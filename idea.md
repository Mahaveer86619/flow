# Flow — Full Architecture & Implementation Prompt
> **Version 2.0 — Standalone + Social + Cross-Device**
> Drop this document as a full context prompt when building or extending the app.

---

## 0. Project Vision

Flow is a standalone Flutter music app that:
- Streams audio directly from YouTube Music via on-device resolution (no backend server)
- Runs a fully local recommendation engine using a weighted scoring graph
- Caches songs intelligently within a user-defined storage budget
- Allows the same user to link multiple devices (e.g. Android + Desktop), where the desktop streams from the mobile and syncs recommendations locally over LAN/BLE
- Allows different users to link their Flow apps, merge recommendation graphs, and build proximity-synced collaborative playlists
- Exports downloaded tracks as properly tagged audio files

No mandatory backend. All intelligence, streaming, and sync is peer-to-peer or on-device.

---

## 1. High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                        UI Layer                         │
│   Screens, Widgets, Themes, Animations (Flutter/M3)     │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│                     State Layer                         │
│                    BLoC (player)                        │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│                    Domain Layer                         │
│  RecommendationEngine · QueueBuilder · NoveltyEngine    │
│  SyncEngine · CollabEngine · TasteProfileBuilder        │
│  (Pure Dart — zero I/O, fully testable)                 │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│                     Data Layer                          │
│  ┌──────────────┐  ┌───────────────┐  ┌─────────────┐  │
│  │SourceAdapters│  │  CacheManager │  │  SyncLayer  │  │
│  │  YTM/Local   │  │  Hive + SQLite│  │ P2P/LAN/BLE │  │
│  └──────────────┘  └───────────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 2. Unified Data Models

### Track Entity (Domain)

```dart
class Track {
  final String id;                 // internal UUID
  final String title;
  final String artist;
  final String artistId;
  final String? album;
  final String? albumId;
  final String? year;
  final List<String> genres;
  final List<String> tags;         // mood, energy, tempo descriptors
  final String? youtubeId;         // videoId for stream resolution
  final String? ytmBrowseId;       // for YTM metadata navigation
  final String? spotifyId;         // metadata only, never for audio
  final String? sourceChannelId;   // YT channel ID
  final String? artworkUrl;
  final String? localArtworkPath;
  final TrackAudioFeatures? audio;
  // Behavioral state
  int playCount;
  int skipCount;
  int replayCount;
  DateTime? lastPlayed;
  bool liked;
  bool downloaded;
  String? downloadedPath;
  bool cachedAudio;
  double graphScore;               // maintained by ScoringGraph
}

class TrackAudioFeatures {
  final double bpm;
  final double energy;        // 0.0–1.0
  final double danceability;  // 0.0–1.0
  final String key;
  final String mode;          // major | minor
}
```

### Track DTO → Entity Mapping

```dart
class TrackModel {
  // Parses InnerTube JSON or Spotify JSON
  factory TrackModel.fromYtmRenderer(Map<String, dynamic> json) { ... }
  factory TrackModel.fromSpotifyJson(Map<String, dynamic> json) { ... }
  Track toEntity() { ... }
}
```

---

## 3. Data Layer

### 3a. YouTube Music Source (Existing — Preserve)

Keep the existing `YoutubeMusicDataSource` exactly as-is. It already handles:
- Multi-probe home feed strategy (`FEmusic_home` + parallel sub-feeds)
- `YtmMapper` for renderer parsing (`musicTwoRowItemRenderer`, etc.)
- `YoutubeInterceptor` for cookie injection and `SAPISIDHASH`
- JIT stream resolution with `flow-jit` placeholder protocol
- `StreamResolver` with client rotation (ANDROID_VR fallback)
- `YoutubeExplode` as secondary stream fallback

**Streaming fix:** The primary issue is likely cookie expiry or InnerTube client version drift. Resolution order going forward:

```dart
class StreamResolver {
  Future<String> resolve(String videoId) async {
    // 1. Try InnerTube ANDROID_VR client (most resilient)
    // 2. Try InnerTube WEB client with fresh SAPISIDHASH
    // 3. Fallback: YoutubeExplode
    // 4. Fallback: yt-dlp via process call (desktop only)
  }
}
```

### 3b. Source Adapter Interface

All sources implement this interface so the domain layer never knows which source is being used:

```dart
abstract class MusicSourceAdapter {
  Future<List<Track>> search(String query);
  Future<StreamUrl> getStreamUrl(Track track, {Quality quality});
  Future<List<Track>> getUserLibrary();
  Future<List<Track>> getCreatorTracks(String creatorId);
  Future<List<Track>> getAlbumTracks(String albumId);
  Future<List<Track>> getSimilar(Track seed);
}
```

| Source | Audio | Metadata | Auth |
|---|---|---|---|
| YouTube Music | InnerTube → YoutubeExplode fallback | Full YTM renderer | Cookie-based |
| Spotify | **None** (metadata only, audio via YT match) | Genres, BPM, energy, danceability | OAuth PKCE |
| Local Files | File path | ID3/Vorbis tags via `metadata_god` | None |

**Cross-source track matching** — link a Spotify track to a YouTube video:

```dart
String trackFingerprint(String artist, String title) =>
  '${_normalize(artist)}::${_normalize(title)}';

// Normalize: lowercase, strip punctuation, collapse whitespace
String _normalize(String s) => s
  .toLowerCase()
  .replaceAll(RegExp(r"[^\w\s]"), '')
  .replaceAll(RegExp(r'\s+'), ' ')
  .trim();
```

Store all source IDs on one `Track`. Audio resolution prefers: local file → cache → YTM InnerTube → YoutubeExplode.

### 3c. Storage Layout

```
/data/user/0/com.flow.app/files/
  /audio/
    /{trackId}.opus         ← managed cache, 64kbps, ~3MB/song
  /artwork/
    /{trackId}.jpg          ← 300×300 max
  /sync/
    /peers/
      /{peerId}.delta       ← incremental graph deltas from linked peers
  /collab/
    /{playlistId}.cplist    ← encrypted collab playlist file

/sdcard/Music/Flow/         ← user downloads (ID3-tagged, user-chosen)
  /{Artist} - {Title}.mp3   ← or .flac or .opus

Hive Boxes:
  settings                  ← app preferences, cache budget, linked peers
  stream_cache              ← short-lived stream URL cache (TTL: 6h)
  
SQLite (drift):
  tracks, listen_events, graph_nodes, graph_edges,
  playlists, playlist_tracks, peers, collab_playlists, sync_log
```

---

## 4. Scoring Graph

The scoring graph is the central intelligence. Every listen event updates node scores, which propagate upward from tracks to artist → genre → tag nodes. Everything reads from and writes to this graph.

### Node Types and Propagation Weights

```dart
enum NodeType { track, artist, album, genre, tag, creator }

// On any listen event, delta propagates as:
// track   × 1.0
// artist  × 0.7
// album   × 0.5
// creator × 0.5
// genres  × 0.4  (each)
// tags    × 0.3  (each)
```

### Event Weights

```dart
enum ListenEvent {
  fullListen,     // +1.0
  replay,         // +2.0
  liked,          // +3.0
  downloaded,     // +2.5
  addedToList,    // +1.5
  skippedMid,     // −0.3
  skippedEarly,   // −0.8
}
```

### Score Update with Time Decay

```dart
void _updateNode(String id, NodeType type, double delta) {
  final node = nodes[id] ??= GraphNode(id, type);
  final ageDays = DateTime.now().difference(node.lastUpdated).inDays;
  // 3% decay per day — recent listens dominate
  node.score = (node.score * pow(0.97, ageDays)) + delta;
  node.lastUpdated = DateTime.now();
}
```

### BFS Recommendation from Seed

```dart
List<GraphNode> recommend(String seedId, {int n = 20}) {
  final visited = <String>{seedId};
  final queue = Queue<String>()..add(seedId);
  final results = <GraphNode>[];

  while (queue.isNotEmpty && results.length < n * 3) {
    final current = queue.removeFirst();
    for (final edge in (adjacency[current] ?? [])) {
      if (!visited.contains(edge.toId)) {
        visited.add(edge.toId);
        final node = nodes[edge.toId];
        if (node != null) { results.add(node); queue.add(edge.toId); }
      }
    }
  }
  results.sort((a, b) => b.score.compareTo(a.score));
  return results.take(n).toList();
}
```

---

## 5. Recommendation Engine

On-device only. Scores track-to-track similarity using genre/tag Jaccard overlap and audio feature proximity, then boosts by the user's graph-derived affinity for the candidate's artist.

```dart
double scoreSimilarity(Track a, Track b, TasteProfile profile) {
  double score = 0;

  if (a.artistId == b.artistId) score += 2.0;
  if (a.albumId != null && a.albumId == b.albumId) score += 1.0;
  score += _jaccard(a.genres, b.genres) * 1.5;
  score += _jaccard(a.tags,   b.tags)   * 1.2;

  if (a.audio != null && b.audio != null) {
    score += (1 - (a.audio!.bpm    - b.audio!.bpm).abs()    / 200) * 0.8;
    score += (1 - (a.audio!.energy - b.audio!.energy).abs())       * 0.6;
  }

  // Boost by user's established affinity for this artist from the graph
  score *= (profile.artistScores[b.artistId] ?? 0.5).clamp(0.1, 5.0);
  return score;
}
```

---

## 6. Novel Song Discovery

When finding unheard songs, rank the *sources* (artists, albums, creators) by affinity first, then fetch from the top-ranked sources across all adapters.

```dart
class NoveltyEngine {
  List<RankedSource> buildSourceRanking(List<Track> fromTracks) {
    final sources = <String, RankedSource>{};
    for (final t in fromTracks) {
      final w = _weight(t); // liked×3 + plays×0.5 + replays×1 - skips×0.3
      _accum(sources, t.artistId,        SourceType.artist,  w * 1.0);
      _accum(sources, t.albumId,         SourceType.album,   w * 0.6);
      _accum(sources, t.sourceChannelId, SourceType.creator, w * 0.5);
    }
    return sources.values.toList()..sort((a,b) => b.score.compareTo(a.score));
  }

  Future<List<Track>> fetchNovel({
    required List<RankedSource> sources,
    required Set<String> exclude,
    int limit = 30,
  }) async {
    final results = <Track>[];
    for (final src in sources.take(10)) {
      final candidates = await _fetchFromSource(src);
      results.addAll(candidates.where((t) => !exclude.contains(t.id)));
    }
    return _deduplicateAndRank(results).take(limit).toList();
  }
}
```

**Discovery context table:**

| Trigger | Seed | Exclude |
|---|---|---|
| Radio from liked songs | Full listen history | All played tracks |
| Radio from playlist | Playlist tracks | Playlist IDs |
| Radio from album | Album + artist | Album track IDs |
| Radio from creator | Creator top tracks | Creator's track IDs |
| Radio from searched song | Graph neighbors of seed | Just the seed |

---

## 7. Queue Builder

```dart
enum QueueMode { listenAgain, radio, discovery }

// familiar/novel ratio per mode:
// listenAgain → 85% / 15%  (resuming library feels safe)
// radio       → 55% / 45%  (balanced exploration)
// discovery   → 20% / 80%  (new music session)

// Novel tracks are interleaved, not clumped:
// familiar: [F F F F F F F F F N F F F F F F F F N ...]
```

---

## 8. Cache System

### Settings

```dart
// Cache tiers — slider snaps to these values
const List<int?> cacheTiers = [0, 250, 500, 1024, 2048, 5120, null];
// Default: 500MB ≈ 160 songs at 64kbps Opus

// 0    → metadata + graph only (recommendations still fully work)
// null → unlimited

String cacheHint(int? mb) => switch (mb) {
  0    => "⚠️ No audio stored. Recommendations still work. Fully network dependent.",
  250  => "~80 songs. Light offline support.",
  500  => "~160 songs. Good baseline for offline queues.",
  1024 => "~320 songs. Solid offline radio.",
  2048 => "~650 songs. Weekly digest works offline.",
  5120 => "~1600 songs. Near-full library offline.",
  null => "✓ Best experience. All scored songs auto-cached.",
  _    => "",
};
```

### Eviction Score

```dart
double cacheScore(Track t) =>
  (t.playCount    *  1.0)
+ (t.liked        ?  5.0 : 0.0)
+ (t.replayCount  *  2.0)
+ (t.downloaded   ?  0.0 : 3.0)  // never evict downloads
+ (t.skipCount    * -0.8)
+ _recencyBoost(t.lastPlayed)     // log decay, max +2.0 at today
+ (graph.nodes[t.id]?.score ?? 0) * 0.5;
// Evict lowest-scored .opus files first. Metadata is NEVER evicted.
```

---

## 9. Download System

Downloads are completely separate from cache. They produce a portable, tagged audio file in a user-chosen folder. The app never auto-deletes them.

| Property | Cache | Download |
|---|---|---|
| Location | Internal `/audio/` | User-chosen folder |
| Format | `.opus` 64kbps | MP3 / FLAC / Opus (user picks) |
| Metadata | SQLite only | Embedded ID3/Vorbis tags in file |
| Exportable | No | Yes |
| Auto-evict | Yes (by score) | Never |

```dart
// FFmpeg command template
'-i "$streamUrl" '
'-metadata title="..." -metadata artist="..." -metadata album="..." '
'-metadata genre="..." -metadata date="..." '
'-i "$artworkPath" -map 0 -map 1 -disposition:v attached_pic '
'-codec:a $ffmpegCodec -b:a ${bitrate}k "$outputPath"'
```

---

## 10. Feature: Same-User Cross-Device Streaming & Sync

### Concept

A user has Flow installed on multiple devices (e.g. Android phone + Windows desktop). They link them as a **device pair**. The desktop becomes a lightweight client that:
1. Streams audio from the mobile device over LAN (the mobile acts as a local media node)
2. Syncs graph scores, listen history, and cache metadata over LAN or BLE
3. Falls back to independent streaming when out of range of the mobile

This is **not** a traditional server. The mobile acts as a peer, not a host. Both devices are equal — either can act as the streaming source.

### Pairing Flow

```
User opens Flow on Android → Settings → My Devices → "Link a Device"
  → Generates a pairing QR code containing:
     { deviceId, displayName, localIp, bleAddress, publicKey }

User opens Flow on Desktop → Settings → My Devices → "Scan / Enter Code"
  → Scans QR or enters 6-digit code
  → Devices exchange public keys (X25519 ECDH)
  → Shared symmetric key derived for encrypted channel
  → Both devices save peer record to `peers` table
  → Pairing confirmed ✓
```

### Device Peer Model

```dart
class DevicePeer {
  final String peerId;             // UUID, stable across sessions
  final String displayName;        // "My Android"
  final PeerRelation relation;     // sameUser | otherUser
  final String publicKey;          // X25519 for E2E encryption
  DateTime lastSeen;
  String? lastKnownIp;
  String? bleAddress;
  SyncPermissions permissions;     // what this peer is allowed to sync
}

class SyncPermissions {
  final bool streamAudio;          // can this device request audio from us?
  final bool syncListenHistory;
  final bool syncGraphScores;
  final bool syncCollabPlaylists;
}
```

### LAN Audio Streaming (Mobile → Desktop)

When the desktop wants to play a track:
1. Desktop checks if the track is locally cached → serve directly
2. Desktop checks if paired mobile is reachable on LAN
3. If yes → desktop sends a `StreamRequest` to mobile over the encrypted LAN channel
4. Mobile resolves the stream URL (using its YTM session/cookies), then either:
   - **Proxies** the stream bytes to desktop in real-time (mobile fetches from YT, desktop plays)
   - **Or sends the resolved URL** directly if the desktop can reach it without cookies
5. Desktop plays via `just_audio` as if it were a normal stream URL

```dart
class LanStreamBridge {
  // Mobile side — listens for stream requests from paired desktop
  Future<void> startStreamServer() async {
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 7788);
    await for (final request in server) {
      if (request.uri.path.startsWith('/stream/')) {
        final videoId = request.uri.pathSegments.last;
        final streamUrl = await streamResolver.resolve(videoId);
        // Proxy the bytes from YT → desktop
        final ytResponse = await dio.get(streamUrl, options: Options(responseType: ResponseType.stream));
        await ytResponse.data.stream.pipe(request.response);
      }
    }
  }

  // Desktop side — requests a stream from paired mobile
  Future<String> requestStreamFromMobile(String videoId, DevicePeer mobile) async {
    // Returns a local proxy URL the desktop's just_audio can use
    return 'http://${mobile.lastKnownIp}:7788/stream/$videoId';
  }
}
```

### Sync Protocol (Graph + History)

Sync happens over LAN when devices are on the same network, and queues deltas for BLE/next-connection when they are not.

```dart
class GraphDelta {
  final String peerId;
  final DateTime from;
  final DateTime to;
  final List<NodeDelta> nodeUpdates;  // [{ id, scoreDelta, lastUpdated }]
  final List<EdgeDelta> edgeUpdates;  // [{ fromId, toId, weightDelta }]
  final List<ListenEventRecord> events;
}

class SyncEngine {
  // Produce a delta since last sync with this peer
  GraphDelta buildDelta(String peerId) {
    final lastSync = db.getLastSyncTime(peerId);
    return GraphDelta(
      peerId: localDeviceId,
      from: lastSync,
      to: DateTime.now(),
      nodeUpdates: graph.getUpdatedNodesSince(lastSync),
      edgeUpdates: graph.getUpdatedEdgesSince(lastSync),
      events: db.getListenEventsSince(lastSync),
    );
  }

  // Apply a received delta — merge, don't overwrite
  void applyDelta(GraphDelta delta) {
    for (final n in delta.nodeUpdates) {
      // Take the max of local and remote score (conservative merge)
      graph.mergeNodeScore(n.id, n.scoreDelta);
    }
    for (final e in delta.events) {
      // Only apply events that don't already exist locally
      if (!db.hasListenEvent(e.id)) db.insertListenEvent(e);
    }
    db.setLastSyncTime(delta.peerId, delta.to);
  }
}
```

### Desktop Lightweight Mode

The desktop client can optionally enter **Lightweight Mode** from settings. In this mode:
- The desktop has no local YTM session (no cookies required)
- All stream resolution is delegated to the paired mobile
- Local graph and cache still work normally
- UI is identical — the user doesn't see any difference

```dart
enum StreamingMode {
  standalone,         // resolve streams locally (default)
  relayFromPeer,      // route through paired mobile
  hybridPreferLocal,  // try local first, fall back to peer
}
```

---

## 11. Feature: Cross-User Social Sync & Collaborative Playlists

### Concept

Two different users can link their Flow apps. This creates a **friend pair**. They can:
1. Opt-in to sharing recommendation graph data, producing a **blended third graph** called a **Taste Blend**
2. Create **Collab Playlists** that are shared between them and sync automatically when the two devices are physically nearby (proximity sync)

This requires no server. All data exchange is direct device-to-device (BLE + LAN) and only happens with explicit user consent.

### Friend Pairing Flow

```
User A: Settings → Friends → "Add Friend"
  → Generates a friend invite QR containing:
     { userId, displayName, publicKey, shareLevel }

User B: Scans QR or enters code
  → Both users confirm the connection on their own devices
  → Keys exchanged, friend record saved
  → Share level negotiated (see below)
  → Connection confirmed on both sides ✓
```

### Share Level (User Controls)

```dart
enum ShareLevel {
  none,           // linked but not sharing anything
  listenStats,    // only share top artists/genres (no track-level data)
  tasteBlend,     // share graph node scores for blend computation
  full,           // tasteBlend + listen history timestamps
}
```

The user can change the share level at any time. Revoking always purges the friend's data from your local DB.

### Taste Blend (Third Recommendation Graph)

When two users have share level `tasteBlend` or higher, a blended graph is computed locally:

```dart
class TasteBlendEngine {
  // Produces a synthetic TasteProfile from two users' graphs
  TasteProfile computeBlend(
    ScoringGraph myGraph,
    Map<String, double> friendNodeScores, // received delta, not full graph
    double myWeight,      // 0.0–1.0, default 0.5 (equal blend)
    double friendWeight,  // 1.0 - myWeight
  ) {
    final blendedArtists = <String, double>{};
    final blendedGenres  = <String, double>{};

    // Merge artist nodes
    final allArtistIds = {
      ...myGraph.artistNodeIds,
      ...friendNodeScores.keys.where((k) => k.startsWith('artist:'))
    };

    for (final id in allArtistIds) {
      final myScore     = myGraph.nodes[id]?.score ?? 0;
      final friendScore = friendNodeScores[id] ?? 0;
      blendedArtists[id] = (myScore * myWeight) + (friendScore * friendWeight);
    }

    // Same for genres and tags...
    return TasteProfile(artistScores: blendedArtists, genreScores: blendedGenres, ...);
  }
}
```

**In the app, the user sees three tabs in Discover:**
- **For You** — your own graph
- **[Friend Name]'s Mix** — their recommendations (if they've shared)
- **Blend** — the computed blend (only if both have tasteBlend enabled)

The user can toggle Blend listening from **Settings → Friends → [name] → Use Blend for Radio**.

### Collaborative Playlists

A Collab Playlist is a shared playlist owned by two or more linked users. It syncs over proximity (BLE or LAN when same network) — no internet or server required.

```dart
class CollabPlaylist {
  final String id;
  final String name;
  final List<String> ownerIds;       // all collaborators
  final List<CollabTrack> tracks;
  final List<CollabEdit> editLog;    // append-only operation log (CRDT-like)
  DateTime lastSyncedAt;
  String contentHash;                // SHA256 of current track list for diff detection
}

class CollabTrack {
  final String trackId;
  final String addedByUserId;
  final DateTime addedAt;
  int position;
}

class CollabEdit {
  final String editId;          // UUID
  final String userId;
  final CollabEditType type;    // addTrack | removeTrack | reorder | rename
  final Map<String, dynamic> payload;
  final DateTime timestamp;
}
```

### Proximity Sync Protocol

```
User A and User B come within BLE range (or join same WiFi)
  │
  ├─→ BLE advertisement: Flow peer beacon { userId, deviceId }
  │        OR
  ├─→ LAN mDNS discovery: "_flow._tcp" service
  │
  ├─→ Devices recognize each other as friends (match userId against friends table)
  │
  ├─→ Encrypted handshake using pre-exchanged keys
  │
  ├─→ Exchange contentHash for each shared collab playlist
  │
  ├─→ For each playlist where hashes differ:
  │     A sends its editLog entries since lastSyncedAt
  │     B sends its editLog entries since lastSyncedAt
  │
  ├─→ Each device applies the other's edits using CRDT merge rules:
  │     - addTrack + addTrack (same track) → deduplicate, keep one
  │     - removeTrack wins over addTrack if timestamp is later
  │     - reorder conflicts → last-write-wins by timestamp
  │
  └─→ Both devices update contentHash and lastSyncedAt ✓
```

### Privacy Rules (Non-Negotiable)

- Friend's raw track listen history is **never transmitted** unless share level is `full` and user has explicitly enabled it
- Graph score deltas are anonymized: only node IDs and score values, no timestamps or listen sequences
- All data is encrypted in transit with the shared session key (X25519 + AES-GCM)
- All friend data is stored encrypted at rest in the `peers` SQLite table
- Removing a friend immediately purges all their data from your device and stops future sync
- Collab playlist data is signed by each user's key so edits cannot be spoofed

---

## 12. Full Feature List

### Playback
- Gapless playback via `just_audio`
- JIT stream resolution with `flow-jit` placeholder protocol
- Crossfade (0–12 seconds, configurable)
- Sleep timer (15 / 30 / 60 min or end of track)
- Playback speed and pitch control
- Equalizer with presets
- Lock screen / notification controls via `audio_service`
- Desktop SMTC (System Media Transport Controls) + media keys

### Library & Sources
- YouTube Music home feed (multi-probe strategy preserved)
- Spotify metadata import + playlist sync (OAuth PKCE, no audio)
- Local file library with ID3/Vorbis tag reading
- Cross-source track matching via normalized fingerprint
- Liked songs, history, and playlists from YTM

### Recommendations
- Scoring graph: all listen events propagate upward to artist/genre/tag nodes
- TasteProfile built from weighted listen history
- Radio from any track, artist, album, playlist, creator, or searched song
- Three queue modes: Listen Again (85/15), Radio (55/45), Discovery (20/80)
- Novel song discovery via ranked-source fetching
- Weekly auto-generated digest playlist (Sunday night, from graph + new discoveries)
- Mood filter: select energy level → filtered queue
- Taste match % shown on each track card

### Cache & Offline
- Storage budget slider: 0 → Unlimited (default 500MB)
- Metadata and graph scores are **never evicted**
- Smart eviction: lowest graph-scored `.opus` files removed first
- Auto pre-cache top-scored tracks on WiFi (via WorkManager)
- Offline mode indicator; uncached tracks shown greyed out

### Downloads
- Format: MP3, FLAC, Opus (user's choice)
- Bitrate selection per format
- Custom save folder via file picker
- Embedded ID3/Vorbis tags including album artwork
- Download queue with progress UI
- Downloads never auto-deleted, excluded from cache eviction

### Cross-Device (Same User)
- Device pairing via QR code or 6-digit code
- E2E encrypted LAN channel (X25519 + AES-GCM)
- Desktop Lightweight Mode: stream audio proxied from mobile
- Background graph + history sync over LAN or queued for BLE
- Selective sync permissions per paired device
- Fallback to standalone if peer unreachable

### Social (Different Users)
- Friend pairing via QR or invite code
- Share level control: None / Listen Stats / Taste Blend / Full
- Taste Blend: computed locally from both users' graph scores
- Blend radio available as third discovery tab (opt-in)
- Collab Playlists: shared playlists synced over proximity (BLE/LAN)
- CRDT-based edit merge — no conflicts, no server
- Full privacy: friend data encrypted at rest and in transit
- Instant revoke: removing friend purges all their data locally

### UI / UX
- Material 3 with dynamic color extraction from album art
- Squiggly progress bar (existing, preserve)
- Full-screen player with blurred artwork background
- Mini player persistent bottom bar
- Queue editor: drag to reorder, swipe to remove
- Waveform scrubber via `audio_waveforms`
- Dark / Light / AMOLED themes
- Desktop mini-player (always-on-top compact player)
- Stats dashboard: top artists, genres, total hours, listening heatmap

---

## 13. Database Schema (drift)

```sql
-- Core tracks
CREATE TABLE tracks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  artist TEXT NOT NULL,
  artist_id TEXT NOT NULL,
  album TEXT,
  album_id TEXT,
  year TEXT,
  genres TEXT,             -- JSON array
  tags TEXT,               -- JSON array
  youtube_id TEXT,
  ytm_browse_id TEXT,
  spotify_id TEXT,
  source_channel_id TEXT,
  artwork_url TEXT,
  local_artwork_path TEXT,
  bpm REAL, energy REAL, danceability REAL, key TEXT, mode TEXT,
  play_count INTEGER DEFAULT 0,
  skip_count INTEGER DEFAULT 0,
  replay_count INTEGER DEFAULT 0,
  last_played INTEGER,
  liked INTEGER DEFAULT 0,
  downloaded INTEGER DEFAULT 0,
  downloaded_path TEXT,
  cached_audio INTEGER DEFAULT 0,
  graph_score REAL DEFAULT 0.0
);

-- Listen history
CREATE TABLE listen_events (
  id TEXT PRIMARY KEY,     -- UUID, used for dedup during sync
  track_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  timestamp INTEGER NOT NULL,
  listen_duration_seconds INTEGER,
  source_user_id TEXT      -- NULL = local, else = synced from friend
);

-- Scoring graph
CREATE TABLE graph_nodes (
  id TEXT PRIMARY KEY,
  node_type TEXT NOT NULL,
  score REAL DEFAULT 0.0,
  last_updated INTEGER
);

CREATE TABLE graph_edges (
  from_id TEXT NOT NULL,
  to_id TEXT NOT NULL,
  weight REAL DEFAULT 0.1,
  PRIMARY KEY (from_id, to_id)
);

-- Playlists (local + YTM + collab)
CREATE TABLE playlists (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  created_at INTEGER,
  type TEXT,               -- local | yt | spotify | collab | auto
  source_id TEXT,          -- remote ID for yt/spotify playlists
  owner_ids TEXT           -- JSON array, for collab playlists
);

CREATE TABLE playlist_tracks (
  playlist_id TEXT NOT NULL,
  track_id TEXT NOT NULL,
  position INTEGER NOT NULL,
  added_by TEXT,           -- userId for collab playlists
  added_at INTEGER,
  PRIMARY KEY (playlist_id, track_id)
);

-- Peers (both device peers and friend peers)
CREATE TABLE peers (
  peer_id TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  relation TEXT NOT NULL,  -- sameUser | otherUser
  public_key TEXT NOT NULL,
  share_level TEXT,        -- none | listenStats | tasteBlend | full (friends only)
  last_seen INTEGER,
  last_known_ip TEXT,
  ble_address TEXT,
  permissions TEXT,        -- JSON: SyncPermissions object
  graph_data_blob TEXT,    -- encrypted friend graph delta, stored locally
  last_sync_time INTEGER
);

-- Collab playlist edit log (CRDT append-only)
CREATE TABLE collab_edits (
  edit_id TEXT PRIMARY KEY,
  playlist_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  edit_type TEXT NOT NULL, -- addTrack | removeTrack | reorder | rename
  payload TEXT NOT NULL,   -- JSON
  timestamp INTEGER NOT NULL,
  applied INTEGER DEFAULT 0
);

-- Sync log
CREATE TABLE sync_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  peer_id TEXT NOT NULL,
  sync_type TEXT NOT NULL, -- graph | history | collabPlaylist
  synced_at INTEGER NOT NULL,
  items_sent INTEGER,
  items_received INTEGER
);
```

---

## 14. Packages

| Purpose | Package |
|---|---|
| Audio playback | `just_audio` |
| Background audio + controls | `audio_service` |
| YouTube stream extraction (fallback) | `youtube_explode_dart` |
| FFmpeg transcoding + tag embedding | `ffmpeg_kit_flutter` |
| Type-safe SQLite ORM | `drift` |
| Fast key-value store | `hive_flutter` |
| HTTP client + caching | `dio` + `dio_cache_interceptor` |
| State management | `riverpod` |
| BLoC (player state) | `flutter_bloc` |
| File picker (download folder) | `file_picker` |
| ID3 tag reading (local files) | `metadata_god` |
| Waveform visualization | `audio_waveforms` |
| Spotify OAuth + API | `spotify` |
| Secure token + key storage | `flutter_secure_storage` |
| Background tasks (cache, pre-cache) | `workmanager` |
| BLE peer discovery | `flutter_blue_plus` |
| LAN mDNS discovery | `multicast_dns` |
| Encryption (X25519 + AES-GCM) | `pointycastle` or `cryptography` |
| QR code generation + scanning | `qr_flutter` + `mobile_scanner` |
| Permission handling | `permission_handler` |
| Desktop SMTC (Windows) | `smtc_windows` |

---

## 15. Implementation Phases

```
Phase 1 — Fix Streaming
- [ ] Audit InnerTube client version and cookie expiry in StreamResolver
- [ ] Add YoutubeExplode as hardened fallback
- [ ] Add yt-dlp process fallback for desktop builds
- [ ] Verify JIT flow-jit placeholder protocol still handles rapid skipping

Phase 2 — Recommendation Engine
- [ ] Implement ScoringGraph with event propagation + time decay
- [ ] TasteProfile builder from listen history
- [ ] RecommendationEngine similarity scoring
- [ ] NoveltyEngine with ranked source discovery
- [ ] QueueBuilder with three modes and interleaved novel tracks

Phase 3 — Cache Overhaul
- [ ] Cache budget slider UI (tiered, with hints)
- [ ] CacheManager with score-based eviction
- [ ] Pre-cache worker via WorkManager (WiFi only)
- [ ] Offline-first load flow

Phase 4 — Download System
- [ ] DownloadManager with FFmpeg transcoding + ID3 embedding
- [ ] Format/bitrate/folder picker UI
- [ ] Download queue with progress
- [ ] Separate from cache, never auto-evicted

Phase 5 — Cross-Device Sync
- [ ] Device pairing via QR code (X25519 key exchange)
- [ ] LAN audio proxy (LanStreamBridge: mobile server, desktop client)
- [ ] Graph delta serialization and sync over LAN
- [ ] BLE delta queuing for out-of-range sync
- [ ] Lightweight Mode toggle on desktop

Phase 6 — Social Features
- [ ] Friend pairing via invite QR
- [ ] Share level UI (per-friend settings)
- [ ] TasteBlendEngine: local blend computation from friend graph delta
- [ ] Blend discover tab in UI
- [ ] CollabPlaylist model + CRDT edit log
- [ ] Proximity sync: BLE/LAN detection + edit exchange + merge
- [ ] Friend data encryption at rest (AES-GCM, key from X25519)

Phase 7 — Polish & Desktop
- [ ] Desktop mini-player (always-on-top)
- [ ] SMTC integration (Windows)
- [ ] Stats dashboard + listening heatmap
- [ ] Weekly digest playlist auto-generation
- [ ] Mood filter
- [ ] AMOLED theme
```

---

## 16. Key Design Decisions

1. **Streaming fix is in the resolver, not the architecture.** The JIT flow-jit protocol, YtmMapper, and YoutubeInterceptor are sound — only the InnerTube client version and cookie handling needs updating.

2. **Metadata is never evicted.** Even at 0MB audio cache, the scoring graph and SQLite remain intact. Recommendations work fully offline.

3. **Spotify is metadata-only.** Audio always comes from YouTube to keep the app free. Spotify OAuth gives genres, BPM, energy, and danceability — high-value signals for the scoring graph.

4. **Same-user device linking is peer-to-peer, not cloud.** The mobile acts as an audio proxy and graph sync source. The desktop is a lightweight client. No server. Works entirely on LAN or BLE.

5. **Cross-user social features are proximity-first.** Collab playlists sync only when users are physically nearby — this is a feature, not a limitation. It creates natural, trust-based sharing that doesn't require a server or account system.

6. **Taste Blend is computed locally.** Friend graph scores are shared as anonymized deltas (node ID + score only). The blend computation runs on your device. Your friend never sees your raw listen history unless share level is `full` and you explicitly chose it.

7. **CRDT edit logs for collab playlists.** No server means no authoritative state. The append-only edit log with timestamp-based conflict resolution ensures both devices converge to the same playlist after every sync, regardless of order.

8. **Novel discovery ranks sources, not tracks.** Fetching from a top-ranked artist surfaces their less-known songs — which are more likely to match taste than a random similar track found by audio features alone.

9. **Queue mode controls familiar/novel ratio.** Resuming your library (Listen Again) feels safe at 85% familiar. Starting a radio from a searched song (Radio) is balanced. A dedicated discovery session runs 80% novel.

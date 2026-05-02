import 'dart:convert';
import 'package:drift/drift.dart';
import '../../domain/entities/scoring_graph.dart' as domain;
import '../../domain/entities/track.dart' as domain;
import '../../domain/entities/collab_playlist.dart' as domain;
import '../../domain/entities/graph_delta.dart';
import '../../domain/engines/sync_engine.dart';
import '../../domain/engines/collab_engine.dart';
import '../../domain/repositories/music_repository.dart';
import '../../data/sources/local/local_database.dart' as db;
import '../logger/app_logger.dart';
import '../storage/local_storage.dart';

class AppIntelligence {
  AppIntelligence._();
  static final AppIntelligence instance = AppIntelligence._();

  final db.LocalDatabase _database = db.LocalDatabase();
  final domain.ScoringGraph _graph = domain.ScoringGraph();
  late final SyncEngine _syncEngine;

  Future<void> init() async {
    _syncEngine = SyncEngine(graph: _graph);
    
    // Load graph from DB
    final nodes = await _database.select(_database.graphNodes).get();
    for (final n in nodes) {
      _graph.nodes[n.id] = domain.GraphNode(
        id: n.id,
        type: domain.NodeType.values.firstWhere((e) => e.name == n.nodeType),
        score: n.score,
        lastUpdated: n.lastUpdated != null 
          ? DateTime.fromMillisecondsSinceEpoch(n.lastUpdated!) 
          : DateTime.now(),
      );
    }

    final edges = await _database.select(_database.graphEdges).get();
    for (final e in edges) {
      final adjacency = _graph.adjacency[e.fromId] ??= [];
      adjacency.add(domain.GraphEdge(fromId: e.fromId, toId: e.toId, weight: e.weight));
    }

    // Check for weekly digest (Sunday only)
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    final lastGen = LocalStorage.instance.lastDigestGeneration;

    if (now.weekday == DateTime.sunday && lastGen != todayStr) {
      // Repository injection will happen via a trigger in HomeCubit
    }
  }

  Future<void> triggerWeeklyDigest(MusicRepository repository) async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    final lastGen = LocalStorage.instance.lastDigestGeneration;

    if (now.weekday == DateTime.sunday && lastGen != todayStr) {
      await generateWeeklyDigest(repository);
      LocalStorage.instance.saveLastDigestGeneration(todayStr);
    }
  }

  Future<void> recordEvent(domain.Track track, domain.ListenEvent event) async {
    final trackNodeId = 'track:${track.fingerprint}';

    _graph.recordEvent(
      trackNodeId,
      event,
      artistId: track.artistId,
      albumId: track.albumId,
      creatorId: track.sourceChannelId,
      genres: track.genres,
      tags: track.tags,
    );

    await _persistGraph();
    
    await (_database.update(_database.tracks)..where((t) => t.id.equals(track.id))).write(
      db.TracksCompanion(
        playCount: Value(event == domain.ListenEvent.fullListen ? (track.playCount + 1) : track.playCount),
        skipCount: Value(event == domain.ListenEvent.skippedEarly || event == domain.ListenEvent.skippedMid ? (track.skipCount + 1) : track.skipCount),
        replayCount: Value(event == domain.ListenEvent.replay ? (track.replayCount + 1) : track.replayCount),
        lastPlayed: Value(DateTime.now().millisecondsSinceEpoch),
        liked: Value(event == domain.ListenEvent.liked ? true : track.liked),
        graphScore: Value(_graph.nodes[trackNodeId]?.score ?? 0.0),
      ),
    );
  }

  Future<void> _persistGraph() async {
    await _database.batch((batch) {
      for (final node in _graph.nodes.values) {
        batch.insert(
          _database.graphNodes,
          db.GraphNodesCompanion.insert(
            id: node.id,
            nodeType: node.type.name,
            score: Value(node.score),
            lastUpdated: Value(node.lastUpdated.millisecondsSinceEpoch),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
      
      for (final edges in _graph.adjacency.values) {
        for (final edge in edges) {
          batch.insert(
            _database.graphEdges,
            db.GraphEdgesCompanion.insert(
              fromId: edge.fromId,
              toId: edge.toId,
              weight: Value(edge.weight),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      }
    });
  }

  domain.ScoringGraph get graph => _graph;

  // ── Sync Methods ──────────────────────────────────────────────────────────

  Future<GraphDelta> getDeltaForPeer(String peerId) async {
    final lastSyncTime = LocalStorage.instance.getPeerLastSync(peerId);
    final lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncTime);
    return _syncEngine.buildDelta('local-device-id', lastSync);
  }

  Future<void> applyDelta(GraphDelta delta) async {
    _syncEngine.applyDelta(delta);
    await _persistGraph();
  }

  Future<void> applyDeltaFromJson(Map<String, dynamic> json) async {
    final delta = GraphDelta.fromJson(json);
    await applyDelta(delta);
    LocalStorage.instance.setPeerLastSync(delta.peerId, delta.to.millisecondsSinceEpoch);
    
    // Save friend's graph data blob
    await (_database.update(_database.peers)..where((t) => t.peerId.equals(delta.peerId))).write(
      db.PeersCompanion(
        graphDataBlob: Value(jsonEncode(json)),
      ),
    );
    
    AppLogger.i('AppIntelligence', 'Applied graph delta from peer ${delta.peerId} (up to ${delta.to})');
  }

  Future<Map<String, double>> getFriendScores(String friendId) async {
    try {
      final peer = await (_database.select(_database.peers)..where((t) => t.peerId.equals(friendId))).getSingleOrNull();
      if (peer?.graphDataBlob != null) {
        final data = jsonDecode(peer!.graphDataBlob!) as Map<String, dynamic>;
        final delta = GraphDelta.fromJson(data);
        final scores = <String, double>{};
        for (final n in delta.nodeUpdates) {
          scores[n.id] = n.scoreDelta;
        }
        return scores;
      }
    } catch (_) {}
    return {};
  }

  // ── Stats Methods ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTopArtists({int limit = 10}) async {
    final query = _database.select(_database.graphNodes)
      ..where((t) => t.nodeType.equals(domain.NodeType.artist.name))
      ..orderBy([(t) => OrderingTerm(expression: t.score, mode: OrderingMode.desc)])
      ..limit(limit);
    
    final nodes = await query.get();
    return nodes.map((n) => {
      'id': n.id.replaceFirst('artist:', ''),
      'score': n.score,
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getTopGenres({int limit = 10}) async {
    final query = _database.select(_database.graphNodes)
      ..where((t) => t.nodeType.equals(domain.NodeType.genre.name))
      ..orderBy([(t) => OrderingTerm(expression: t.score, mode: OrderingMode.desc)])
      ..limit(limit);
    
    final nodes = await query.get();
    return nodes.map((n) => {
      'id': n.id.replaceFirst('genre:', ''),
      'score': n.score,
    }).toList();
  }

  Future<Map<DateTime, int>> getListeningHeatmap({int days = 30}) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    
    final query = _database.select(_database.listenEvents)
      ..where((t) => t.timestamp.isBiggerThanValue(start.millisecondsSinceEpoch));
    
    final events = await query.get();
    final heatmap = <DateTime, int>{};
    
    for (final e in events) {
      final date = DateTime.fromMillisecondsSinceEpoch(e.timestamp);
      final day = DateTime(date.year, date.month, date.day);
      heatmap[day] = (heatmap[day] ?? 0) + 1;
    }
    
    return heatmap;
  }

  // ── Playlist & Collaboration Methods ──────────────────────────────────────

  Future<void> saveLocalPlaylist(String name, List<String> trackIds) async {
    final id = 'local:${DateTime.now().millisecondsSinceEpoch}';
    await _database.batch((batch) {
      batch.insert(_database.playlists, db.PlaylistsCompanion.insert(
        id: id,
        name: name,
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
        type: const Value('local'),
      ));

      for (int i = 0; i < trackIds.length; i++) {
        batch.insert(_database.playlistTracks, db.PlaylistTracksCompanion.insert(
          playlistId: id,
          trackId: trackIds[i],
          position: i,
        ));
      }
    });
  }

  Future<void> mergeCollabPlaylist(domain.CollabPlaylist remotePlaylist) async {
    final localEntity = await (_database.select(_database.playlists)..where((t) => t.id.equals(remotePlaylist.id))).getSingleOrNull();
    
    if (localEntity == null) {
      await saveCollabPlaylist(remotePlaylist);
      return;
    }

    final localEdits = await (_database.select(_database.collabEdits)..where((t) => t.playlistId.equals(remotePlaylist.id))).get();
    
    final engine = CollabEngine();
    final merged = engine.merge(
      remotePlaylist,
      localEdits.map((e) => domain.CollabEdit(
        editId: e.editId,
        userId: e.userId,
        type: domain.CollabEditType.values.firstWhere((v) => v.name == e.editType),
        payload: jsonDecode(e.payload) as Map<String, dynamic>,
        timestamp: DateTime.fromMillisecondsSinceEpoch(e.timestamp),
      )).toList(),
    );

    await saveCollabPlaylist(merged);
  }

  Future<void> saveCollabPlaylist(domain.CollabPlaylist playlist) async {
    await _database.batch((batch) {
      batch.insert(_database.playlists, db.PlaylistsCompanion.insert(
        id: playlist.id,
        name: playlist.name,
        createdAt: Value(playlist.lastSyncedAt.millisecondsSinceEpoch),
        type: const Value('collab'),
        ownerIds: Value(jsonEncode(playlist.ownerIds)),
      ), mode: InsertMode.insertOrReplace);

      for (final t in playlist.tracks) {
        batch.insert(_database.playlistTracks, db.PlaylistTracksCompanion.insert(
          playlistId: playlist.id,
          trackId: t.trackId,
          position: t.position,
          addedBy: Value(t.addedByUserId),
          addedAt: Value(t.addedAt.millisecondsSinceEpoch),
        ), mode: InsertMode.insertOrReplace);
      }
    });
  }

  // ── Weekly Digest ─────────────────────────────────────────────────────────

  Future<void> generateWeeklyDigest(MusicRepository repository) async {
    AppLogger.i('AppIntelligence', 'Generating Weekly Digest...');
    
    final topArtists = await getTopArtists(limit: 5);
    if (topArtists.isEmpty) {
      AppLogger.w('AppIntelligence', 'Not enough data for Weekly Digest');
      return;
    }

    final digestTracks = <String>{};
    
    for (final artist in topArtists) {
      try {
        final results = await repository.searchSongs(artist['id'], limit: 10);
        for (final song in results) {
          digestTracks.add(song.id);
          if (digestTracks.length >= 30) break;
        }
      } catch (_) {}
      if (digestTracks.length >= 30) break;
    }

    if (digestTracks.isNotEmpty) {
      final dateStr = '${DateTime.now().day}/${DateTime.now().month}';
      await saveLocalPlaylist('Weekly Digest $dateStr', digestTracks.toList());
      AppLogger.i('AppIntelligence', 'Weekly Digest generated with ${digestTracks.length} tracks');
    }
  }
}

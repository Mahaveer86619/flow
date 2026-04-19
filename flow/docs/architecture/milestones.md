# Milestone: Standalone Integration & Direct Source Extraction

This document serves as a technical reference for the standalone architecture of **Flow**, detailing how the app interacts directly with YouTube Music (YTM) without a proxy backend.

---

## 1. Direct Source Extraction (StreamResolver)
The `StreamResolver` converts a `videoId` into a playable `.googlevideo.com` audio URL on-device.

### Core Mechanism
- **Endpoint:** InnerTube `youtubei/v1/player` via POST.
- **Rotation Strategy:** To bypass "404 Not Found" and "403 Forbidden" errors, the resolver implements a **Multi-Client & Multi-Endpoint Rotation**.
- **Successful Impersonations:** 
  - **`ANDROID_VR` (v1.50.46)**: Currently the most stable for direct URLs.
  - **`IOS` (v19.29.1)**: Mobile-friendly streams fallback.

### Safety Protocol
- **Isolated Dio:** The resolver uses a **Clean Dio Instance** without global interceptors to avoid bot detection triggered by global cookies/headers.
- **Player Headers:** The `PlayerBloc` injects specific mobile headers (`User-Agent: com.google.android.youtube/...`) into `just_audio` to match the impersonated client.

---

## 2. Data Source Architecture (YoutubeMusicDataSource)
Direct communication with YTM's InnerTube API for all metadata.

### Authenticated Metadata
- **Authenticated Dio:** Unlike the `StreamResolver`, the `YoutubeMusicDataSource` uses the **Global Authenticated Dio**. This ensures user cookies are sent, enabling personalized shelves like *"Listen Again"* and *"Quick Picks"*.
- **Merging Strategy:** The app fetches the main home feed (`FEmusic_home`) and merges it with specific sub-feeds (`FEmusic_listen_again`, `FEmusic_quick_picks`) to ensure requested shelves are always present.

### Requested Layout Mapping
- **"Listen Again"**: Mapped from various recent history shelves.
- **"Fresh Picks"**: Specifically maps **"Your daily discover"** for personalized exploration.
- **"Albums For You"**: Consolidates album shelves and "Artist Spotlight" sections.

---

## 3. Data Flow & Structure

### Intelligent Playback (Start Radio)
- **Home/Search**: Tapping a song automatically triggers **`PlayRadioEvent`**, initializing an infinite discovery queue.
- **Albums/Playlists**: Tapping a song triggers **`PlayQueueEvent`**, playing the specific list in order.

### Data Structure (`Song` Entity)
```dart
class Song {
  final String id;              // YouTube videoId
  final Map<String, dynamic>? extras; // JIT metadata (bio, description, artistId)
}
```

---

## 4. Performance Optimization (Eliminating Lag)
- **Lazy Stream Resolution:** URLs are only resolved for the track currently starting.
- **JIT Prefetching:** The `PlayerBloc` resolves the *next* track in the background.
- **Parallel Metadata:** `SongDetailsCubit` fetches Artist Bio and Song Description in parallel with playback.

---

## 5. Robust Parsing Logic (InnerTube Adaptability)

### Search Result Parsing
Search results in YTM often use `musicResponsiveListItemRenderer` with a `flexColumns` structure instead of top-level `title` and `subtitle` keys.
- **Title Extraction:** Found in `flexColumns[0]`.
- **Metadata (Artist/Album):** Found in `flexColumns[1]` runs.
- **Multi-Shelf Search:** The parsing logic iterates through all response shelves (`musicShelfRenderer` and `musicCardShelfRenderer`) to capture "Top results", "Songs", and "Videos".

---

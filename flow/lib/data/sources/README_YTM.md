# YouTube Music Source (YTM) Implementation

This document provides a detailed technical overview of the `YoutubeMusicDataSource` and the surrounding data layer.

## Overview

The YTM data source provides a robust bridge between the YouTube Music InnerTube API and the Flow app's internal models. It prioritizes personalized content (Home Feed) and provides integrated access to both cloud and local libraries.

## Key Components

### 1. `YoutubeMusicDataSource`
The primary implementation of the `MusicDataSource` interface.
- **Parallel Fetching**: The `fetchHomeData` method executes multiple InnerTube calls in parallel to guarantee that specialized shelves (Quick Picks, Listen Again, Podcasts) are populated, even if they are missing from the primary home feed.
- **Smart Merging**: Results from sub-feeds are intelligently merged into the main feed model, replacing generic sections with personalized ones.
- **JIT Stream Resolution**: Integrated with `StreamResolver` to fetch audio URLs only when needed, reducing initial load times.

### 2. `YtmMapper`
A specialized utility for translating InnerTube's complex JSON renderers into clean app models.
- **Renderer Support**: Specifically optimized for `musicTwoRowItemRenderer`, `musicResponsiveListItemRenderer`, `musicItemRenderer`, and more.
- **Type Discovery**: Automatically distinguishes between Songs, Albums, Playlists, and Artists based on `browseId` patterns and subtitle analysis.
- **Thumbnail Optimization**: Maps standard YouTube thumbnails to high-resolution versions (e.g., 512x512 square for YTM items).

### 3. Integrated Library
The library screen logic has been unified:
- **Local Playlists**: Fetched from the `local_playlists` Hive box.
- **YTM Playlists**: Fetched from the authorized `FEmusic_library_playlists` endpoint.
- **Unified Model**: Both sources are mapped to `PlaylistModel` with a `type` tag (`yt` vs `local`), allowing the UI to render them consistently while supporting source-specific actions.

## Data Mapping Reference

| Internal Field | InnerTube Location | Logic / Notes |
|----------------|-------------------|---------------|
| `id` | `videoId` or `browseId` | Unique identifier for playback or navigation. |
| `title` | `runs[0].text` | The primary display name. |
| `subtitle` | `subtitle.runs` | Concatenated text for artist/metadata. |
| `thumbnail` | `thumbnails.last.url` | Replaced with `=w512-h512-p` for high-res. |
| `isAlbum` | `browseId` prefix | Identified by `MPREb_` or `FEmusic_album`. |

## Technical Implementation Details

### Home Feed Strategy
Flow uses a "Multi-Probe" strategy for the Home screen:
1.  **Probe 1**: Primary `FEmusic_home` browse call.
2.  **Probe 2-5**: Parallel calls for `Quick Picks` (via params), `Listen Again` (dedicated browse), and category-specific params (Podcasts, Relax).
3.  **Merge**: The app collects all shelves, deduplicates by title, and arranges them in the user's requested order.

### Playback Resiliency (`flow-jit`)
To prevent the "Rapid Skipping" bug, the player uses a `flow-jit` placeholder protocol. 
- When a playlist is loaded, only the current and immediate next tracks have resolved URLs.
- Farther tracks use `https://flow-jit/[id]`.
- The `PlayerBloc` listens for index changes and triggers JIT resolution *before* the player attempts to connect to the dummy host, ensuring smooth transitions without network errors.

## Authentication & Context
All requests are intercepted by `YoutubeInterceptor`, which:
1. Injects browser cookies from secure storage.
2. Generates a `SAPISIDHASH` using the `SAPISID` cookie for authorized InnerTube calls.
3. Sets mandatory headers (`Origin`, `Referer`, `User-Agent`) to prevent 403 errors.

## Research & Dumps
Raw data dumps for further research can be generated using:
```bash
dart run bin/yt_research.dart "YOUR_COOKIE_STRING"
```
Dumps are saved in `bin/dumps/` and are used to verify renderer updates.

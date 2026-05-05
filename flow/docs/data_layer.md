# Data Layer Documentation

The **Data Layer** in Flow is responsible for all external communications, data persistence, and the translation of raw data into domain-level entities. It follows a strict separation between data structures (Models) and business logic interfaces (Repositories).

## 1. Architecture Overview

The layer is organized into four main pillars:

### A. Sources (`lib/data/sources`)
Direct interfaces with external APIs or local storage.
- **`YoutubeMusicDataSource`**: Communicates with YouTube Music's InnerTube API. It returns a **streamlined feed** of raw sections (titles and items) without performing internal classification. This ensures the data layer remains "dumb" and resilient to API title changes.
- **`StreamResolver`**: Specialized component for extracting direct audio URLs. It rotates between different client types (e.g., `ANDROID_VR`, `WEB`) to ensure reliable playback.
- **`LocalStorage`**: Wrapper around **Hive** for ultra-fast metadata caching, settings, and user preferences.

### B. Models (`lib/data/models`)
Data Transfer Objects (DTOs) that represent the raw JSON structure.
- **`SongModel`**: Represents a track from any source. Includes serialization logic (`fromJson`, `toJson`) and a `toEntity()` method to map to the domain's `Song` entity.
- **`HomeDataModel`**: Represents the structured home screen with multiple sections (shelves).
- **`PlaylistModel`**: Represents user or system-generated playlists.

### C. Repositories (`lib/data/repositories`)
Concrete implementations of the `MusicRepository` interface defined in the Domain layer.
- **`YoutubeMusicRepository`**: The primary remote implementation.
- **`LocalMusicRepository`**: Handles offline data and local file management.
- **`CompositeMusicRepository`**: Orchestrates between local and remote sources (e.g., returning cached data while fetching fresh data from the network).

### D. Workers (`lib/data/workers`)
Background processes for tasks like audio pre-fetching or sync operations.

---

## 2. Intelligence & Classification Logic

The application supports a toggle-based intelligence system governed by the `INTELLIGENCE_ACTIVE` environment variable.

### Intelligence Active (`true`)
- **Domain Layer**: The `GetHomeDataUseCase` performs heuristic string matching on raw section titles (e.g., "Quick picks") to assign `section` types (e.g., `quickPicks`).
- **Presentation Layer**: `HomeCubit` adds synthetic shelves like "Flow Intelligence" (recommendations) and "Daily Rotation" (history-based).
- **UI**: The `HomeScreen` uses specialized layouts (grids, hero cards) for known section types and displays personalized greetings/mood chips.

### Intelligence Inactive (`false`)
- **Domain Layer**: Data is passed through exactly as it arrived from the source. No classification is performed.
- **Presentation Layer**: No synthetic shelves are added. Only the raw source feed is emitted.
- **UI**: The `HomeScreen` renders a generic vertical list of horizontal shelves. Personalized elements (greetings, mood chips) are hidden to provide a "pure" source experience.

---

## 3. Data Mapping Flow

1.  **Request**: A Use Case calls a method on the `MusicRepository`.
2.  **Fetch**: The `Repository` implementation calls a `Source` (e.g., `YoutubeMusicDataSource`).
3.  **Parse**: The `Source` receives raw JSON and passes it to a `Model` factory (e.g., `SongModel.fromJson`).
4.  **Transform**: The `Repository` calls `model.toEntity()` to convert the DTO into a pure Domain Entity.
5.  **Deliver**: The Domain layer receives a clean `Entity`, completely decoupled from the original JSON structure or source.

---

## 4. Domain Use Cases & Parameters

The Domain layer provides specific Use Cases that the Presentation layer (Cubits/Blocs) consumes. Each Use Case wraps a specific repository function.

| Use Case | Parameters | Return Type | Description |
| :--- | :--- | :--- | :--- |
| **`GetHomeDataUseCase`** | `int limit` (default: 25) | `Future<HomeData>` | Fetches structured home screen data. Applies classification if intelligence is active. |
| **`SearchSongsUseCase`** | `String query`, `int limit` (default: 25) | `Future<List<Song>>` | Searches for songs matching the query. Filters for "Songs" on YouTube Music. |
| **`GetPlaylistsUseCase`** | None | `Future<List<Playlist>>` | Retrieves the user's library playlists. |
| **`GetPlaylistTracksUseCase`**| `String playlistId` | `Future<List<Song>>` | Fetches all tracks contained within a specific playlist. |
| **`GetCategoriesUseCase`** | None | `List<Map<String, dynamic>>` | Returns static browse categories (Sync). |
| **`GetSongsUseCase`** | None | `Future<List<Song>>` | Compatibility use case; flattens home data into a song list. |

---

## 5. Key Implementation Details

### InnerTube Integration
The `YoutubeMusicDataSource` uses POST requests to `https://www.youtube.com/youtubei/v1/browse` and `/search`.
- **Context**: Every request includes a `_context` map defining the client as `ANDROID_TESTSUITE`.
- **Visitor Data**: Persisted in `LocalStorage` to maintain session consistency and improve recommendation quality.

### Consistency Rules
As per `GEMINI.md`:
- **Headers**: `X-YouTube-Client-Name` and `X-YouTube-Client-Version` must match the `context` to avoid `400 Bad Request`.
- **JIT Resolution**: Stream URLs are resolved "Just-In-Time" during playback to prevent expiration.

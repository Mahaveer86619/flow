# Domain Layer Documentation

The **Domain Layer** is the heart of the Flow application. It contains the core business logic, entities, and repository interfaces. It is designed to be completely independent of external data sources (like YouTube Music), databases (Hive), or the UI framework (Flutter).

## 1. Architecture Overview

The layer is organized into four main directories:

### A. Entities (`lib/domain/entities`)
Pure Dart objects that represent the core data structures used throughout the application.
- **`Song`**: The primary entity for a music track. Contains essential metadata (id, title, artist, duration, thumbnailUrl).
- **`Track`**: A metadata-rich extension of `Song`. It includes behavioral state (play count, skip count), tags (mood, energy), and audio features. It is used for advanced features like scoring and personalization. Use `Track.fromSong(song)` to convert.
- **`Playlist`**: Represents a collection of songs. It can represent a YouTube Music playlist, an album, or a "Flow" playlist (user-created within the app).
- **`HomeData`**: Represents the structured content of the home screen, organized into `HomeShelf` and `HomeItem`.
- **`HistoryData`**: Represents user playback history with date-based segmentation.

### B. Repositories (`lib/domain/repositories`)
Abstract interfaces that define the contract for data operations.
- **`MusicRepository`**: The main interface defining all required operations, from fetching home data to managing custom Flow playlists and record tracking. The Data layer provides concrete implementations (e.g., `YoutubeMusicRepository`).

### C. Use Cases (`lib/domain/usecases`)
Single-purpose classes that encapsulate specific business logic and orchestrate repository calls.
- **`GetHomeDataUseCase`**: Fetches and potentially classifies home screen data.
- **`SearchSongsUseCase`**: Handles music searching.
- **`GetPlaylistsUseCase`**: Retrieves the user's library.
- **`recordPlay` (via repo)**: Logic for tracking user behavior.

### D. Engines (`lib/domain/engines`)
The "intelligence" of the application. Engines process entities to provide advanced functionality.
- **`RecommendationEngine`**: Generates personalized song lists. It uses a similarity-based approach:
    - **Jaccard Similarity**: Used to compare text-based metadata like genres and tags.
    - **Audio Feature Distance**: Compares physical audio attributes like BPM and Energy to ensure recommendations match the current "vibe."
    - **Affinity Boosting**: Multiplies scores based on the user's historical affinity for specific artists.
- **`MoodEngine`**: Classifies music and filters recommendations by mood (e.g., "Chill", "Energy").
- **`ScoringGraph`**: Maintains a local "graph" of artists and songs, calculating scores based on user interaction (likes, plays, skips) to drive the recommendation logic.
- **`SyncEngine`**: Manages data synchronization between local storage and remote services.

---

## 2. The Song vs. Track Distinction

Flow uses two distinct entities for music tracks to balance performance and feature richness:

| Feature | `Song` | `Track` |
| :--- | :--- | :--- |
| **Purpose** | UI Display & Playback | Intelligence & Analytics |
| **Weight** | Lightweight | Heavy (Rich metadata) |
| **Source** | Direct from Data Layer | Derived from `Song` + Analytics |
| **Behavioral Data** | None | Play/Skip counts, Last played |
| **Usage** | Lists, Player, Search results | Scoring, Recommendations, History |

---

## 3. Intelligence & Heuristics

The Domain layer is responsible for making the "dumb" data from the source feel "smart."

### Home Screen Classification
In `GetHomeDataUseCase`, when `intelligenceActive` is enabled, the app applies heuristic string matching to raw shelf titles:
- "Quick picks" -> `quickPicks`
- "Listen again" -> `listeningAgain`
- "Similar to..." -> `recommendations`

This classification allows the Presentation layer to apply specialized layouts (e.g., a 2x4 grid for Quick Picks) instead of a generic horizontal list.

### Scoring Logic
The `ScoringGraph` (located in `engines`) updates a `graphScore` for artists and tracks. 
- **Positive Signals**: Full play, Repeat, Like.
- **Negative Signals**: Skip (especially early skip), Unlike.
These scores are persisted locally and used by the `RecommendationEngine` to prioritize content.

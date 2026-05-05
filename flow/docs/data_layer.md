# Data Layer Documentation

The **Data Layer** in Flow is responsible for all external communications, data persistence, and the translation of raw data into domain-level entities. It follows a strict separation between data structures (Models) and business logic interfaces (Repositories).

## 1. Architecture Overview

The layer is organized into four main pillars:

### A. Sources (`lib/data/sources`)
Direct interfaces with external APIs or local storage.
- **`YoutubeMusicDataSource`**: Communicates with YouTube Music's InnerTube API. It returns a **streamlined feed** of raw sections (titles and items) without performing internal classification. This ensures the data layer remains "dumb" and resilient to API title changes.
- **`StreamResolver`**: Specialized component for extracting direct audio URLs. It rotates between different client types (e.g., `ANDROID_VR`, `WEB`) to ensure reliable playback.
- **`LocalStorage`**: Wrapper around **Hive** for ultra-fast metadata caching, settings, and user preferences.

### B. Models & Mappers (`lib/data/models`)
Data Transfer Objects (DTOs) that represent the raw JSON structure and the logic to parse them.
- **`YtmMapper`**: The "Swiss Army Knife" of InnerTube parsing. It identifies and extracts data from various renderers (`musicTwoRowItemRenderer`, `musicResponsiveListItemRenderer`, etc.). It extracts:
    - **IDs**: Maps `videoId` for playback and `browseId` for navigation.
    - **Types**: Automatically classifies items as `song`, `video`, `artist`, `album`, or `playlist` based on ID prefixes and available fields.
    - **Thumbnails**: Upgrades low-resolution YouTube thumbnails to high-quality versions (e.g., `=w512-h512`).
- **`SongModel`**: Represents a track from any source. Includes serialization logic (`fromJson`, `toJson`) and a `toEntity()` method to map to the domain's `Song` entity.
- **`HomeDataModel`**: Orchestrates the parsing of the entire home screen. It takes the list of raw shelves provided by the source and uses `toEntity()` to map them into domain-level `HomeShelf` objects.

### C. Repositories (`lib/data/repositories`)
Concrete implementations of the `MusicRepository` interface defined in the Domain layer.
- **`YoutubeMusicRepository`**: The primary remote implementation. It uses `YtmMapper` to transform raw InnerTube responses into Models and then Entities.
- **`LocalMusicRepository`**: Handles offline data and local file management.
- **`CompositeMusicRepository`**: The central coordinator. It implements the "Cache-Then-Network" pattern, returning local data immediately while fetching fresh data in the background.

### D. Workers (`lib/data/workers`)
Background processes for tasks like audio pre-fetching or sync operations.

---

## 2. InnerTube Parsing Strategy

YouTube Music's API (InnerTube) returns deeply nested and highly variable JSON. The Data Layer handles this via a multi-stage process:

1.  **Extraction**: `YoutubeMusicDataSource` fetches raw JSON from endpoints like `/browse` or `/search`.
2.  **Item Identification**: `YtmMapper.parseItemRenderer` scans for known renderer keys (e.g., `musicItemRenderer`).
3.  **Heuristic Mapping**: 
    - Titles are extracted from `runs` or `simpleText`.
    - Artists are extracted from `subtitle` or `byline` fields.
    - Types are inferred: `MPREb...` (Album), `UC...` (Artist), `VLRD...` (Radio).
4.  **Normalization**: All items are normalized into `YtmItem` (internal DTO) before being converted to `SongModel` or `PlaylistModel`.

---

## 3. Data Mapping Flow

1.  **Request**: A Use Case calls a method on the `MusicRepository`.
2.  **Fetch**: The `Repository` implementation calls a `Source` (e.g., `YoutubeMusicDataSource`).
3.  **Parse**: The `Source` receives raw JSON. `YtmMapper` is used to identify and normalize items into Models.
4.  **Transform**: The `Repository` (via `Model.toEntity()`) converts the DTO into a pure Domain Entity.
5.  **Deliver**: The Domain layer receives a clean `Entity`, completely decoupled from the original JSON structure or source.

---

## 4. Playback & Stream Resolution

The `StreamResolver` handles the complexity of obtaining playable URLs:
- **Client Rotation**: If one client (e.g., `ANDROID`) returns a `403`, it automatically tries another (e.g., `WEB_REMIX`).
- **Just-In-Time (JIT)**: URLs are resolved only when a track is about to play to avoid expiration.
- **Interceptor**: `YoutubeInterceptor` ensures all requests include the necessary headers and visitor data to pass YouTube's security checks.

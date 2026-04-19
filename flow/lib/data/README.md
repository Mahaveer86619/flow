# Data Layer

The **Data** layer is responsible for retrieving data from external sources (APIs, Local Database) and mapping it into Domain entities.

## Architecture

- **`sources/`**: Direct communication with 3rd party providers.
  - `YoutubeMusicDataSource`: Interacts with InnerTube APIs (`/browse`, `/search`, `/next`).
  - `StreamResolver`: Specialized component for extracting direct audio URLs using client rotation (e.g., `ANDROID_VR`).
  - `MockSongDataSource`: In-memory data for testing and offline development.
- **`repositories/`**: Implementations of Domain repository interfaces.
  - Orchestrates calls between multiple DataSources (e.g., check cache then hit API).
  - Handles data persistence using `LocalStorage`.
- **`models/`**: Data Transfer Objects (DTOs).
  - Contains JSON serialization logic (`fromJson`, `toJson`).
  - Implements mapping to Domain entities (`toEntity`).

## Key Technologies
- **Dio**: HTTP client for all API requests.
- **Hive**: NoSQL local database for ultra-fast metadata caching and settings.
- **YoutubeExplode**: Used as a fallback for stream resolution when InnerTube fails.

## Data Mapping Flow
1. `Source` returns `Map<String, dynamic>`.
2. `Model` parses JSON into a DTO.
3. `Repository` calls `Model.toEntity()`.
4. `Domain` layer receives the pure `Entity`.

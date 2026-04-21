# Flow Data Layer & YouTube Music Integration

This document explains how Flow fetches, parses, and manages music data from YouTube Music.

## 1. The Source: YouTube InnerTube API

Flow does not use the public YouTube Data API (v3). Instead, it communicates with **InnerTube**, YouTube's internal private API used by their official applications.

### Key Characteristics:
- **Endpoints**: `https://music.youtube.com/youtubei/v1/browse`, `/search`, `/next`, etc.
- **Payloads**: Requests and responses are in JSON format, but are extremely deeply nested and complex.
- **Context**: Every request includes a `context` object specifying the client (e.g., `WEB_REMIX` for web-like behavior, `ANDROID_VR` for stable stream URLs).
- **Authentication**: Uses `visitorData` (for anonymous sessions) and cookies (for authenticated sessions) passed in the headers.

---

## 2. Data Fetching Architecture

The data layer is divided into three main components: **Data Sources**, **Models**, and **Repositories**.

### A. Data Sources (`YoutubeMusicDataSource`)
This is the lowest level of the data layer. It handles the "dirty work" of networking and raw JSON traversal.

1.  **Networking**: Uses the `Dio` library to make HTTP POST requests to InnerTube endpoints.
2.  **JSON Traversal**: InnerTube responses often have 10-15 levels of nesting. The Data Source safely navigates these (e.g., `data['contents']['singleColumnBrowseResultsRenderer']['tabs'][0]...`) to find relevant music items.
3.  **Heuristics & Fallbacks**: 
    *   Since InnerTube is undocumented, Flow uses heuristics (like checking if a title contains "Listen Again") to categorize sections.
    *   If the primary Home Feed is missing personalized sections, it automatically triggers "sub-feed" requests to dedicated endpoints like `FEmusic_listen_again`.
4.  **Thumbnail Optimization**: Flow processes thumbnail URLs to ensure high quality and square aspect ratios by manipulating URL parameters (e.g., replacing size tokens with `=w512-h512-p`).

### B. Data Models (`SongModel`, `HomeDataModel`)
Models are Dart classes that represent the structure of the data as it comes from the source. They include `fromJson` and `toJson` methods for easy serialization and persistence.

### C. Repositories (`YoutubeMusicRepository`)
The Repository acts as a bridge between the Data Layer and the Domain Layer.

1.  **Abstraction**: It implements an interface defined in the Domain layer, meaning the rest of the app doesn't know *where* the music comes from (it could be YouTube, Spotify, or local files).
2.  **Entity Mapping**: It converts **Data Models** into **Domain Entities** (`Song`, `HomeData`). Entities are "clean" objects optimized for the UI.
3.  **Persistence & Caching**: It interacts with `LocalStorage` (Hive) to save listening history, cache home screen data, and manage liked songs.

---

## 3. Data Flow Example: Loading the Home Screen

1.  **Presentation**: `HomeCubit` calls `repository.getHomeData()`.
2.  **Repository**: 
    *   Checks if there's a fresh cache in Hive.
    *   If not, calls `dataSource.fetchHomeData()`.
3.  **Data Source**: 
    *   Fetches raw JSON from the InnerTube `/browse` endpoint.
    *   Parses the "shelves" (horizontal rows).
    *   If "Quick Picks" is missing, fetches the sub-feed.
    *   Maps raw items into `SongModel` or `PlaylistModel`.
4.  **Repository**: 
    *   Converts models into `Song` and `HomeData` entities.
    *   Saves the result to local cache.
5.  **Presentation**: Receives the clean `HomeData` and updates the UI.

---

## 4. Other Layers (Simplified)

*   **Domain Layer**: Defines the "What". It contains the core business logic, entity definitions, and repository interfaces. It is pure Dart and has no dependencies on Flutter or external APIs.
*   **Core Layer**: Contains infrastructure code like the `AudioPlayer` wrapper, `LocalStorage` setup, and logging utilities.
*   **Presentation Layer**: The Flutter UI. It uses the BLoC/Cubit pattern to manage state and react to user interactions.

# Home Screen Deduplication & Title Refresh Design

**Goal:** Ensure a unique user experience on the home screen by eliminating duplicate songs across different sections and providing distinct, descriptive titles/subtitles for each section.

## 1. Architecture

### 1.1. Data Flow & Deduplication
The deduplication logic will reside in the `HomeCubit`. This ensures that the UI receives a clean, filtered list of shelves and songs, maintaining a single source of truth for data integrity.

- **Process:**
    1. Fetch `HomeData` from the use case.
    2. Iterate through `shelves` in their intended display order.
    3. Maintain a `Set<String>` of `seenSongIds`.
    4. For each shelf, filter its `items`:
        - If an item is a `song`, check if its ID is in `seenSongIds`.
        - If not seen, add ID to `seenSongIds` and keep the song.
        - If seen, discard the song from this shelf.
    5. Update the `HomeState` with the deduplicated shelves.

### 1.2. UI Refresh
The `home_screen.dart` and `_HomeShelfRenderer` will be updated to use a more diverse set of titles and subtitles.

- **Naming Strategy:**
    - **Quick picks:** Title: "Jump Back In" | Subtitle: "Your current favorites"
    - **Listen again:** Title: "Your Daily Rotation" | Subtitle: "Based on your history"
    - **Fresh Picks:** Title: "Fresh Finds" | Subtitle: "New music for you"
    - **Long Listening:** Title: "Deep Dives" | Subtitle: "Long tracks & sets"
    - **Podcasts:** Title: "Podcasts" | Subtitle: "Stories and conversations"
    - **Albums:** Title: "Albums for You" | Subtitle: "Expand your collection"

## 2. Components

### 2.1. HomeCubit (`lib/presentation/cubits/home/home_cubit.dart`)
- **New Method:** `_deduplicateShelves(List<HomeShelf> shelves)`
- **Responsibility:** Implements the filtering logic described in 1.1.

### 2.2. HomeScreen (`lib/presentation/screens/home/home_screen.dart`)
- **Responsibility:** Updates hardcoded section titles in `requestedSections` and subtitles in `_HomeShelfRenderer` build methods.

## 3. Testing Strategy

- **Unit Tests (`HomeCubit`):**
    - Verify that `_deduplicateShelves` correctly removes duplicate songs across multiple shelves.
    - Verify that it preserves the first occurrence of a song.
    - Verify that it doesn't affect non-song items (artists, playlists).
- **Widget Tests (`HomeScreen`):**
    - Verify that the new titles and subtitles are rendered correctly.
    - (Manual verification) Scroll through the home screen to ensure no duplicate songs are visible.

## 4. Success Criteria
1. No song (by ID) appears more than once in the entire home scroll.
2. Every section has a unique and descriptive title/subtitle combination.
3. Repetitive "personalized for you" text is removed.

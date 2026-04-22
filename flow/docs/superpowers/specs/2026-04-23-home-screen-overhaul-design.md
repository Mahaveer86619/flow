# Home Screen Comprehensive Overhaul Design

**Goal:** Transform the Home screen into a premium, highly personalized hub with dynamic shelves driven by user behavior and a modern "Glass & Flow" aesthetic.

## 1. Architecture & Logic

### 1.1. Dynamic Shelves (Strict Order)
1.  **Daily Rotation (`listeningAgain`):**
    *   **Content:** Pure songs (no playlists/albums).
    *   **Logic:** local history (top played) + YT "Listen Again".
2.  **Jump Back In (`quickPicks`):**
    *   **Logic:** Promotes artists from recent searches and most-repeated local tracks.
    *   **Sorting:** Top-played/recently searched first. Limit: 20 items.
3.  **Music Videos for You (`musicVideos`):**
    *   **Logic:** Filters recommended tracks for those with rectangular thumbnails (16:9).
4.  **Albums for You:**
    *   **Logic:** Fetches similar artists based on top 5 local artists. Discovered artists are saved to an "interest list".
5.  **Deep Dives (`longListening`):**
    *   **Logic:** Specifically for Lofi/Long tracks based on duration and keyword tracking.
6.  **Podcasts:**
    *   **Logic:** Dedicated shelf for podcast content.

### 1.2. Tracking Engine
We will enhance `LocalStorage` and `MusicRepository` to track:
- `artist_play_counts`: To identify top 5 artists.
- `search_artist_history`: To prioritize "Jump Back In" items.
- `interest_list`: Persistently stored similar artists discovered via "Albums for You".

## 2. Visual Design ("Material Flow")

### 2.1. Background & App Bar
- **Material 3 Surface:** The `SliverAppBar` will use a Material 3 `surfaceContainer` tint with a high-quality blur effect and a subtle primary/secondary gradient.
- **Continuous Pattern:** A custom `BackgroundPatternPainter` will render a subtle, modern geometric or organic pattern using Material tonal colors (e.g., `surfaceVariant`) that starts at the top and continues behind the entire scrollable area.
- **Spacing:** Optimized Material spacing (using `surfaceContainerLow` for the base and `surfaceContainerHigh` for headers) to remove awkward gaps and ensure a unified scroll.

### 2.2. Header Modernization
- **Typography:** `Space Grotesk`, FontWeight 800, tight letter-spacing.
- **Icons:** Modern, thin-stroke icons (e.g., `huge_icons` style or clean Material symbols).
- **Subtitles:** Unique, descriptive text (e.g., "Your Daily Rotation" -> "Based on your history").

## 3. Interaction
- **Playback:** Clicking a song card will trigger playback in the **Mini Player** only. `PlayerScreen.show(context)` will be removed from the tap handler in the home context.

## 4. Components to Modify
- `lib/presentation/screens/home/home_screen.dart`: Complete structural rewrite of the sliver list.
- `lib/presentation/cubits/home/home_cubit.dart`: Update `_load` logic to implement the new shelf filtering/sorting.
- `lib/core/storage/local_storage.dart`: Add new tracking methods.
- `lib/presentation/widgets/song_card.dart`: Conditional navigation (skip full player on Home).
- `lib/presentation/widgets/section_header.dart`: Redesign for modern look.

## 5. Success Criteria
1.  Home screen strictly follows the new shelf order.
2.  No duplicate songs; no playlists in "Daily Rotation".
3.  Premium blurred App Bar with continuous background pattern.
4.  Songs play in background (Mini Player) without interrupting browsing.

# Enhanced Home Feed & Recommendation System Design

**Date:** 2026-04-14
**Topic:** Improving the Home Feed and adding a lightweight recommendation system.

## 1. Problem Statement
The current home feed in the Flow music app is not sufficiently personalized. Users report that their YTMusic preferences are not properly reflected, and key sections like "Quick Picks" and "Listen Again" are often missing due to fragile shelf title mapping. Additionally, there is no local recommendation layer that combines search history, play counts, and genre preferences with YTMusic's existing data.

## 2. Proposed Solution
A hybrid recommendation system that combines the best of YTMusic's personalized data with a local tracking and ranking layer.

### 2.1 Fixed Home Feed Logic
- Update the `YTMusicService._classify_shelf` logic to use more resilient keywords and fallback detection.
- Enforce a strict ordering for shelves on the home screen:
    1. **Quick Picks** (`quickPicks`)
    2. **Listening Again** (`listeningAgain`)
    3. **Fresh Picks** (`freshFinds` - our custom system)
    4. **Trending** (`trending`)
    5. **Other shelves** (Moods, Similar To, etc.)

### 2.2 Local Interaction & Tracking Layer
- Introduce a `UserSongInteraction` table to store:
    - `id`, `user_id`, `song_id`, `play_count`, `last_played_at`, `genre_tags` (JSON).
- Add a mechanism to infer and store `UserGenrePreference`:
    - Tracks scores for genres based on interactions (e.g., +1 for a play, +3 for a repeat play, +5 for a "liked" status).

### 2.3 Lightweight Recommendation Engine ("Fresh Picks")
- **Frequency**: Triggered on every `/home` fetch (with a 5-minute cache).
- **Process**:
    1. **Identify Seeds**: Weighted blend of:
        - 3 most recently played songs.
        - 3 most frequently played songs.
        - Top 2 genres for the user.
    2. **Fetch Related**: For each seed song ID, call `ytm.get_watch_playlist(videoId=seed_id, limit=5)` to get related/radio tracks.
    3. **Mix Trends**: Fetch genre-specific trending releases from `ytm.get_explore()`.
    4. **Rank & Filter**:
        - Remove already seen/played songs.
        - Rank by "similarity score" (genre match + YTMusic's internal ranking).
    5. **Persistence**: Save final recommendations to a `UserRecommendation` table to allow for quick retrieval.

### 2.4 Data Flow
1. User requests `/home`.
2. Backend fetches YTMusic home shelves.
3. Backend checks for local recommendations in the `UserRecommendation` table.
4. If missing or stale (>1 hour), backend triggers a background task to recalculate "Fresh Picks".
5. Backend injects "Fresh Picks" as the third shelf.
6. Frontend renders shelves in the prescribed order.

## 3. Architecture & Data Models

### 3.1 SQLAlchemy Models (Backend)
- **`UserSongInteraction`**:
    - `id: int`
    - `user_id: int`
    - `song_id: str`
    - `play_count: int`
    - `last_played_at: datetime`
    - `genre_tags: str` (JSON)
- **`UserRecommendation`**:
    - `id: int`
    - `user_id: int`
    - `song_id: str`
    - `data: str` (JSON - serialized `SongResponse`)
    - `score: float`
    - `updated_at: datetime`

### 3.2 Home Screen Ordering (Frontend)
- The Flutter `HomeScreen` will be updated to explicitly filter and order the `HomeShelf` list before rendering.

## 4. Testing Plan
- **Unit Tests**:
    - Verify `_classify_shelf` handles a wider range of titles.
    - Test the recommendation scoring logic with mock user interactions.
- **Integration Tests**:
    - Ensure `/home` endpoint returns the correct shelf order and content.
- **Manual Verification**:
    - Confirm the "Fresh Picks" section appears on the third shelf and contains relevant, fresh songs.

## 5. Success Criteria
- "Quick Picks" and "Listen Again" sections are consistently present for authenticated users.
- The "Fresh Picks" section provides a mix of familiar and discoverable songs that match the user's top genres and history.
- The system remains lightweight, with home feed fetching completing in under 2 seconds.

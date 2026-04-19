# Design Spec: Home Screen Personalized Shelves

Enable a personalized home screen experience by fetching the YouTube Music "Home" feed using authenticated cookies and prioritizing specific shelves (Quick Picks, Listen Again, and Music Videos).

## 1. Context & Goals

The current home screen often falls back to a public "New Releases" or search-based feed because it lacks proper authentication headers in its `FEmusic_home` request. 

**Goals:**
- Fetch the personalized `FEmusic_home` feed using the user's YouTube cookies.
- Prioritize and pin three specific shelves at the top: **Listen again**, **Quick picks**, and **Music videos**.
- Implement a "Priority Mode" where these three appear first, followed by other personalized shelves (Mixed for you, Similar to, etc.).
- Provide robust fallbacks for missing shelves (e.g., local history for "Listen again").

## 2. Technical Architecture

### 2.1 Data Layer (`YoutubeMusicDataSource`)
- **Authentication**: Rely on the existing `YoutubeInterceptor` which automatically injects cookies from `SecureStorageService` into requests to `music.youtube.com`.
- **Fetching**: Update `fetchHomeData` to consistently target `FEmusic_home`.
- **Parsing**: 
    - Enhance `_parseHomeData` to identify shelves by title (case-insensitive matching).
    - Map specific titles to `sectionType`:
        - `listeningAgain`: "Listen again", "Recent", "Frequent"
        - `quickPicks`: "Quick picks"
        - `musicVideos`: "Music videos", "Videos for you"
    - Ensure `musicTwoRowItemRenderer` is correctly handled for the "Quick picks" 4-row grid.

### 2.2 Domain Layer
- **Entities**: Ensure `HomeShelf` entity in `flow/lib/domain/entities/home_data.dart` supports the required section types. (Already supported by current model/entity mapping).

### 2.3 Presentation Layer (`HomeScreen`)
- **Shelf Reordering**: 
    - Update the logic in `HomeScreen` to extract and pin the three priority shelves at the top of the `CustomScrollView`.
    - Ensure "Listen again" is Priority 1, "Quick picks" is Priority 2, and "Music videos" is Priority 3.
- **Shelf Rendering**:
    - `_buildListenAgainShelf`: Standard horizontal list of song cards.
    - `_buildQuickAccessRow`: 4-row horizontal list for "Quick picks" (Start Radio style).
    - `_buildVideoRow`: Horizontal list with 16:9 aspect ratio cards.
- **Fallbacks**:
    - If `listeningAgain` is empty, use data from the app's local history database.
    - If `musicVideos` is empty, fetch "Trending Music Videos" via a fallback search.

## 3. Data Flow
1. `HomeCubit` calls `HomeRepository.getHomeData()`.
2. `YoutubeMusicDataSource` performs a POST to `FEmusic_home`.
3. `YoutubeInterceptor` adds `Cookie` and `User-Agent` from `SecureStorageService`.
4. `YoutubeMusicDataSource` parses the JSON, identifying the priority shelves.
5. `HomeScreen` receives `HomeData` and reorders the `SliverList` to place priority shelves at the top.

## 4. Error Handling & Edge Cases
- **No Cookies**: If cookies are missing/expired, `FEmusic_home` returns a public feed. The app will fall back to its current public data fetching logic.
- **Empty Shelves**: If a priority shelf is missing from the YT response, the UI will trigger the local/search fallback instead of hiding the section entirely.

## 5. Success Criteria
- Home screen shows "Listen again", "Quick picks", and "Music videos" as the first three items.
- The content is personalized based on the user's YT Music account.
- The 16:9 layout is correctly applied to the Music Videos shelf.

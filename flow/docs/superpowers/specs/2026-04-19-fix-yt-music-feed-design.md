# Plan: Fix YouTube Music Feed Fetching

The goal is to correctly fetch and parse the personalized YouTube Music feed, including sections like "Quick Picks", "Listen Again", "Long Listening", and "Forgotten Favorites".

## Research Findings
- The current implementation uses the `WEB_REMIX` client and `FEmusic_home` browseId.
- Parsing logic in `YoutubeMusicDataSource._parseHomeData` is limited to a few section titles and shelf types.
- Fallback logic triggers too easily (if any part of the parsing returns empty).
- Authentication headers (cookies) are injected via `YoutubeInterceptor`, but the request context in `fetchHomeData` is minimal, which might lead to generic responses from YouTube.

## Proposed Changes

### 1. Data Layer: `YoutubeMusicDataSource`
- **Update `fetchHomeData` Request:**
    - Increase `clientVersion` to a more recent one (e.g., `1.20240409.01.01`).
    - Add more detailed `client` context fields (`osName`, `osVersion`, `platform`, `userAgent`, etc.) to better mimic a real browser.
- **Enhance `_parseHomeData`:**
    - Improve shelf extraction to be more flexible (handle nested `itemSectionRenderer` more robustly).
    - Expand section title matching to include more keywords:
        - "long listening" -> `longListening`
        - "forgotten favorites" -> `forgottenFavorites`
        - "similar to", "fans also like" -> `similarTo`
        - "albums" -> `albumsForYou`
        - "charts" -> `topCharts`
        - "new arrivals", "new releases" -> `newArrivals`
        - "mixed for you", "recommended" -> `mixedForYou`
    - Handle `tastebuilderItems` in `musicTastebuilderShelfRenderer`.
- **Improve `_parseMytmItem`:**
    - Ensure `musicTwoRowItemRenderer` and other formats are correctly parsed for both songs and playlists/artists.
    - Improve artist name extraction from various `runs` structures.

### 2. Verification Plan
- **Manual Verification:**
    - Use logs to verify that `FEmusic_home` is successfully called and returned sections are parsed.
    - Confirm that the Home screen displays the newly added sections when available.
- **Automated Verification:**
    - Run existing tests to ensure no regressions in search and other data source functions.
    - Add a unit test for the new parsing logic if time permits.

## Success Criteria
- The Home screen displays personalized sections instead of fallback "Trending" search results when cookies are provided.
- Sections like "Listen Again" and "Quick Picks" appear at the top of the feed as intended.

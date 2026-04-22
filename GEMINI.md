# Flow Development Rules

## 1. Test-Driven Research (TDR) Mandate

Before attempting to fix any issue related to external data (YouTube Music API, Spotify, etc.) or complex state logic, you MUST follow the Test-Driven Research workflow:

1.  **Evidence Gathering:** Do not guess the structure of API responses. Use existing dump scripts (e.g., `bin/yt_research.dart`) or create temporary test cases to generate raw JSON dumps in the `bin/` directory.
2.  **Personalized Verification:** If the issue involves personalized content (Home feed, Library), use the `bin/test-cookie.txt` mechanism to fetch data using actual user sessions.
3.  **Analysis before Action:** Analyze the generated dumps to confirm the exact location of fields (e.g., view counts, shelf titles, playability status) before modifying parsing or resolution logic.
4.  **Regression Dumps:** After implementing a fix, generate a fresh dump to verify that the parsing logic now correctly handles the real-world data structure.
5.  **Logging:** Always log the results of your research (e.g., "Shelf X found with 0 items, expected Y") in your thoughts and terminal output to provide a clear audit trail of why a logic change was made.

## 2. API Consistency

When updating InnerTube API calls, ensure consistency across the `YoutubeMusicDataSource`, `StreamResolver`, and `YoutubeInterceptor`. 
- **Headers:** Always use modern client versions (e.g., `ANDROID_TESTSUITE`) and matching `X-YouTube-Client-Name` / `X-YouTube-Client-Version` headers to prevent `400 Bad Request` or `403 Forbidden` errors.
- **Cookies:** Always check for saved cookies in `SecureStorageService` to bypass bot detection.

## 3. Playback Resiliency

Never resolve all stream URLs at once for large playlists. Use the `flow-jit` protocol (Just-In-Time resolution) to fetch URLs only for the current and next tracks to avoid expiration and rate-limiting issues.

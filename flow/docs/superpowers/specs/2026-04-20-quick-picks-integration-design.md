# Design Spec: Quick Picks Integration and Feed Optimization

Correctly fetch and parse the personalized "Quick Picks" shelf from YouTube Music by optimizing the request context and refining the data parsing logic.

## 1. Context & Goals

Previously, "Quick Picks" and other personalized shelves were missing or failing because the request context was too generic and standalone sub-feed calls (`FEmusic_quick_picks`) were unreliable.

**Goals:**
- Update the InnerTube context to mimic a real desktop browser more accurately.
- Consolidate home feed fetching into a robust single call to `FEmusic_home`.
- Correctly parse the "Quick picks" shelf and its associated items.
- Ensure the Home screen displays this data as intended.

## 2. Technical Architecture

### 2.1 Data Layer (`YoutubeMusicDataSource`)

#### Request Context Update
The static `_context` will be updated to include more specific client details. This has been verified in debug tests to trigger personalized shelf returns.

```json
{
  "client": {
    "clientName": "WEB_REMIX",
    "clientVersion": "1.20240409.01.01",
    "osName": "Windows",
    "osVersion": "10.0",
    "platform": "DESKTOP",
    "hl": "en",
    "gl": "US",
    "utcOffsetMinutes": 0
  },
  "user": {
    "lockedSafetyMode": false
  }
}
```

#### Fetching Logic
- `fetchHomeData` will focus on a high-quality `FEmusic_home` call.
- Remove or demote `FEmusic_listen_again` and `FEmusic_quick_picks` standalone calls to fallback status only if needed.

#### Parsing Logic
- **Shelf Identification:** Update `_parseHomeDataInternal` to map "Quick picks" (and variants) to `sectionType = 'quickPicks'`.
- **Item Extraction:** Enhance `_parseMytmItem` to support `musicTwoRowItemRenderer` and handle complex `runs` structures for artist names.

### 2.2 Presentation Layer (`HomeScreen`)
- Verify that `_buildQuickAccessRow` handles the `quickPicks` data structure.
- Ensure the shelf is placed at the top of the feed (Priority 2, after "Listen Again").

## 3. Data Flow
1. `HomeCubit` requests home data.
2. `YoutubeMusicDataSource` calls `FEmusic_home` with enhanced context.
3. YouTube returns personalized shelves including "Quick Picks".
4. DataSource parses these into `HomeShelf` entities with the `quickPicks` type.
5. `HomeScreen` renders these using the specialized staggered grid layout.

## 4. Verification Plan
- **Automated Test:** Run `test/ytm_debug_test.dart` to verify that `rawShelves` now contains a "Quick picks" section with items.
- **Manual Verification:** Launch the app and confirm the "Quick Picks" shelf appears on the Home screen with correct song data and thumbnails.

## 5. Success Criteria
- "Quick Picks" shelf appears consistently for authenticated users.
- Home feed loads faster due to fewer (and more successful) network calls.
- Item metadata (title, artist, high-res thumbnail) is correctly parsed.

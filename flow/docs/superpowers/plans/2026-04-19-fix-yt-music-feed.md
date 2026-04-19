# Fix YouTube Music Feed Fetching Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Correctly fetch and parse the personalized YouTube Music feed, including sections like "Quick Picks", "Listen Again", "Long Listening", and "Forgotten Favorites".

**Architecture:** Update the `YoutubeMusicDataSource` to use a more modern request context and a more robust parsing strategy for home shelves and items.

**Tech Stack:** Dart, Dio, YouTube Music Internal API (YTMusicAPI patterns).

---

### Task 1: Update Home Data Request Context

**Files:**
- Modify: `lib/data/sources/youtube_music_data_source.dart`

- [ ] **Step 1: Update the request payload in `fetchHomeData`**

Update the `context` object in the `FEmusic_home` request to include more realistic client details.

```dart
// lib/data/sources/youtube_music_data_source.dart

// ... inside fetchHomeData ...
      final response = await _dio.post(
        '$_ytmBase/browse?prettyPrint=false',
        data: {
          "browseId": "FEmusic_home",
          "context": {
            "client": {
              "clientName": "WEB_REMIX",
              "clientVersion": "1.20240409.01.01",
              "osName": "Windows",
              "osVersion": "10.0",
              "platform": "DESKTOP",
              "hl": "en",
              "gl": "US",
              "utcOffsetMinutes": 0,
            },
            "user": {
               "lockedSafetyMode": false
            }
          }
        },
      );
```

- [ ] **Step 2: Commit**

```bash
git add lib/data/sources/youtube_music_data_source.dart
git commit -m "feat(data): update YT Music home request context for better feed results"
```

---

### Task 2: Enhance Shelf Type Identification

**Files:**
- Modify: `lib/data/sources/youtube_music_data_source.dart`

- [ ] **Step 1: Expand sectionType mapping in `_parseHomeData`**

Add more keywords and section types to match the expected home feed sections.

```dart
// lib/data/sources/youtube_music_data_source.dart

// ... inside _parseHomeData loop ...
        String sectionType = 'standard';
        if (title != null) {
          final t = title.toLowerCase();
          if (t.contains('listen again') || t.contains('recent') || t.contains('frequent')) {
            sectionType = 'listeningAgain';
          } else if (t.contains('quick picks')) {
            sectionType = 'quickPicks';
          } else if (t.contains('mixed for you') || t.contains('recommended') || t.contains('start radio')) {
            sectionType = 'mixedForYou';
          } else if (t.contains('trending')) {
            sectionType = 'trending';
          } else if (t.contains('music video') || t.contains('videos for you')) {
            sectionType = 'musicVideos';
          } else if (t.contains('long listening')) {
            sectionType = 'longListening';
          } else if (t.contains('forgotten favorites')) {
            sectionType = 'forgottenFavorites';
          } else if (t.contains('similar to') || t.contains('fans also like')) {
            sectionType = 'similarTo';
          } else if (t.contains('album')) {
            sectionType = 'albumsForYou';
          } else if (t.contains('chart')) {
            sectionType = 'topCharts';
          } else if (t.contains('new arrival') || t.contains('new release')) {
            sectionType = 'newArrivals';
          }
        }
```

- [ ] **Step 2: Handle `musicTastebuilderShelfRenderer` specifically**

Extract items from the `tastebuilderItems` list if `contents` is empty.

```dart
// lib/data/sources/youtube_music_data_source.dart

// ... inside _parseHomeData ...
        final List<dynamic> shelfItems = (shelf['contents'] as List<dynamic>?) ?? 
                                         (shelf['tastebuilderItems'] as List<dynamic>?) ?? [];
```

- [ ] **Step 3: Commit**

```bash
git add lib/data/sources/youtube_music_data_source.dart
git commit -m "feat(data): expand home feed section parsing for personalized shelves"
```

---

### Task 3: Improve Item Parsing Logic

**Files:**
- Modify: `lib/data/sources/youtube_music_data_source.dart`

- [ ] **Step 1: Enhance `_parseMytmItem` to handle `musicTwoRowItemRenderer` details**

Ensure artist and subtitle info is correctly extracted for various item types.

```dart
// lib/data/sources/youtube_music_data_source.dart

// ... inside _parseMytmItem ...
        String artist = 'Unknown Artist';
        if (renderer['flexColumns'] != null && (renderer['flexColumns'] as List).length > 1) {
          final runs = renderer['flexColumns']?[1]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List?;
          if (runs != null && runs.isNotEmpty) {
            artist = runs.map((r) => r['text']).join('');
          }
        } else if (renderer['longBylineText'] != null) {
          final runs = renderer['longBylineText']?['runs'] as List?;
          if (runs != null && runs.isNotEmpty) {
            artist = runs.map((r) => r['text']).join('');
          }
        } else if (renderer['shortBylineText'] != null) {
          final runs = renderer['shortBylineText']?['runs'] as List?;
          if (runs != null && runs.isNotEmpty) {
            artist = runs.map((r) => r['text']).join('');
          }
        } else if (renderer['subtitle'] != null) {
          final runs = renderer['subtitle']?['runs'] as List?;
          if (runs != null && runs.isNotEmpty) {
             // Often: [Artist, Type, Views] or [Artist, Year]
             // We take all runs until we hit a separator or end
             artist = runs.map((r) => r['text']).where((t) => t != ' • ').join('');
          }
        }
```

- [ ] **Step 2: Add support for `musicTwoColumnItemRenderer` if missing**

(Note: Already present in code, but ensure it's handled in the renderer identification).

- [ ] **Step 3: Commit**

```bash
git add lib/data/sources/youtube_music_data_source.dart
git commit -m "feat(data): improve item parsing for home feed renderers"
```

---

### Task 4: Verification and Final Polish

**Files:**
- Modify: `lib/data/sources/youtube_music_data_source.dart`

- [ ] **Step 1: Add more debug logging for feed parsing**

Log the raw section titles and first item types to aid in debugging if sections still don't show up.

- [ ] **Step 2: Verify with manual run**

Check the logs for: `Parsed shelf: "Listen Again" (20 items)` etc.

- [ ] **Step 3: Commit**

```bash
git commit -am "chore(data): add enhanced logging for home feed parsing"
```

# Quick Picks Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Correctly fetch and parse the personalized "Quick Picks" shelf from YouTube Music.

**Architecture:** Update the InnerTube request context to trigger personalized results, optimize the home feed fetching into a single robust call, and enhance the parsing logic for shelves and items.

**Tech Stack:** Dart, Dio, YouTube Music Internal API.

---

### Task 1: Update Request Context and Section Mapping

**Files:**
- Modify: `lib/data/sources/youtube_music_data_source.dart`
- Test: `test/ytm_debug_test.dart`

- [ ] **Step 1: Update the static `_context` object**

Update the client details to mimic a modern desktop browser.

```dart
// lib/data/sources/youtube_music_data_source.dart

  // Standard InnerTube context
  final Map<String, dynamic> _context = {
    "client": {
      "clientName": "WEB_REMIX",
      "clientVersion": "1.20240409.01.01",
      "hl": "en",
      "gl": "US",
      "utcOffsetMinutes": 0,
      "osName": "Windows",
      "osVersion": "10.0",
      "platform": "DESKTOP",
    },
    "user": {
      "lockedSafetyMode": false,
    }
  };
```

- [ ] **Step 2: Expand shelf title mapping in `_parseHomeDataInternal`**

Ensure "Quick picks" and other variants are correctly categorized.

```dart
// lib/data/sources/youtube_music_data_source.dart

// ... inside _parseHomeDataInternal loop ...
      if (forcedSectionType == null && title != null) {
        final t = title.toLowerCase();
        if (t.contains('listen again') || t.contains('recent') || t.contains('frequent')) {
          sectionType = 'listeningAgain';
        } else if (t.contains('quick picks') || t.contains('start radio') || t.contains('speed dial') || t.contains('picks')) {
          sectionType = 'quickPicks';
        }
        // ... (rest of mapping remains)
```

- [ ] **Step 3: Verify with debug test**

Run: `dart test test/ytm_debug_test.dart --name "Fetch Home Feed and Print Raw Structure"`
Expected: Output shows a shelf with section: `quickPicks`.

- [ ] **Step 4: Commit**

```bash
git add lib/data/sources/youtube_music_data_source.dart
git commit -m "feat(data): update request context and shelf mapping for quick picks"
```

---

### Task 2: Enhance Item Parsing for Personalized Shelves

**Files:**
- Modify: `lib/data/sources/youtube_music_data_source.dart`

- [ ] **Step 1: Update `_parseMytmItem` to support `musicTwoRowItemRenderer`**

This renderer is common in personalized shelves.

```dart
// lib/data/sources/youtube_music_data_source.dart

  Map<String, dynamic>? _parseMytmItem(dynamic item) {
    final renderer = item['musicTwoColumnItemRenderer'] ?? 
                     item['musicResponsiveListItemRenderer'] ??
                     item['musicNavigationButtonRenderer'] ??
                     item['musicItemRenderer'] ??
                     item['musicMultiRowListItemRenderer'] ??
                     item['musicWideButtonRenderer'] ??
                     item['musicPlaylistRenderer'] ??
                     item['musicVideoRenderer'] ??
                     item['gridVideoRenderer'] ??
                     item['gridPlaylistRenderer'] ??
                     item['musicTwoRowItemRenderer'] ?? // Correct identification
                     item['playlistPanelVideoRenderer'];    
    if (renderer == null) return null;
```

- [ ] **Step 2: Improve artist/subtitle extraction**

Personalized shelves often have deeper `runs` in subtitles.

```dart
// lib/data/sources/youtube_music_data_source.dart

// ... inside _parseMytmItem ...
    String? subtitle;
    final subtitleRuns = renderer['subtitle']?['runs'] as List?;
    if (subtitleRuns != null) {
      subtitle = subtitleRuns.map((r) => r['text']).where((t) => t != ' • ').join('');
    } else {
      subtitle = renderer['subtitle']?['simpleText'] ?? 
                 renderer['description']?['runs']?[0]?['text'] ??
                 renderer['longBylineText']?['runs']?[0]?['text'] ??
                 renderer['shortBylineText']?['runs']?[0]?['text'];
    }
```

- [ ] **Step 3: Commit**

```bash
git add lib/data/sources/youtube_music_data_source.dart
git commit -m "feat(data): enhance item parsing for two-row renderers and subtitles"
```

---

### Task 3: Consolidate Home Feed Fetching

**Files:**
- Modify: `lib/data/sources/youtube_music_data_source.dart`

- [ ] **Step 1: Simplify `fetchHomeData` to rely on `FEmusic_home`**

Since `FEmusic_home` now returns the necessary shelves with the updated context, we can reduce network overhead.

```dart
// lib/data/sources/youtube_music_data_source.dart

  @override
  Future<HomeDataModel> fetchHomeData({int limit = 25}) async {
    try {
      AppLogger.i(_tag, 'fetchHomeData standalone');
      final visitorData = LocalStorage.instance.getCachedMetadata('yt_visitor_data') as String?;

      final response = await _dio.post(
        '$_ytmBase/browse?prettyPrint=false',
        data: {
          "browseId": "FEmusic_home",
          "context": {
            ..._context,
            if (visitorData != null) "visitorData": visitorData,
          }
        },
      );

      if (response.statusCode != 200) return const HomeDataModel(rawShelves: []);
      
      final data = response.data as Map<String, dynamic>;
      
      // visitorData update
      final newVisitorData = data['responseContext']?['visitorData'];
      if (newVisitorData != null) {
        LocalStorage.instance.saveCachedMetadata('yt_visitor_data', newVisitorData);
      }

      final model = _parseHomeDataInternal(data);
      return model;
    } catch (e, st) {
      AppLogger.e(_tag, 'fetchHomeData failed', e, st);
      return const HomeDataModel(rawShelves: []);
    }
  }
```

- [ ] **Step 2: Commit**

```bash
git add lib/data/sources/youtube_music_data_source.dart
git commit -m "refactor(data): simplify home feed fetching to single robust call"
```

---

### Task 4: UI Verification and Final Polish

**Files:**
- Modify: `lib/presentation/screens/home/home_screen.dart`

- [ ] **Step 1: Verify `quickPicks` handling in `HomeScreen`**

Ensure the section is correctly identified and rendered.

- [ ] **Step 2: Run final automated test**

Run: `dart test test/ytm_debug_test.dart`
Expected: All tests pass, output shows multiple shelves including "Quick picks".

- [ ] **Step 3: Final Commit**

```bash
git commit -am "chore: final polish for quick picks integration"
```

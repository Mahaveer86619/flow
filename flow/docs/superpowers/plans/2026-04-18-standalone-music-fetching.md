# Standalone YouTube Music Data Fetching Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the app into a fully standalone music player by fixing the YouTube Music Home feed parsing and implementing direct, robust stream resolution without a backend server.

**Architecture:** Rewrite the `YoutubeMusicDataSource` to correctly parse the InnerTube `FEmusic_home` layout and upgrade `StreamResolver` to fetch high-quality audio streams directly from the `youtubei/v1/player` endpoint using official client contexts.

**Tech Stack:** Flutter, Dart, Dio, youtube_explode_dart (as fallback).

---

### Task 1: Fix Home Feed Parser in YoutubeMusicDataSource

**Files:**
- Modify: `flow/lib/data/sources/youtube_music_data_source.dart`
- Test: `flow/test/standalone_youtube_test.dart`

- [ ] **Step 1: Update `_parseMytmItem` to support `musicTwoRowItemRenderer`**
Fix the typo/missing renderer name and improve extraction logic for grid items.

```dart
// flow/lib/data/sources/youtube_music_data_source.dart

  Map<String, dynamic>? _parseMytmItem(dynamic item) {
    try {
      final renderer = item['musicResponsiveListItemRenderer'] ??
                       item['musicTwoRowItemRenderer'] ?? // Corrected from musicTwoColumnItemRenderer
                       item['playlistPanelVideoRenderer'] ??
                       item['musicNavigationButtonRenderer'] ??
                       item['musicTwoColumnItemRenderer']; // Keep as fallback

      if (renderer == null) return null;

      String? title;
      if (renderer['flexColumns'] != null) {
        title = renderer['flexColumns']?[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['text'];
      } else if (renderer['title'] != null) {
        title = renderer['title']?['runs']?[0]?['text'] ?? renderer['title']?['simpleText'];
      }

      // ... rest of extraction logic
```

- [ ] **Step 2: Improve `videoId` and `browseId` extraction**
Ensure we catch `videoId` from `navigationEndpoint` or `thumbnailOverlay`.

- [ ] **Step 3: Test Home Feed Fetching**
Run `standalone_youtube_test.dart` or a manual check to ensure `fetchHomeData` returns populated shelves.

### Task 2: Implement Direct Stream Resolution in StreamResolver

**Files:**
- Modify: `flow/lib/data/sources/stream_resolver.dart`

- [ ] **Step 1: Rewrite `resolveYoutubeStream` to hit `youtubei/v1/player`**
Implement the POST request with `ANDROID_MUSIC` context to get direct audio URLs.

```dart
// flow/lib/data/sources/stream_resolver.dart

  Future<String?> resolveYoutubeStream(String videoId) async {
    try {
      final dio = Dio(); // Use shared instance if available
      final response = await dio.post(
        'https://music.youtube.com/youtubei/v1/player?key=...', // Needs API Key if standard WEB, or use simplified ANDROID payload
        data: {
          "videoId": videoId,
          "context": {
            "client": {
              "clientName": "ANDROID_MUSIC",
              "clientVersion": "6.01.51"
            }
          }
        }
      );
      // ... parse streamingData.adaptiveFormats
    } catch (e) {
      // Fallback to youtube_explode_dart
    }
  }
```

- [ ] **Step 2: Parse and Sort Adaptive Formats**
Filter for `audio/` mime types and sort by bitrate to pick the best stream.

- [ ] **Step 3: Commit Changes**
```bash
git add flow/lib/data/sources/youtube_music_data_source.dart flow/lib/data/sources/stream_resolver.dart
git commit -m "feat: implement standalone youtube data fetching and direct stream resolution"
```

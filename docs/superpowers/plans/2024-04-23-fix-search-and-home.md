# Fix Search and Home Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix failing search, add view count sorting/fuzzy results, and restore missing shelves on the home screen.

**Architecture:** 
1. Enhance `_parseMytmItem` to extract view counts into the `extras` field.
2. Improve `searchSongs` to sort by view count and handle results more robustly.
3. Update `fetchHomeData` to include all shelves from the primary feed while maintaining the user's specific sub-feed overrides.

**Tech Stack:** Dart, YouTube Music (InnerTube) API, Dio.

---

### Task 1: Enhance `SongModel` and `_parseMytmItem` with View Counts

**Files:**
- Modify: `flow/lib/data/sources/youtube_music_data_source.dart`

- [ ] **Step 1: Add `_parseViewCount` helper method**
  Add a helper to convert strings like "89K plays" into integers.

- [ ] **Step 2: Update `_parseMytmItem` to extract views**
  Extract the view count from `musicResponsiveListItemRenderer`'s flex columns and store it in the `extras` map.

### Task 2: Improve `searchSongs` with Sorting and Resiliency

**Files:**
- Modify: `flow/lib/data/sources/youtube_music_data_source.dart`

- [ ] **Step 3: Implement Sorting by Views**
  In `searchSongs`, sort the `tracks` list based on the extracted view count in `extras['views']`.

- [ ] **Step 4: Enhance Search Resiliency**
  Add logic to handle "Similar songs" by potentially falling back to a search without strict params if the initial search is too narrow.

### Task 3: Restore Home Screen Shelves

**Files:**
- Modify: `flow/lib/data/sources/youtube_music_data_source.dart`

- [ ] **Step 5: Relax Thumbnail Filtering**
  Slightly relax the aspect ratio check for `listeningAgain` and `quickPicks` to avoid dropping items that are almost square.

- [ ] **Step 6: Include All Primary Feed Shelves**
  Update the merging logic in `fetchHomeData` to include ALL shelves from `mainModel.rawShelves` that haven't already been added via sub-feeds.

---

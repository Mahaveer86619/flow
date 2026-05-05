# Home Screen Deduplication & Title Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deduplicate songs on the home screen and provide unique section titles/subtitles.

**Architecture:** Implement global song deduplication in `HomeCubit` and refresh section titles in `home_screen.dart`.

**Tech Stack:** Flutter, BLoC (Cubit).

---

### Task 1: Implement Deduplication Logic in HomeCubit

**Files:**
- Modify: `flow/lib/presentation/cubits/home/home_cubit.dart`

- [ ] **Step 1: Add `_deduplicateShelves` helper method**

```dart
  List<HomeShelf> _deduplicateShelves(List<HomeShelf> shelves) {
    final seenIds = <String>{};
    return shelves.map((shelf) {
      final uniqueItems = shelf.items.where((item) {
        if (item.type == HomeItemType.song && item.data is Song) {
          final song = item.data as Song;
          return seenIds.add(song.id);
        }
        return true;
      }).toList();
      return HomeShelf(
        title: shelf.title,
        section: shelf.section,
        items: uniqueItems,
      );
    }).toList();
  }
```

- [ ] **Step 2: Apply deduplication in `_load` and `_loadFromCache`**

In `_loadFromCache`:
```dart
        final data = model.toEntity();
        final deduplicatedShelves = _deduplicateShelves(data.shelves);
        // ... in emit:
        shelves: deduplicatedShelves,
```

In `_load`:
```dart
      final data = results[0] as HomeData;
      final deduplicatedShelves = _deduplicateShelves(data.shelves);
      // ... in emit:
      shelves: deduplicatedShelves,
```

- [ ] **Step 3: Commit Cubit changes**

```bash
git add flow/lib/presentation/cubits/home/home_cubit.dart
git commit -m "feat(home): implement global song deduplication across shelves"
```

---

### Task 2: Refresh Section Titles and Subtitles in HomeScreen

**Files:**
- Modify: `flow/lib/presentation/screens/home/home_screen.dart`

- [ ] **Step 1: Update `requestedSections` titles**

```dart
                  final requestedSections = [
                    ('Jump Back In', 'quickPicks', Icons.bolt_outlined),
                    ('Your Daily Rotation', 'listeningAgain', Icons.history_rounded),
                    ('Fresh Finds', 'newArrivals', Icons.new_releases_outlined),
                    (
                      'Watch & Listen',
                      'musicVideos',
                      Icons.play_circle_outline_rounded,
                    ),
                    ('Albums for You', 'albumsForYou', Icons.album_rounded),
                    ('Deep Dives', 'longListening', Icons.timer_outlined),
                    ('Podcasts', 'podcasts', Icons.podcasts_rounded),
                  ];
```

- [ ] **Step 2: Update subtitles in `_HomeShelfRenderer`**

Update `quickPicks`: `'lets start with a radio'` -> `'Your current favorites'`
Update `newArrivals`: `'personalized for you'` -> `'New music for you'`
Update `longListening`: `'long tracks & sets'` -> `'Extended tracks for your flow'`
Update `podcasts`: `'podcasts for you'` -> `'Stories and conversations'`
Update `albumsForYou`: `'albums for you'` -> `'Expand your collection'`

- [ ] **Step 3: Commit UI changes**

```bash
git add flow/lib/presentation/screens/home/home_screen.dart
git commit -m "style(home): update section titles and subtitles for uniqueness"
```

---

### Task 3: Verification

- [ ] **Step 1: Run tests**

Run: `dart test flow/test/home_feed_test.dart`
Expected: PASS

- [ ] **Step 2: Manual Verification (if possible)**
Confirm that no song IDs are repeated across different shelves on the home screen.

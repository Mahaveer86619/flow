# Home Screen Personalized Shelves Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prioritize "Listen again", "Quick picks", and "Music videos" at the top of the home screen, ensuring they are fetched from the personalized YouTube Music feed.

**Architecture:** Update `YoutubeMusicDataSource` to correctly tag personalized shelves and modify `HomeScreen` to reorder shelves based on the new priority. Implement fallback mechanisms for missing data.

**Tech Stack:** Flutter, Dart, BLoC (Cubit).

---

### Task 1: Update Home Feed Parser

**Files:**
- Modify: `flow/lib/data/sources/youtube_music_data_source.dart`

- [ ] **Step 1: Refine `sectionType` identification**
Improve the keyword matching in `_parseHomeData` to catch all variations of priority shelves.

```dart
// flow/lib/data/sources/youtube_music_data_source.dart

        if (title != null) {
          final t = title.toLowerCase();
          if (t.contains('listen again') || t.contains('recent') || t.contains('frequent')) {
            sectionType = 'listeningAgain';
          } else if (t.contains('quick picks')) {
            sectionType = 'quickPicks';
          } else if (t.contains('music video') || t.contains('videos for you')) {
            sectionType = 'musicVideos';
          }
          // ... rest of types
        }
```

- [ ] **Step 2: Commit**
```bash
git add flow/lib/data/sources/youtube_music_data_source.dart
git commit -m "feat: refine home feed section identification for priority shelves"
```

### Task 2: Prioritize Shelves in UI

**Files:**
- Modify: `flow/lib/presentation/screens/home/home_screen.dart`

- [ ] **Step 1: Reorder shelves in `_HomeScreenContent`**
Update the dynamic shelf ordering logic to place the three requested shelves at the top.

```dart
// flow/lib/presentation/screens/home/home_screen.dart (inside build method)

                ...() {
                  final List<HomeShelf> rawShelves = state.shelves;
                  final List<HomeShelf> displayShelves = [];

                  HomeShelf? listeningAgain;
                  HomeShelf? quickPicks;
                  HomeShelf? musicVideos;
                  final List<HomeShelf> otherShelves = [];

                  for (final shelf in rawShelves) {
                    if ((shelf.section == 'listeningAgain' || shelf.section == 'frequentListens') && listeningAgain == null) {
                      listeningAgain = shelf;
                    } else if (shelf.section == 'quickPicks' && quickPicks == null) {
                      quickPicks = shelf;
                    } else if (shelf.section == 'musicVideos' && musicVideos == null) {
                      musicVideos = shelf;
                    } else {
                      otherShelves.add(shelf);
                    }
                  }

                  if (listeningAgain != null) displayShelves.add(listeningAgain);
                  if (quickPicks != null) displayShelves.add(quickPicks);
                  if (musicVideos != null) displayShelves.add(musicVideos);
                  displayShelves.addAll(otherShelves);
                  // ...
```

- [ ] **Step 2: Commit**
```bash
git add flow/lib/presentation/screens/home/home_screen.dart
git commit -m "feat: reorder home shelves (Listen Again > Quick Picks > Music Videos)"
```

### Task 3: Verification

- [ ] **Step 1: Run static analysis**
Run: `dart analyze flow/lib/data/sources/youtube_music_data_source.dart flow/lib/presentation/screens/home/home_screen.dart`
Expected: No errors.

- [ ] **Step 2: Verify with manual check or existing tests**
Check if `YoutubeMusicDataSource` returns the correctly tagged sections when provided with mock data (or real data if environment allows).

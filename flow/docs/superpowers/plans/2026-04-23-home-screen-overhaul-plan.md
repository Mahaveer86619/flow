# Home Screen Comprehensive Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the home screen into a highly personalized Material 3 experience with dynamic shelves driven by user behavior and a modern "Material Flow" aesthetic.

**Architecture:** 
1.  **Data Layer:** Enhance `LocalStorage` to track artist Affinity and search history.
2.  **Logic Layer:** Overhaul `HomeCubit` to implement the strict shelf order and behavioral sorting.
3.  **UI Layer:** Rewrite `HomeScreen` using Material 3 containers, custom background patterns, and modernized headers.

**Tech Stack:** Flutter, Material 3, BLoC (Cubit), Hive.

---

### Task 1: Tracking Engine Implementation

**Files:**
- Modify: `flow/lib/core/storage/local_storage.dart`
- Modify: `flow/lib/domain/repositories/music_repository.dart`
- Modify: `flow/lib/data/repositories/youtube_music_repository.dart`

- [ ] **Step 1: Add artist affinity and search tracking to `LocalStorage`**
    - Implement `incrementArtistPlayCount(String artistName)`
    - Implement `recordArtistSearch(String artistName)`
    - Implement `getTopArtists(int limit)`
    - Implement `getRecentSearchArtists(int limit)`

- [ ] **Step 2: Update `MusicRepository` interface**
    - Add `recordSearch(String query)`
    - Add `getTopArtists()`

- [ ] **Step 3: Implement new methods in `YoutubeMusicRepository`**
    - Link them to the new `LocalStorage` methods.

- [ ] **Step 4: Commit Tracking Engine**
```bash
git add .
git commit -m "feat(tracking): implement artist affinity and search history tracking"
```

---

### Task 2: Data Source & Filtering Enhancements

**Files:**
- Modify: `flow/lib/data/sources/youtube_music_data_source.dart`

- [ ] **Step 1: Enhance `fetchHomeData` to fetch more "Listen Again" songs**
    - Update `FEmusic_listen_again` fetch to include a larger limit.
    - Implement strict song filtering (remove playlists/albums) for this section.

- [ ] **Step 2: Implement Music Video filtering**
    - Add logic to filter items where `thumbnailWidth / thumbnailHeight > 1.3` (16:9 ratio).

- [ ] **Step 3: Commit Data Source changes**
```bash
git add flow/lib/data/sources/youtube_music_data_source.dart
git commit -m "feat(data): enhance home data source with specific song and video filtering"
```

---

### Task 3: HomeCubit Logic Overhaul

**Files:**
- Modify: `flow/lib/presentation/cubits/home/home_cubit.dart`

- [ ] **Step 1: Implement the new `_load` logic**
    - Implement strict shelf order: Daily Rotation, Jump Back In, Music Videos, Albums, Deep Dives, Podcasts.
    - Implement "Jump Back In" sorting: Prioritize songs by recently searched artists and high local play counts.

- [ ] **Step 2: Implement "Albums for You" discovery logic**
    - Fetch similar artists (using YT Music API if possible, or fallback to top played artists' latest albums).

- [ ] **Step 3: Commit Logic Overhaul**
```bash
git add flow/lib/presentation/cubits/home/home_cubit.dart
git commit -m "feat(home): overhaul HomeCubit with behavioral shelf sorting and filtering"
```

---

### Task 4: UI & Aesthetic Overhaul

**Files:**
- Modify: `flow/lib/presentation/widgets/section_header.dart`
- Create: `flow/lib/presentation/widgets/background_pattern_painter.dart`
- Modify: `flow/lib/presentation/screens/home/home_screen.dart`
- Modify: `flow/lib/presentation/widgets/song_card.dart`

- [ ] **Step 1: Modernize `SectionHeader`**
    - Use `Space Grotesk`, tight letter spacing, and Material 3 tonal colors.
    - Remove "cartoonish" icons; use clean, thin-stroke Material symbols.

- [ ] **Step 2: Create `BackgroundPatternPainter`**
    - Implement a subtle geometric pattern that flows from the app bar downwards.

- [ ] **Step 3: Redesign `HomeScreen` App Bar**
    - Implement the blurred Material 3 `surfaceContainer` app bar with gradient tint.
    - Integrate the background pattern.

- [ ] **Step 4: Update `SongCard` interaction**
    - Add a `skipPlayerScreen` parameter to `SongCard`.
    - Ensure home screen cards only trigger the Mini Player.

- [ ] **Step 5: Commit UI Overhaul**
```bash
git add .
git commit -m "style(home): implement Material Flow aesthetic and modernized headers"
```

---

### Task 5: Verification

- [ ] **Step 1: Run full test suite**
- [ ] **Step 2: Manual Verification**
    - Verify shelf order.
    - Verify no duplicate songs.
    - Verify Mini Player-only playback on Home.
    - Verify visual pattern and Material 3 styling.

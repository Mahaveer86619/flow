# UI Overhaul & Functional Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure the Flow app UI to align with YT Music aesthetics, unify navigation/app bars, and fix storage/queue bugs.

**Architecture:** 
- **Functional:** Update `AndroidManifest.xml` and `PermissionService` for storage; modify `PlayerBloc` for proactive queue hydration.
- **UI:** Refactor `MainShell` for persistent navigation; update `HomeScreen`, `SearchScreen`, and `LibraryScreen` for unified app bars and YT-style sections.
- **Components:** Create `FlowAppBar` and `ShimmerShelf` for consistency.

**Tech Stack:** Flutter, Bloc, Hive, PermissionHandler

---

### Task 1: Core Functional Fixes (Storage & Queue)

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `lib/core/platform/permission_service.dart`
- Modify: `lib/presentation/blocs/player/player_bloc.dart`

- [ ] **Step 1: Update AndroidManifest for Storage**

Add permissions:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29" />
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
```

- [ ] **Step 2: Update PermissionService**

Add logic to request `manageExternalStorage` on Android 11+.

- [ ] **Step 3: Update PlayerBloc for Proactive Queueing**

In `_onPlaySingle`, if the queue becomes size 1, automatically trigger `PlayRadioEvent` to hydrate "Up Next".

- [ ] **Step 4: Verify Fixes**
- Run a test to ensure `PlaySingleEvent` triggers radio tracks.
- Confirm Android manifest is correct.

- [ ] **Step 5: Commit**
```bash
git add .
git commit -m "fix: storage permissions and proactive queue loading"
```

---

### Task 2: Navigation & Shell Refactor

**Files:**
- Modify: `lib/presentation/widgets/main_shell.dart`
- Modify: `lib/presentation/widgets/mini_player.dart`

- [ ] **Step 1: Implement Mini Player Hiding**

Update `MiniPlayer` to check `PlayerState.currentSong` and hide if the full player is detected as "open" (via a new property in `PlayerBloc` or `AppEventBus`).

- [ ] **Step 2: Persistent Bottom Nav in MainShell**

Ensure `MainShell` stays visible when navigating to nested settings/notifications by providing them as routes within the existing tab navigators or using a separate shell logic.

- [ ] **Step 3: Verify Navigation**
- Open Player and confirm MiniPlayer is gone.
- Open Settings and confirm BottomNav remains.

- [ ] **Step 4: Commit**
```bash
git add .
git commit -m "ui: refactor shell for persistent navigation and miniplayer hiding"
```

---

### Task 3: Unified App Bar & Search Spacing

**Files:**
- Create: `lib/presentation/widgets/flow_app_bar.dart`
- Modify: `lib/presentation/screens/home/home_screen.dart`
- Modify: `lib/presentation/screens/search/search_screen.dart`
- Modify: `lib/presentation/screens/library/library_screen.dart`

- [ ] **Step 1: Create FlowAppBar Widget**

Implement a reusable `SliverAppBar` component with `notifications`, `history`, and `settings` actions.

- [ ] **Step 2: Update Search Screen Spacing**

Reduce `expandedHeight` of `SliverAppBar` and adjust `FlexibleSpaceBar` padding for a tighter YT-Music feel.

- [ ] **Step 3: Apply Unified App Bar**

Replace existing headers in Home, Search, and Library with `FlowAppBar`.

- [ ] **Step 4: Verify Spacing & Icons**
- Check spacing on Search screen.
- Confirm all 3 tabs have the new app bar actions.

- [ ] **Step 5: Commit**
```bash
git add .
git commit -m "ui: implement unified app bars and fix search screen spacing"
```

---

### Task 4: Home Screen YT-Music Restructuring

**Files:**
- Modify: `lib/presentation/screens/home/home_screen.dart`
- Create: `lib/presentation/widgets/shimmer_shelf.dart`

- [ ] **Step 1: Create ShimmerShelf Widget**

Implement a skeleton loader for horizontal and grid sections.

- [ ] **Step 2: Implement Fixed Top Sections**

Add the "Mood Chips" as a fixed section at the top of `HomeScreen`.

- [ ] **Step 3: Intelligence Shelf Priority**

Update `HomeScreen` to always place the `quick_picks` section (Intelligence) as the first dynamic shelf.

- [ ] **Step 4: Unified Shimmer Loading**

Update `HomeScreen` loading state to use `ShimmerShelf` for all sections.

- [ ] **Step 5: Verify Home Layout**
- Confirm Mood chips are fixed.
- Confirm Intelligence shelf is first.
- Confirm Shimmer loads during refresh.

- [ ] **Step 6: Commit**
```bash
git add .
git commit -m "ui: restructure home screen with YT-style sections and shimmers"
```

---

### Task 5: Player & Queue Polish

**Files:**
- Modify: `lib/presentation/screens/player/player_screen.dart`
- Modify: `lib/presentation/screens/queue/queue_screen.dart`

- [ ] **Step 1: Reclaim Player Space**

Remove unused `SizedBox` at the top of `PlayerScreen` and adjust `SafeArea`.

- [ ] **Step 2: Minimal Queue Redesign**

Update `QueueScreen` to use a card for "Now Playing" and improve spacing for list items.

- [ ] **Step 3: Final Verification**
- Full app walkthrough to ensure all UI requirements are met.
- Verify "Next songs" are loading correctly in the new Queue.

- [ ] **Step 4: Commit**
```bash
git add .
git commit -m "ui: polish player and queue screens"
```

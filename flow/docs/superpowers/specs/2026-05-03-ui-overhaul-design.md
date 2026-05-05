# UI/UX Overhaul & Functional Fixes Design Spec

**Date:** 2026-05-03
**Status:** Approved
**Topic:** Comprehensive Presentation Layer Restructuring & Playback Resiliency

---

## 1. Overview
This project aims to restructure the "Flow" music app's presentation layer to align with modern music app standards (specifically YT Music style), fix navigation inconsistencies, and resolve critical functional bugs related to storage and queue management.

## 2. UI/UX Requirements

### 2.1 Home Screen Restructuring
- **Fixed Sections:** Implement a fixed top area containing a greeting and mood chips (Chill, Focus, etc.).
- **Intelligence Shelf:** The "Quick Picks" / AI-powered recommendations section will be the first dynamic shelf.
- **Loading State:** Replace generic loaders with a unified **Shimmer Effect** for all shelves (Intelligence, Listen Again, etc.).
- **Consistency:** Align card sizes and spacing with the YT Music aesthetic.

### 2.2 Unified App Bar & Navigation
- **App Bar Actions:** Add Notifications (`notifications_none_rounded`), Recently Played (`history_rounded`), and Settings (`settings_outlined`) icons to the `SliverAppBar` of Home, Search, and Library screens.
- **Persistent Bottom Nav:** The `BottomNavigationBar` (in `MainShell`) must remain visible on all screens except the Full Player and the Queue.
- **Mini Player Fix:** The Mini Player must automatically hide when the `PlayerScreen` is open.

### 2.3 Screen-Specific Improvements
- **Search Screen:**
    - Reduce excessive top padding in `SliverAppBar`.
    - Decrease vertical gap between "Search" title and `SearchBar`.
- **Player Screen:**
    - Remove large unused `SizedBox` (32px) at the top.
    - Adjust `SafeArea` and `LayoutBuilder` to utilize the top space, making the album art more prominent.
- **Queue Screen:**
    - Redesign for minimalism.
    - Use card-based highlighting for the "Now Playing" item.
    - Improve spacing and typography for "Up Next" list items.

## 3. Functional Requirements

### 3.1 Storage Permissions (PathAccessException Fix)
- **Manifest Updates:** Add `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, and `MANAGE_EXTERNAL_STORAGE` (for API 30+) to `AndroidManifest.xml`.
- **Permission Handling:** Update `PermissionService` to request these permissions on first launch or when a download is initiated.

### 3.2 Queue Resiliency
- **Proactive Loading:** When a song is started from Search (or any single-song source), automatically trigger a "Play Radio" or "Fetch Related" event if the queue is empty.
- **Queue State:** Ensure `PlayerBloc` correctly hydrates the queue when `PlaySingleEvent` is dispatched.

## 4. Technical Approach

### 4.1 Navigation Refactor
- Modify `MainShell.dart` to use a global state or `PlayerState` listener to toggle bottom bar visibility.
- Ensure nested `Navigator` calls don't hide the shell's bottom bar unless explicitly routed to `PlayerScreen`.

### 4.2 UI Components
- **Shimmer:** Create/Update a reusable `ShimmerShelf` widget.
- **App Bar:** Centralize `Action` icon logic into a reusable `FlowAppBar` or similar mixin/widget to ensure consistency.

## 5. Verification Plan
- **UI Audit:** Verify spacing on Search/Player screens against mockups.
- **Permission Test:** Confirm downloads work on Android 11+ without `PathAccessException`.
- **Queue Test:** Start a song from Search and verify the "Up Next" queue is automatically populated with related tracks.

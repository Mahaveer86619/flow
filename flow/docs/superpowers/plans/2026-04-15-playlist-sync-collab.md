# Playlist Syncing & Custom Flow Playlists Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix album rendering, implement unified playlist fetching (YT + Flow), and enable collaborative "Flow" playlists with unique user codes.

**Architecture:** 
- **Backend:** Merged `/library` endpoint, `user_code` generation (`username#1234`), and Flow-level playlist CRUD.
- **Frontend:** Enriched `Playlist` entity with type/album flags, optimized `PlaylistScreen` for albums, and `AppEventBus` for real-time local syncing.

**Tech Stack:** Python (FastAPI, SQLAlchemy), Flutter (Bloc/Cubit, Hive).

---

### Task 1: Backend User Code & Playlist Models

**Files:**
- Modify: `flow-source/app/models.py`
- Modify: `flow-source/app/routes.py`
- Modify: `flow-source/app/services.py`

- [x] **Step 1: Update Pydantic models for User and Playlist**
    - Add `user_code` to `UserResponse`.
    - Add `type`, `isAlbum`, `ownerCode` to `PlaylistResponse`.

- [x] **Step 2: Implement `user_code` generation in `AuthService`**
    - Add `generate_user_code(username, db)` to `flow-source/app/services.py`.
    - Ensure uniqueness by appending 4 random digits and checking the DB.

- [x] **Step 3: Update `signup` route to generate and store `user_code`**
    - Modify `flow-source/app/routes.py` to call `generate_user_code` during user creation.

- [ ] **Step 4: Commit**
    ```bash
    git add flow-source/app/models.py flow-source/app/routes.py flow-source/app/services.py
    git commit -m "feat(backend): add user_code generation and enriched playlist response models"
    ```

---

### Task 2: Unified Library & Album Normalization

**Files:**
- Modify: `flow-source/app/utils.py`
- Modify: `flow-source/app/services.py`
- Modify: `flow-source/app/routes.py`

- [x] **Step 1: Update `normalize_playlist` to include `type` and `is_album`**
    - In `utils.py`, add `type` parameter (default "yt") and `is_album` detection.

- [ ] **Step 2: Update `normalize_song` to better inherit album thumbnails**
    - Ensure `album` field is always populated where possible.

- [x] **Step 3: Update `/v1/library` to merge YT playlists with user's Flow playlists**
    - Modify `get_library` in `routes.py` to fetch both `ytm.get_library_playlists()` and `db.query(Playlist).filter(owner_id == user.id)`.
    - Return a combined list.

- [ ] **Step 4: Commit**
    ```bash
    git add flow-source/app/utils.py flow-source/app/services.py flow-source/app/routes.py
    git commit -m "feat(backend): unified library endpoint merging YT and Flow playlists"
    ```

---

### Task 3: Frontend Entity & Model Enrichment

**Files:**
- Modify: `flow/lib/domain/entities/song.dart`
- Modify: `flow/lib/data/models/playlist_model.dart`
- Modify: `flow/lib/data/models/home_data_model.dart`

- [x] **Step 1: Add `type`, `isAlbum`, `artistName`, and `ownerCode` to `Playlist` entity**
    - Update `Song` file in domain/entities.

- [x] **Step 2: Update `PlaylistModel` to handle new fields from JSON**
    - Update `fromJson` and `toEntity` mapping.

- [x] **Step 3: Update `HomeDataModel` to correctly distinguish `album` vs `playlist` items**
    - Fix the switch case in `toEntity()` to map `HomeItemType.album` correctly.

- [ ] **Step 4: Commit**
    ```bash
    git add flow/lib/domain/entities/song.dart flow/lib/data/models/playlist_model.dart flow/lib/data/models/home_data_model.dart
    git commit -m "feat(frontend): enriched Playlist entity and model with type and album support"
    ```

---

### Task 4: Optimized Album Rendering in PlaylistScreen

**Files:**
- Modify: `flow/lib/presentation/screens/playlist/playlist_screen.dart`

- [x] **Step 1: Update `PlaylistScreen` header**
    - Show "Album • Artist Name" instead of just "Playlist" when `playlist.isAlbum` is true.

- [x] **Step 2: Optimize track loading**
    - Ensure thumbnails are inherited from the playlist/album if the track-specific thumbnail is missing (handled in backend Task 2, but verify frontend fallback).

- [ ] **Step 3: Commit**
    ```bash
    git add flow/lib/presentation/screens/playlist/playlist_screen.dart
    git commit -m "ui: optimized PlaylistScreen for album rendering"
    ```

---

### Task 5: Custom Flow Playlists & Collaboration

**Files:**
- Modify: `flow-source/app/routes.py`
- Modify: `flow/lib/data/sources/api_song_data_source.dart`
- Modify: `flow/lib/domain/repositories/song_repository.dart`
- Modify: `flow/lib/data/repositories/song_repository_impl.dart`

- [x] **Step 1: Implement Flow playlist CRUD**
    - Add endpoints to `routes.py` for creating Flow playlists (persisting to `playlists` table).
    - Add endpoints for adding/removing collaborators using `user_code`.

- [x] **Step 2: Update Frontend API source**
    - Update `ApiSongDataSource` to point to new Flow-specific endpoints where needed.

- [x] **Step 3: Update Repository and Cubits**
    - Ensure `LibraryCubit` handles the merged results correctly.

- [ ] **Step 4: Commit**
    ```bash
    git add .
    git commit -m "feat: complete custom flow playlists and collaboration system"
    ```

---

### Task 6: Final Verification

- [ ] **Step 1: Verify `user_code` appears in Profile**
- [ ] **Step 2: Verify albums show artist names and correct icons**
- [ ] **Step 3: Test collaborative playlist updates between two users**

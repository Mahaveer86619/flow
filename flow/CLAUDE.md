# Flow — AI Development Context

## What this project is

**Flow** is a Flutter music streaming app UI template. The UI is complete and fully functional as a demo. All audio playback, song data, and user data are currently **mocked** — no real API or audio engine is connected. The owner will add real business logic (streaming, authentication, API integration) on top of this UI shell.

## Tech stack

| Concern | Solution |
|---------|----------|
| Framework | Flutter (SDK ^3.11.4), Material Design 3 |
| State management | `flutter_bloc` 8.1.6 — Cubit pattern only (no full Bloc/event streams) |
| Typography | `google_fonts` — Outfit (body) + Space Grotesk (headings) |
| Responsive | Custom `Breakpoints` + `ResponsiveLayout` in `lib/core/responsive/` |
| DI | `RepositoryProvider` from flutter_bloc |

## Repository layout

```
lib/
  core/responsive/     # Breakpoints + ResponsiveLayout widget
  cubits/              # All state management (PlayerCubit, HomeCubit, SearchCubit, LibraryCubit)
  data/                # Mock data constants (mock_data.dart)
  models/              # Song, Playlist value objects
  repositories/        # SongRepository abstract class + MockSongRepository
  screens/             # One file per screen + desktop_shell + main_screen
  viewmodels/          # LEGACY — unused ChangeNotifier viewmodels, ignore these
  widgets/             # Reusable UI components
  main.dart            # App entry, DI wiring, theme
```

## Architecture rules

1. **Repository pattern** — all data access goes through `SongRepository`. Never read from `mock_data.dart` directly in UI or cubits.
2. **Cubit-only state** — no `StatefulWidget` for business state. UI state (focus, animation) can use `StatefulWidget`.
3. **Screens are dumb** — screens watch cubits and pass data down. Logic lives in cubits.
4. **Responsive nav** — on desktop (≥ 1100 px) never push `PlayerScreen` as a route. The `PlayerPanel` sidebar updates automatically.
5. **Ignore viewmodels/** — `lib/viewmodels/` is legacy scaffolding, not wired to anything. Do not add code there.

## Key extension points

### Connecting real audio
Edit `lib/cubits/player_cubit.dart`:
- Replace `_progressTimer` with calls to your audio plugin (e.g. `just_audio`)
- `_playSong(Song song)` is the single entry point for starting playback
- `state.progress` (0.0–1.0) drives all progress UI — emit updates from your player stream

### Connecting a real API
1. Add fields to `Song` model (e.g. `streamUrl`, `artworkUrl`, `durationMs`)
2. Create `lib/repositories/api_song_repository.dart` implementing `SongRepository`
3. In `main.dart`, swap `MockSongRepository()` → `ApiSongRepository()`
4. Nothing else changes

### Replacing artwork placeholders
- `AlbumArtWidget` (`lib/widgets/album_art_widget.dart`) — replace the gradient Stack with `Image.network(song.artworkUrl)`
- `SongCard` (`lib/widgets/song_card.dart`) — same, replace gradient Container
- `ArtistCard` (`lib/widgets/artist_card.dart`) — replace initials Text with circular Image

### Adding authentication
- Add an `AuthCubit` / `AuthRepository`
- Wrap `MultiBlocProvider` in `main.dart` with auth state checks
- Gate `SplashScreen` navigation on auth state

### Persisting data
- Search history: in `SearchCubit.addRecentSearch`, write to `SharedPreferences`
- Liked songs: in `PlayerCubit.toggleLike`, persist the liked IDs list
- Queue/session: serialize `PlayerState` to local storage on app pause

## Responsive system

| Width | Shell | Player |
|-------|-------|--------|
| < 700 px | `MainScreen` (bottom nav + `MiniPlayer`) | `PlayerScreen` pushed as route |
| 700–1099 px | Same as mobile | Same as mobile |
| ≥ 1100 px | `DesktopShell` (NavigationRail + content + sidebar) | `PlayerPanel` always visible in sidebar |

Entry point after splash: `_RootShell` (in `splash_screen.dart`) → `ResponsiveLayout`.

Change breakpoints in one place: `lib/core/responsive/breakpoints.dart`.

## Theme

Seed color: `Color(0xFF7C3AED)` (purple). Dark mode default.
All theme decisions are in `FlowApp._buildTheme()` in `main.dart`.

## What NOT to do

- Do not add business logic to screens — screens are display-only
- Do not read `mock_data.dart` directly from cubits or screens
- Do not push `PlayerScreen` on desktop — check `Breakpoints.isDesktop()` first
- Do not create new state management solutions — use the existing Cubit pattern
- Do not modify `lib/viewmodels/` — it is unused legacy code
- Do not add `const` to `HomeState` constructor call in `_build` — it builds dynamic data

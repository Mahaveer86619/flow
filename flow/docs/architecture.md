# Architecture Overview

## High-level structure

Flow is a Flutter music streaming UI template built on three layered concerns:

```
┌─────────────────────────────────────────────────┐
│                  UI Layer                        │
│  Screens + Widgets (display only, no logic)      │
└────────────────────┬────────────────────────────┘
                     │ watches / reads
┌────────────────────▼────────────────────────────┐
│               State Layer (Cubits)               │
│  PlayerCubit · HomeCubit · SearchCubit           │
│  LibraryCubit                                    │
└────────────────────┬────────────────────────────┘
                     │ calls
┌────────────────────▼────────────────────────────┐
│              Data Layer (Repositories)           │
│  SongRepository (abstract)                       │
│  MockSongRepository (current implementation)     │
└─────────────────────────────────────────────────┘
```

## App startup sequence

```
main()
  └── RepositoryProvider<SongRepository>(MockSongRepository)
        └── MultiBlocProvider
              ├── PlayerCubit()
              ├── HomeCubit(repo)
              ├── SearchCubit(repo)
              └── LibraryCubit(repo)
                    └── FlowApp (MaterialApp)
                          └── SplashScreen
                                └── _RootShell (after animation)
                                      └── ResponsiveLayout
                                            ├── mobile → MainScreen
                                            └── desktop → DesktopShell
```

## Mobile shell layout

```
Scaffold
  ├── AppBar (flow title + notification/history/settings icons)
  ├── Body
  │     ├── IndexedStack
  │     │     ├── [0] HomeScreen
  │     │     ├── [1] SearchScreen
  │     │     └── [2] LibraryScreen
  │     └── MiniPlayer (visible when a song is loaded; hidden otherwise)
  └── BottomNavigationBar (Home / Search / Library)
```

When a song tile is tapped, `PlayerScreen` is pushed as a full-screen route over the shell.

## Desktop shell layout

```
Scaffold
  └── Row
        ├── NavigationRail (72 px, with logo + settings at bottom)
        ├── VerticalDivider
        ├── Expanded Column
        │     ├── _DesktopTopBar (56 px, app title + recently played)
        │     └── IndexedStack (Home / Search / Library)
        ├── VerticalDivider
        └── _PlayerSidebar (340 px, always visible)
              └── PlayerPanel
```

On desktop, `PlayerScreen` is **never** pushed as a route. Tapping any song just calls `PlayerCubit.playQueue()` — the sidebar updates automatically.

## State management pattern

All mutable state lives in Cubits. The pattern for every screen:

```dart
// In the widget's build():
final state = context.watch<SomeCubit>().state;  // subscribe to state
final cubit = context.read<SomeCubit>();          // get cubit for commands

// Trigger state changes:
cubit.someAction();
```

Cubits are provided at the root (`main.dart`) and accessible everywhere below `MultiBlocProvider`.

## Dependency injection

`RepositoryProvider` provides `SongRepository` to the widget tree. Cubits read it during construction:

```dart
BlocProvider(create: (ctx) => HomeCubit(ctx.read<SongRepository>()))
```

To swap the data source, change one line in `main.dart`:
```dart
create: (_) => MockSongRepository()
// →
create: (_) => ApiSongRepository(baseUrl: 'https://api.example.com')
```

## Navigation

| Trigger | Action | Mobile | Desktop |
|---------|--------|--------|---------|
| Tap song card | `PlayerCubit.playQueue()` + push route | `PlayerScreen` pushed | sidebar updates only |
| Tap MiniPlayer | push route | `PlayerScreen` pushed | n/a (no MiniPlayer on desktop) |
| Tap nav item | `setState` in shell | `_index` changes | `_index` changes |
| Tap back in player | `Navigator.pop()` | returns to shell | n/a |

## File naming conventions

- `*_cubit.dart` — contains both `XxxState` and `XxxCubit` classes in one file
- `*_screen.dart` — full-page views, route targets
- `*_widget.dart` or descriptive name — reusable components with no screen-level concerns
- `*_repository.dart` — data access implementations

## What is intentionally not implemented (yet)

| Feature | Where to add |
|---------|-------------|
| Real audio playback | `PlayerCubit._playSong()` |
| API data fetching | New `ApiSongRepository` |
| Authentication | New `AuthCubit` + `AuthRepository` |
| Offline / caching | `SongRepository` implementation |
| Persistent liked songs | `PlayerCubit.toggleLike()` → SharedPreferences |
| Persistent search history | `SearchCubit.addRecentSearch()` → SharedPreferences |
| Real artwork images | `AlbumArtWidget`, `SongCard`, `ArtistCard` |
| Playlist management | `LibraryCubit` + new screen actions |

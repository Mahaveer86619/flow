# State Management

Flow uses the **Cubit** variant of the BLoC pattern (`flutter_bloc` 8.1.6).
Cubits are simpler than full Blocs — they emit state directly via `emit()` rather than processing events.

## Cubit overview

| Cubit | File | Scope | Injected with |
|-------|------|-------|---------------|
| `PlayerCubit` | `cubits/player_cubit.dart` | Global (shared across all screens) | nothing — standalone |
| `HomeCubit` | `cubits/home_cubit.dart` | Global | `SongRepository` |
| `SearchCubit` | `cubits/search_cubit.dart` | Global | `SongRepository` |
| `LibraryCubit` | `cubits/library_cubit.dart` | Global | `SongRepository` |

All cubits are provided at the root in `main.dart` under `MultiBlocProvider`, so every widget in the tree can access them.

---

## PlayerCubit

**File:** `lib/cubits/player_cubit.dart`

The most important cubit. Manages everything about playback.

### State: `PlayerState`

```dart
class PlayerState {
  final Song?         currentSong;      // null = nothing loaded
  final bool          isPlaying;
  final double        progress;         // 0.0 – 1.0
  final bool          isShuffle;
  final bool          isRepeat;
  final double        volume;           // 0.0 – 1.0
  final List<String>  likedSongIds;     // song.id values
  final List<Song>    recentlyPlayed;   // newest first, max 20
}
```

Derived getters (computed, not stored):
- `isLiked(Song song)` — checks `likedSongIds`
- `likedSongsCount` — integer count
- `currentTimeString` — `"3:24"` formatted
- `totalTimeString` — `"4:15"` formatted

### Commands

```dart
cubit.playQueue(List<Song> songs, {int startIndex = 0})
// Sets internal queue, starts playing from startIndex.
// This is the primary way to start playback from any song list.

cubit.play(Song song)
// Convenience: single-song queue.

cubit.togglePlayPause()
cubit.seekTo(double fraction)   // 0.0–1.0
cubit.next()
cubit.previous()                // restarts if progress > 5%, else goes back
cubit.toggleShuffle()
cubit.toggleRepeat()
cubit.toggleLike(Song song)
cubit.setVolume(double value)   // 0.0–1.0
```

### Internal queue

The queue (`_queue`, `_queueIndex`) is **not** exposed in state — it's an implementation detail. This means UI widgets cannot read queue position directly; they can only read `currentSong`.

When you connect a real audio plugin:
- Keep the queue management logic as-is
- Replace `_startTimer()` with calls to your audio plugin
- Stream progress updates from the plugin into `emit(state.copyWith(progress: ...))`

### Progress simulation

Currently a `Timer.periodic` fires every 500ms and increments `progress` based on `song.duration`. Replace with a real stream listener when integrating audio.

---

## HomeCubit

**File:** `lib/cubits/home_cubit.dart`

Provides content for `HomeScreen`. Currently built synchronously from the repository.

### State: `HomeState`

```dart
class HomeState {
  final String                     greeting;           // "Good morning" etc.
  final List<Song>                 allSongs;           // full catalogue
  final List<Song>                 quickAccess;        // first 6 songs
  final List<Song>                 listeningAgain;     // first 6 songs
  final List<Song>                 forgottenFavorites; // last 6 songs (reversed)
  final List<Song>                 musicForYou;        // all songs
  final List<Map<String, dynamic>> trendingArtists;    // distinct artists
}
```

The `trendingArtists` list contains maps with keys: `name`, `colorPrimary`, `colorSecondary`.

### Adding async loading

When `SongRepository.getSongs()` becomes async (e.g. network call), add a loading variant:

```dart
// Option: sealed class states
abstract class HomeState {}
class HomeLoading extends HomeState {}
class HomeLoaded extends HomeState { final HomeData data; ... }
class HomeError extends HomeState { final String message; ... }
```

Then `HomeScreen` switches on state type instead of using data directly.

---

## SearchCubit

**File:** `lib/cubits/search_cubit.dart`

Handles search input, results, and search history.

### State: `SearchState`

```dart
class SearchState {
  final String                     query;
  final List<Song>                 results;
  final List<Map<String, dynamic>> categories;   // static, never changes
  final List<String>               recentSearches; // newest first, max 8
}

bool get hasQuery => query.isNotEmpty;
```

### Commands

```dart
cubit.updateQuery(String query)     // filters songs client-side
cubit.clearQuery()
cubit.addRecentSearch(String query) // called on keyboard submit
cubit.removeRecentSearch(String query)
cubit.clearRecentSearches()
```

### Making search async / server-side

Replace the client-side filter in `updateQuery()`:
```dart
void updateQuery(String query) async {
  emit(state.copyWith(query: query, results: [])); // show loading
  final results = await _repository.searchSongs(query); // new async method
  emit(state.copyWith(results: results));
}
```

Add `searchSongs(String query)` to `SongRepository`.

### Persisting search history

In `addRecentSearch`:
```dart
final prefs = await SharedPreferences.getInstance();
await prefs.setStringList('recent_searches', updated);
```

Load in the cubit constructor or `initState`.

---

## LibraryCubit

**File:** `lib/cubits/library_cubit.dart`

Manages the Library screen's filter chips and playlist list.

### State: `LibraryState`

```dart
class LibraryState {
  final int             filterIndex;  // which chip is selected (0–3)
  final List<Playlist>  playlists;    // from repository
}

static const filterOptions = ['Playlists', 'Albums', 'Artists', 'Downloads'];
```

### Commands

```dart
cubit.setFilter(int index)  // changes active chip
```

The `LibraryScreen` also reads `PlayerCubit.state.likedSongsCount` directly to show the liked songs count badge — this is intentional cross-cubit reading.

---

## How screens consume state

```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // context.watch rebuilds this widget when HomeCubit emits
    final state = context.watch<HomeCubit>().state;

    // context.read does NOT subscribe — use for event handlers
    final cubit = context.read<PlayerCubit>();

    return SomeWidget(
      data: state.listeningAgain,
      onTap: () => cubit.playQueue(state.allSongs),
    );
  }
}
```

**Rule:** `context.watch` in `build`, `context.read` in callbacks.

---

## Cross-cubit communication

Currently there is no direct cubit-to-cubit communication. Where cross-state reading is needed (e.g. `LibraryScreen` showing liked count), the screen simply watches both cubits independently:

```dart
final libraryState = context.watch<LibraryCubit>().state;
final likedCount   = context.watch<PlayerCubit>().state.likedSongsCount;
```

This is intentional and correct for this scale.

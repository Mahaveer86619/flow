# Data Layer

## Models

**File:** `lib/models/song.dart`

### Song

```dart
class Song {
  final String   id;
  final String   title;
  final String   artist;
  final String   album;
  final Duration duration;
  final Color    colorPrimary;    // used for gradients and UI accents
  final Color    colorSecondary;  // gradient end color
}
```

`Song` is immutable (`const`). `colorPrimary` and `colorSecondary` serve as a UI theming mechanism — each song carries its own accent colors, which drive gradients in `AlbumArtWidget`, `SongCard`, `PlayerScreen`, etc.

**Fields to add when connecting a real API:**
```dart
// Add to Song:
final String? artworkUrl;     // for Image.network()
final String? streamUrl;      // for audio plugin
final String? genre;
final int?    playCount;
final DateTime? releasedAt;
```

### Playlist

```dart
class Playlist {
  final String       id;
  final String       name;
  final String       description;  // e.g. "18 songs • Made by you"
  final List<Song>   songs;
  final Color        color;
}
```

Currently `songs` is always empty in mock data — playlists are display-only. To make them functional, populate `songs` from the API and update `LibraryScreen` to play them.

---

## Repository pattern

**File:** `lib/repositories/song_repository.dart`

```dart
abstract class SongRepository {
  List<Song>                   getSongs();
  List<Playlist>               getPlaylists();
  List<Map<String, dynamic>>   getCategories();
}
```

The abstract class is the only thing cubits and screens ever reference. The concrete implementation is injected at the root in `main.dart`:

```dart
RepositoryProvider<SongRepository>(
  create: (_) => MockSongRepository(),  // ← swap here
)
```

### `getCategories()` return shape

Returns a list of maps with exactly two keys:
```dart
{'name': 'Electronic', 'color': Color(0xFF7C3AED)}
```

These are consumed by `SearchScreen`'s category grid.

### `trendingArtists` shape (from HomeCubit)

`HomeCubit` derives a list of maps from songs:
```dart
{'name': 'Luna Echo', 'colorPrimary': Color(...), 'colorSecondary': Color(...)}
```

If you add an `artists` endpoint to `SongRepository`, return this shape (or a proper model) from there instead of deriving it in `HomeCubit`.

---

## MockSongRepository

**File:** `lib/repositories/mock_song_repository.dart`

8 hard-coded songs, 4 playlists, 10 search categories. All `static const` or `static final`. Methods return `List.unmodifiable(...)` to prevent accidental mutation.

---

## Mock data constants

**File:** `lib/data/mock_data.dart`

Standalone constants (`mockSongs`, `mockPlaylists`, `searchCategories`) that are **only used by `MockSongRepository`**. Do not import `mock_data.dart` anywhere else.

---

## Writing a real SongRepository

```dart
// lib/repositories/api_song_repository.dart

import '../models/song.dart';
import 'song_repository.dart';

class ApiSongRepository implements SongRepository {
  final String baseUrl;
  final http.Client _client;

  ApiSongRepository({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  @override
  List<Song> getSongs() {
    // For a truly async API, change the signature to Future<List<Song>>
    // and update SongRepository + all cubits that call getSongs().
    throw UnimplementedError('Use getSongsAsync() instead');
  }

  Future<List<Song>> getSongsAsync() async {
    final response = await _client.get(Uri.parse('$baseUrl/songs'));
    final data = jsonDecode(response.body) as List;
    return data.map((json) => Song(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      album: json['album'],
      duration: Duration(seconds: json['durationSeconds']),
      // Use a fixed color until the API provides per-song colors,
      // or map genre → color in a helper function:
      colorPrimary: _colorForGenre(json['genre']),
      colorSecondary: _colorForGenre(json['genre'], secondary: true),
    )).toList();
  }
}
```

### Making the repository async

The current `SongRepository` interface is synchronous. To switch to async:

1. Change `SongRepository.getSongs()` → `Future<List<Song>> getSongs()`
2. Update `HomeCubit`, `SearchCubit` to `await` the call
3. Add Loading/Error states to `HomeState` and `SearchState`
4. Update screens to handle loading states

---

## Data flow diagram

```
User taps song card
      │
      ▼
SongCard._handleTap()
      │
      ▼
PlayerCubit.playQueue(queue, startIndex: i)
      │
      ├── _queue = songs list (in-memory)
      ├── _playSong(songs[i])
      │       ├── cancel any running timer
      │       ├── emit PlayerState(currentSong: song, isPlaying: true, progress: 0)
      │       └── _startTimer() → emits progress updates every 500ms
      │
      └── (on desktop) nothing else
          (on mobile)  Navigator.push(PlayerScreen)

PlayerScreen / PlayerPanel watches PlayerCubit
      │
      └── rebuilds when state changes
              ├── AlbumArtWidget    uses song.colorPrimary/Secondary
              ├── title/artist text uses song.title/artist
              ├── SquigglyProgressBar uses state.progress
              └── playback controls use state.isPlaying, isShuffle, isRepeat
```

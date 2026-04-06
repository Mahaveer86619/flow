# Extension Guide

Step-by-step instructions for the most common additions to this template.

---

## 1. Connect real audio playback

**Recommended plugin:** `just_audio` (pub.dev)

### Step 1 — Add dependency

```yaml
# pubspec.yaml
dependencies:
  just_audio: ^0.9.x
```

### Step 2 — Add `streamUrl` to Song

```dart
// lib/models/song.dart
class Song {
  // ... existing fields ...
  final String? streamUrl;  // null for mock songs
}
```

### Step 3 — Inject audio player into PlayerCubit

```dart
// lib/cubits/player_cubit.dart
import 'package:just_audio/just_audio.dart';

class PlayerCubit extends Cubit<PlayerState> {
  final AudioPlayer _player = AudioPlayer();

  PlayerCubit() : super(const PlayerState()) {
    // Forward position stream to state
    _player.positionStream.listen((pos) {
      final total = _player.duration?.inMilliseconds ?? 1;
      final progress = pos.inMilliseconds / total;
      emit(state.copyWith(progress: progress.clamp(0.0, 1.0)));
    });
    _player.playerStateStream.listen((playerState) {
      emit(state.copyWith(isPlaying: playerState.playing));
    });
  }

  void _playSong(Song song) async {
    // Remove the existing _progressTimer logic and replace:
    final recent = [song, ...state.recentlyPlayed.where((s) => s.id != song.id)];
    if (recent.length > 20) recent.removeLast();
    emit(state.copyWith(currentSong: song, isPlaying: true, progress: 0.0, recentlyPlayed: recent));

    if (song.streamUrl != null) {
      await _player.setUrl(song.streamUrl!);
      await _player.play();
    }
  }

  void togglePlayPause() {
    _player.playing ? _player.pause() : _player.play();
  }

  void seekTo(double value) {
    final duration = _player.duration;
    if (duration != null) {
      _player.seek(duration * value);
    }
  }

  void setVolume(double value) {
    _player.setVolume(value);
    emit(state.copyWith(volume: value));
  }

  @override
  Future<void> close() async {
    await _player.dispose();
    return super.close();
  }
}
```

---

## 2. Connect a REST API for song data

### Step 1 — Add `http` dependency

```yaml
dependencies:
  http: ^1.x.x
```

### Step 2 — Extend the Song model

```dart
class Song {
  // ... existing fields ...
  final String? artworkUrl;
  final String? streamUrl;

  const Song({
    // ... existing params ...
    this.artworkUrl,
    this.streamUrl,
  });

  factory Song.fromJson(Map<String, dynamic> json) => Song(
    id: json['id'],
    title: json['title'],
    artist: json['artist_name'],
    album: json['album_name'],
    duration: Duration(seconds: json['duration_seconds']),
    colorPrimary: _genreColor(json['genre']),
    colorSecondary: _genreColor(json['genre'], secondary: true),
    artworkUrl: json['artwork_url'],
    streamUrl: json['stream_url'],
  );
}
```

### Step 3 — Create ApiSongRepository

```dart
// lib/repositories/api_song_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import 'song_repository.dart';

class ApiSongRepository implements SongRepository {
  final String baseUrl;
  final String authToken;

  ApiSongRepository({required this.baseUrl, required this.authToken});

  @override
  List<Song> getSongs() => throw UnimplementedError('Use async variant');

  Future<List<Song>> fetchSongs() async {
    final res = await http.get(
      Uri.parse('$baseUrl/songs'),
      headers: {'Authorization': 'Bearer $authToken'},
    );
    if (res.statusCode != 200) throw Exception('Failed to load songs');
    final list = jsonDecode(res.body) as List;
    return list.map((j) => Song.fromJson(j)).toList();
  }
}
```

### Step 4 — Add async loading to HomeCubit

```dart
// Add loading state:
class HomeState {
  final bool isLoading;
  final String? error;
  // ... rest of fields, now nullable:
  final List<Song> allSongs;
  // ...
}

class HomeCubit extends Cubit<HomeState> {
  final ApiSongRepository _repo;
  HomeCubit(this._repo) : super(HomeState.loading()) {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final songs = await _repo.fetchSongs();
      emit(HomeState.loaded(songs));
    } catch (e) {
      emit(HomeState.error(e.toString()));
    }
  }
}
```

### Step 5 — Swap repository in main.dart

```dart
RepositoryProvider<SongRepository>(
  create: (_) => ApiSongRepository(
    baseUrl: 'https://api.yourservice.com',
    authToken: const String.fromEnvironment('API_TOKEN'),
  ),
)
```

---

## 3. Replace artwork placeholders with real images

### AlbumArtWidget

```dart
// lib/widgets/album_art_widget.dart
// Replace the entire Stack child with:
child: song.artworkUrl != null
    ? ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          song.artworkUrl!,
          width: size, height: size,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : _VinylPlaceholder(size: size, ...),
          errorBuilder: (_, __, ___) => _VinylPlaceholder(size: size, ...),
        ),
      )
    : _VinylPlaceholder(size: size, ...),
```

Move the existing vinyl Stack to `_VinylPlaceholder` and use it as fallback.

### SongCard

Same pattern in `lib/widgets/song_card.dart` — replace the gradient Container.

### ArtistCard

```dart
// Replace initials Text with:
ClipRRect(
  borderRadius: BorderRadius.circular(16),
  child: Image.network(
    artist['imageUrl'],
    width: cardSize, height: cardSize,
    fit: BoxFit.cover,
  ),
)
```

---

## 4. Add authentication

### Step 1 — Create AuthRepository

```dart
// lib/repositories/auth_repository.dart
abstract class AuthRepository {
  Future<String?> signIn(String email, String password);
  Future<void> signOut();
  Stream<bool> get authStateChanges;
}
```

### Step 2 — Create AuthCubit

```dart
// lib/cubits/auth_cubit.dart
class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? error;
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repo;
  AuthCubit(this._repo) : super(AuthState(isAuthenticated: false)) {
    _repo.authStateChanges.listen((authed) => emit(...));
  }

  Future<void> signIn(String email, String password) async { ... }
  Future<void> signOut() async { ... }
}
```

### Step 3 — Gate navigation in SplashScreen

```dart
// Instead of navigating directly to _RootShell:
final authState = context.read<AuthCubit>().state;
if (authState.isAuthenticated) {
  Navigator.pushReplacement(context, ..._RootShell...);
} else {
  Navigator.pushReplacement(context, ...LoginScreen...);
}
```

---

## 5. Persist liked songs and search history

```dart
// Add to pubspec.yaml:
// shared_preferences: ^2.x.x

// In PlayerCubit.toggleLike():
void toggleLike(Song song) async {
  final liked = List<String>.from(state.likedSongIds);
  liked.contains(song.id) ? liked.remove(song.id) : liked.add(song.id);
  emit(state.copyWith(likedSongIds: liked));

  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('liked_songs', liked);
}

// In PlayerCubit constructor — restore from storage:
PlayerCubit() : super(const PlayerState()) {
  _restoreLikedSongs();
}

Future<void> _restoreLikedSongs() async {
  final prefs = await SharedPreferences.getInstance();
  final liked = prefs.getStringList('liked_songs') ?? [];
  emit(state.copyWith(likedSongIds: liked));
}
```

Same pattern applies to `SearchCubit.addRecentSearch()`.

---

## 6. Add a new Home screen section

### Step 1 — Add data to HomeState

```dart
// lib/cubits/home_cubit.dart
class HomeState {
  // ... existing fields ...
  final List<Song> hotNewReleases;  // new section
}
```

### Step 2 — Populate in HomeCubit._build()

```dart
return HomeState(
  // ... existing ...
  hotNewReleases: songs.where((s) => s.isNewRelease).toList(),
);
```

### Step 3 — Add section to HomeScreen

```dart
// In HomeScreen.build() slivers list:
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
    child: SectionHeader(title: 'Hot New Releases', onSeeAll: () {}),
  ),
),
SliverToBoxAdapter(
  child: SizedBox(
    height: 190,
    child: _HorizontalSongRow(
      songs: state.hotNewReleases,
      allSongs: state.allSongs,
    ),
  ),
),
```

---

## 7. Add a new screen with navigation

### Step 1 — Create the screen

```dart
// lib/screens/artist_detail_screen.dart
class ArtistDetailScreen extends StatelessWidget {
  final String artistName;
  const ArtistDetailScreen({super.key, required this.artistName});
  // ...
}
```

### Step 2 — Add nav destination (mobile)

```dart
// lib/screens/main_screen.dart — add to NavigationBar destinations:
NavigationDestination(
  icon: Icon(Icons.person_outline_rounded),
  selectedIcon: Icon(Icons.person_rounded),
  label: 'Artists',
)
// Also add ArtistScreen() to _screens list
```

### Step 3 — Add nav destination (desktop)

```dart
// lib/screens/desktop_shell.dart — add to NavigationRail destinations:
NavigationRailDestination(
  icon: Icon(Icons.person_outline_rounded),
  selectedIcon: Icon(Icons.person_rounded),
  label: Text('Artists'),
)
// Also add to _screens list
```

Keep the `_index` values in sync between both shells.

---

## 8. Change the app theme color

In `main.dart`, change the seed:
```dart
const seedColor = Color(0xFF7C3AED);  // ← change this
```

All Material 3 color roles regenerate from the seed automatically.

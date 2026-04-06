# UI Components

All reusable widgets live in `lib/widgets/`. Screens compose from these rather than duplicating UI code.

---

## PlayerPanel

**File:** `lib/widgets/player_panel.dart`

The complete now-playing UI. Used in two contexts:

| Context | `showBackButton` | `artMaxSize` |
|---------|-----------------|--------------|
| `PlayerScreen` (mobile full-screen) | `true` | `null` (fills space) |
| `_PlayerSidebar` (desktop) | `false` | `panelWidth - 48` |

```dart
PlayerPanel(
  showBackButton: true,   // shows chevron-down dismiss button
  artMaxSize: 300,        // caps artwork square (optional)
)
```

### Sub-widgets (private)

| Widget | Purpose |
|--------|---------|
| `_EmptyPlayerPanel` | Shown when no song is loaded |
| `_TopBar` | Back button / "Now Playing" / overflow menu |
| `_PlaybackControls` | Shuffle, prev, play/pause, next, repeat |
| `_PlayPauseButton` | The large white circle button |
| `_VolumeRow` | Volume icons + slider |

All sub-widgets read `PlayerCubit` independently so only the relevant widget rebuilds on state change.

---

## AlbumArtWidget

**File:** `lib/widgets/album_art_widget.dart`

Vinyl-record–style artwork placeholder.

```dart
AlbumArtWidget(
  size: 280,
  colorPrimary: song.colorPrimary,
  colorSecondary: song.colorSecondary,
  borderRadius: 24,  // default
)
```

Visual layers (back to front):
1. Gradient rectangle background
2. Top-right highlight bubble
3. Outer vinyl ring (circle outline)
4. Middle vinyl ring (filled + outline)
5. Center hub with `Icons.music_note_rounded`

**To replace with real artwork:**
```dart
// In AlbumArtWidget.build(), replace the Stack with:
ClipRRect(
  borderRadius: BorderRadius.circular(borderRadius),
  child: Image.network(
    artworkUrl,
    width: size, height: size,
    fit: BoxFit.cover,
    loadingBuilder: (_, child, progress) =>
        progress == null ? child : _placeholderGradient(), // keep gradient as fallback
  ),
)
```

---

## SongCard

**File:** `lib/widgets/song_card.dart`

Portrait card for horizontal scrolling song lists.

```dart
SongCard(
  song: song,
  queue: allSongs,  // full list for queue building
  index: 2,         // position of this song in queue
  cardWidth: 135,   // default
)
```

- Tapping calls `PlayerCubit.playQueue(queue, startIndex: index)`
- On mobile/tablet: also pushes `PlayerScreen`
- On desktop: playback only, no route push

**To replace artwork:**
```dart
// Replace the gradient Container with:
ClipRRect(
  borderRadius: BorderRadius.circular(14),
  child: Image.network(song.artworkUrl, width: cardWidth, height: cardWidth, fit: BoxFit.cover),
)
```

---

## ArtistCard

**File:** `lib/widgets/artist_card.dart`

Square gradient card showing artist name + initials. Used in "Trending Artists".

```dart
ArtistCard(
  artist: {
    'name': 'Luna Echo',
    'colorPrimary': Color(0xFF7C3AED),
    'colorSecondary': Color(0xFF2563EB),
  },
  cardSize: 110,  // default
)
```

**To replace with real profile image:**
```dart
// Replace initials Text with:
ClipRRect(
  borderRadius: BorderRadius.circular(16),
  child: Image.network(artist['imageUrl'], fit: BoxFit.cover),
)
```

---

## SectionHeader

**File:** `lib/widgets/section_header.dart`

Title row with optional "See all" button.

```dart
SectionHeader(
  title: 'Listening Again',
  onSeeAll: () => Navigator.push(...),  // omit to hide button
)
```

---

## MiniPlayer

**File:** `lib/widgets/mini_player.dart`

Compact playback bar shown above the `BottomNavigationBar` in `MainScreen`.

- Returns `SizedBox.shrink()` when no song is loaded
- Shows song art, title, play/pause, next
- Progress indicator at bottom edge
- Tapping the body pushes `PlayerScreen`

No parameters — reads `PlayerCubit` directly.

---

## SquigglyProgressBar

**File:** `lib/widgets/squiggly_progress_bar.dart`

Animated sine-wave progress bar with drag-to-seek.

```dart
SquigglyProgressBar(
  progress: 0.35,          // 0.0–1.0
  onSeek: (v) => cubit.seekTo(v),
)
```

Height: 28 px. The wave amplitude is 28% of height. The animated dot sits on the wave at the progress position.

Internal: `AnimationController` drives the wave phase at 2s/cycle. `CustomPaint` with `_SquigglyPainter` clips the path at `progress * width` to paint played/unplayed portions in different colors.

---

## HomeScreen internal widgets

These are private to `home_screen.dart` (not exported):

| Widget | Description |
|--------|-------------|
| `_QuickAccessGrid` | `GridView` 2-col, fixed-height tiles |
| `_QuickAccessTile` | Coloured strip + song title, handles responsive nav |
| `_HorizontalSongRow` | `ListView` horizontal wrapping `SongCard` |
| `_MusicForYouGrid` | `GridView` horizontal, 2 rows, portrait cards |
| `_TrendingArtistRow` | `ListView` horizontal wrapping `ArtistCard` |

---

## DesktopShell internal widgets

Private to `desktop_shell.dart`:

| Widget | Description |
|--------|-------------|
| `_DesktopNavRail` | `NavigationRail` with logo, destinations, settings/notifications |
| `_DesktopTopBar` | 56 px top bar with app title and recently played button |
| `_PlayerSidebar` | 340 px container wrapping `PlayerPanel`, gradient from song colors |
| `_RecentlyPlayedDialog` | `AlertDialog` showing play history |
| `_SettingRow` | Dense `ListTile` for settings entries |

---

## Theme & typography

Configured in `FlowApp._buildTheme()` in `main.dart`.

| Usage | Font | Weight |
|-------|------|--------|
| App title "flow" | Space Grotesk | w800 |
| Screen headings | Space Grotesk | w700 |
| Song titles | Space Grotesk | w700 |
| Body text | Outfit | w400–w600 |
| Labels / metadata | Outfit | w400 |

Seed color: `Color(0xFF7C3AED)` purple. All `colorScheme.*` colors are generated from this seed via `ColorScheme.fromSeed`.

Dark mode is the default (`themeMode: ThemeMode.dark`).

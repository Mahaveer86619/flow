// ─────────────────────────────────────────────────────────────────────────────
// DesktopShell — three-pane layout for desktop screens (≥ 1100 px).
//
// Layout:
//   ┌──────────────┬────────────────────────────┬───────────────┐
//   │ NavigationRail│       Main Content         │  Player Panel │
//   │   (72 px)    │        (Expanded)           │   (340 px)    │
//   └──────────────┴────────────────────────────┴───────────────┘
//
// The player panel is always visible. When nothing is playing it shows an
// "empty" state. When a song starts (via [PlayerCubit]) the panel updates
// automatically.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../cubits/player_cubit.dart';
import '../../widgets/player_panel.dart';
import '../home/home_screen.dart';
import '../library/library_screen.dart';
import '../search/search_screen.dart';

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _index = 0;

  // Screens share the same cubit instances provided by main.dart.
  static const _screens = [HomeScreen(), SearchScreen(), LibraryScreen()];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Row(
        children: [
          // ── Left pane: NavigationRail ──────────────────────────────────────
          _DesktopNavRail(
            index: _index,
            onIndexChanged: (i) => setState(() => _index = i),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withAlpha(60),
          ),

          // ── Center pane: main content ──────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                _DesktopTopBar(),
                Expanded(
                  child: IndexedStack(index: _index, children: _screens),
                ),
              ],
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withAlpha(60),
          ),

          // ── Right pane: player panel ───────────────────────────────────────
          const _PlayerSidebar(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Left navigation rail
// ─────────────────────────────────────────────────────────────────────────────

class _DesktopNavRail extends StatelessWidget {
  final int index;
  final ValueChanged<int> onIndexChanged;

  const _DesktopNavRail({required this.index, required this.onIndexChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return NavigationRail(
      backgroundColor: colorScheme.surface,
      selectedIndex: index,
      onDestinationSelected: onIndexChanged,
      extended: false,
      minWidth: 72,
      // App logo at top of rail
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'f',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -2,
            color: colorScheme.primary,
          ),
        ),
      ),
      // Settings & notifications pinned to the bottom of the rail
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Notifications',
                  onPressed: () => _showDialog(
                    context,
                    title: 'Notifications',
                    body: 'No new notifications.',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Settings',
                  onPressed: () => _showSettingsDialog(context),
                ),
              ],
            ),
          ),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.search_rounded),
          label: Text('Search'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.library_music_outlined),
          selectedIcon: Icon(Icons.library_music_rounded),
          label: Text('Library'),
        ),
      ],
    );
  }

  void _showDialog(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Settings',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _SettingRow(
                icon: Icons.graphic_eq_rounded,
                title: 'Audio Quality',
                value: 'High (320 kbps)',
              ),
              _SettingRow(
                icon: Icons.equalizer_rounded,
                title: 'Equalizer',
                value: 'Off',
              ),
              _SettingRow(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                value: 'Dark • System',
              ),
              _SettingRow(
                icon: Icons.info_outline_rounded,
                title: 'About flow',
                value: 'v1.0.0',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(value, style: const TextStyle(fontSize: 12)),
      dense: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar for the center content pane
// ─────────────────────────────────────────────────────────────────────────────

class _DesktopTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withAlpha(60),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'flow',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -2,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          // Recently played dialog
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Recently played',
            onPressed: () => _showRecentlyPlayed(context),
          ),
        ],
      ),
    );
  }

  void _showRecentlyPlayed(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<PlayerCubit>(),
        child: _RecentlyPlayedDialog(),
      ),
    );
  }
}

class _RecentlyPlayedDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerCubit>().state;
    final songs = state.recentlyPlayed;

    return AlertDialog(
      title: Text(
        'Recently Played',
        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 380,
        height: 320,
        child: songs.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nothing played yet',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: songs.length,
                itemBuilder: (context, i) {
                  final song = songs[i];
                  return ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [song.colorPrimary, song.colorSecondary],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.music_note_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      song.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(song.artist),
                    // On desktop: just play, the sidebar updates.
                    onTap: () {
                      context.read<PlayerCubit>().play(song);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Right player sidebar
// ─────────────────────────────────────────────────────────────────────────────

class _PlayerSidebar extends StatelessWidget {
  const _PlayerSidebar();

  /// Change this value to resize the player sidebar globally.
  static const double _panelWidth = 340;

  @override
  Widget build(BuildContext context) {
    final song = context.watch<PlayerCubit>().state.currentSong;

    return Container(
      width: _panelWidth,
      // Gradient follows the current song's colors; plain dark bg when idle.
      decoration: song != null
          ? BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomCenter,
                colors: [
                  song.colorPrimary.withAlpha(160),
                  const Color(0xFF0A0A14),
                  const Color(0xFF0A0A14),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            )
          : const BoxDecoration(color: Color(0xFF0A0A14)),
      child: SafeArea(
        child: PlayerPanel(
          showBackButton: false,
          // Artwork never exceeds the sidebar width minus horizontal padding.
          artMaxSize: _panelWidth - 48,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DesktopShell — three-pane layout for desktop screens (≥ 1100 px).
//
// Layout:
//   ┌──────────────┬────────────────────────────┬───────────────┐
//   │ NavigationRail│       Main Content         │  Player Panel │
//   │   (72 px)    │        (Expanded)           │   (340 px)    │
//   └──────────────┴────────────────────────────┴───────────────┘
//
// The player panel slides in from the right the first time a song plays and
// stays visible until the app is closed. The divider appears with it.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/player/player_bloc.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/player_panel.dart';
import '../home/home_screen.dart';
import '../library/library_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;

  static const _screens = [HomeScreen(), SearchScreen(), LibraryScreen()];

  static const double _panelWidth = 340;

  late final AnimationController _panelCtrl;
  late final Animation<double> _panelAnim;

  @override
  void initState() {
    super.initState();
    _panelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _panelAnim = CurvedAnimation(
      parent: _panelCtrl,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _panelCtrl.dispose();
    super.dispose();
  }

  void _syncPanel(bool hasSong) {
    if (hasSong && _panelCtrl.status == AnimationStatus.dismissed) {
      _panelCtrl.forward();
    } else if (!hasSong && _panelCtrl.status == AnimationStatus.completed) {
      _panelCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = context.watch<PlayerBloc>().state;
    final hasSong = state.currentSong != null;

    // Drive animation reactively — no setState needed.
    _syncPanel(hasSong);

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
                const OfflineBanner(),
                _DesktopTopBar(),
                Expanded(
                  child: IndexedStack(index: _index, children: _screens),
                ),
              ],
            ),
          ),

          // ── Right pane: player panel (animates in/out) ─────────────────────
          AnimatedBuilder(
            animation: _panelAnim,
            builder: (context, child) {
              final width = _panelAnim.value * _panelWidth;
              if (width <= 0) return const SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Divider fades + slides with the panel
                  Opacity(
                    opacity: _panelAnim.value,
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: colorScheme.outlineVariant.withAlpha(60),
                    ),
                  ),
                  // Panel reveals from left edge (slide-in-from-right effect)
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerRight,
                      widthFactor: _panelAnim.value,
                      child: child,
                    ),
                  ),
                ],
              );
            },
            child: _buildPlayerPanel(state),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerPanel(PlayerState state) {
    final song = state.currentSong;
    return Container(
      width: _panelWidth,
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
          artMaxSize: _panelWidth - 48,
        ),
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
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
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
        value: context.read<PlayerBloc>(),
        child: _RecentlyPlayedDialog(),
      ),
    );
  }
}

class _RecentlyPlayedDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerBloc>().state;
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
                    onTap: () {
                      context.read<PlayerBloc>().add(PlaySingleEvent(song));
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

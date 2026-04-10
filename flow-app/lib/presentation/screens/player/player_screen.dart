import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/song.dart';
import '../../blocs/player/player_bloc.dart';
import '../../widgets/album_art_widget.dart';
import '../../widgets/squiggly_progress_bar.dart';
import '../queue/queue_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PlayerScreen (mobile) — vertically scrollable layout.
//
// Scroll sections:
//   1. Main player    — album art, song info, progress, controls (fills viewport)
//   2. Artist card    — large gradient card, same aspect ratio as album art
//   3. Metadata card  — album, duration, artist details
// ─────────────────────────────────────────────────────────────────────────────

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerBloc>().state;
    final song = state.currentSong;

    if (song == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A14),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'Nothing playing',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: const Alignment(0.0, 0.55),
            colors: [
              song.colorPrimary.withAlpha(190),
              const Color(0xFF0A0A14),
            ],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── 1. Main player (fills the viewport) ──────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height,
                child: SafeArea(
                  child: _MainPlayerSection(song: song),
                ),
              ),
            ),

            // ── 2. Artist card ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _ArtistCard(song: song),
              ),
            ),

            // ── 3. Metadata card ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 52),
                child: _MetadataCard(song: song),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 1 — Main player (fills viewport height)
// ─────────────────────────────────────────────────────────────────────────────

class _MainPlayerSection extends StatelessWidget {
  final Song song;
  const _MainPlayerSection({required this.song});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerBloc>().state;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 6),

          // ── Top bar ──────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 30,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              Column(
                children: [
                  Text(
                    'NOW PLAYING',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withAlpha(160),
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    song.title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white.withAlpha(200),
                ),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Album art ────────────────────────────────────────────────────
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.maxHeight < constraints.maxWidth
                    ? constraints.maxHeight
                    : constraints.maxWidth;
                return Center(
                  child: AlbumArtWidget(
                    size: size,
                    colorPrimary: song.colorPrimary,
                    colorSecondary: song.colorSecondary,
                    thumbnailUrl: song.thumbnailUrl,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // ── Song info + like ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.white.withAlpha(170),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  state.isLiked(song)
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 24,
                  color: state.isLiked(song)
                      ? const Color(0xFFEC4899)
                      : Colors.white.withAlpha(170),
                ),
                onPressed: () => context.read<PlayerBloc>().add(
                  ToggleLikeEvent(song),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Squiggly progress bar ────────────────────────────────────────
          SquigglyProgressBar(
            progress: state.progress,
            onSeek: (fraction) => context.read<PlayerBloc>().add(
              SeekToEvent(fraction),
            ),
          ),
          const SizedBox(height: 2),

          // Time labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                state.currentTimeString,
                style: TextStyle(
                  color: Colors.white.withAlpha(140),
                  fontSize: 11,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                state.totalTimeString,
                style: TextStyle(
                  color: Colors.white.withAlpha(140),
                  fontSize: 11,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Playback controls ────────────────────────────────────────────
          _PlaybackControls(activeColor: song.colorPrimary),
          const SizedBox(height: 4),

          // ── Queue button + scroll-down hint ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.queue_music_rounded,
                  color: Colors.white.withAlpha(160),
                  size: 26,
                ),
                tooltip: 'Queue',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QueueScreen()),
                ),
              ),
              Column(
                children: [
                  Text(
                    'Artist & info',
                    style: TextStyle(
                      color: Colors.white.withAlpha(80),
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white.withAlpha(80),
                    size: 20,
                  ),
                ],
              ),
              // Balance the row
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Playback controls row
// ─────────────────────────────────────────────────────────────────────────────

class _PlaybackControls extends StatelessWidget {
  final Color activeColor;
  const _PlaybackControls({required this.activeColor});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerBloc>().state;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(
            Icons.shuffle_rounded,
            color:
                state.isShuffle ? activeColor : Colors.white.withAlpha(160),
            size: 21,
          ),
          onPressed: () => context.read<PlayerBloc>().add(
            const ToggleShuffleEvent(),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.skip_previous_rounded,
            size: 40,
            color: Colors.white,
          ),
          onPressed: () => context.read<PlayerBloc>().add(
            const SkipPreviousEvent(),
          ),
        ),
        // Play/Pause button
        _PlayPauseButton(),
        IconButton(
          icon: const Icon(
            Icons.skip_next_rounded,
            size: 40,
            color: Colors.white,
          ),
          onPressed: () => context.read<PlayerBloc>().add(
            const SkipNextEvent(),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.repeat_rounded,
            color: state.isRepeat ? activeColor : Colors.white.withAlpha(160),
            size: 21,
          ),
          onPressed: () => context.read<PlayerBloc>().add(
            const ToggleRepeatEvent(),
          ),
        ),
      ],
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerBloc>().state;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withAlpha(50),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 34,
          color: Colors.black,
        ),
        onPressed: () => context.read<PlayerBloc>().add(
          const TogglePlayPauseEvent(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 2 — Artist card (square, same aspect ratio as album art)
// ─────────────────────────────────────────────────────────────────────────────

class _ArtistCard extends StatelessWidget {
  final Song song;
  const _ArtistCard({required this.song});

  @override
  Widget build(BuildContext context) {
    final name = song.artist;
    final initials = name
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join();

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              song.colorPrimary,
              song.colorSecondary,
            ],
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Large faint initials background
            Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: MediaQuery.sizeOf(context).width * 0.38,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withAlpha(18),
                ),
              ),
            ),

            // "Artist" chip at top-left
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(70),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Artist',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // Bottom gradient + artist name
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withAlpha(200),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Artist',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.white.withAlpha(160),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 3 — Metadata card
// ─────────────────────────────────────────────────────────────────────────────

class _MetadataCard extends StatelessWidget {
  final Song song;
  const _MetadataCard({required this.song});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About this song',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _MetaRow(
            icon: Icons.album_rounded,
            label: 'Album',
            value: song.album,
          ),
          const Divider(height: 24, thickness: 0.5),
          _MetaRow(
            icon: Icons.person_outline_rounded,
            label: 'Artist',
            value: song.artist,
          ),
          const Divider(height: 24, thickness: 0.5),
          _MetaRow(
            icon: Icons.timer_outlined,
            label: 'Duration',
            value: _formatDuration(song.duration),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m min ${s.toString().padLeft(2, '0')} sec';
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 17, color: colorScheme.onSurface.withAlpha(120)),
        const SizedBox(width: 10),
        Text(
          '$label   ',
          style: TextStyle(
            color: colorScheme.onSurface.withAlpha(120),
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

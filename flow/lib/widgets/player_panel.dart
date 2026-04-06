// ─────────────────────────────────────────────────────────────────────────────
// PlayerPanel — the full player UI as a self-contained widget.
//
// Used in two contexts:
//   1. [PlayerScreen] (mobile) — full-screen modal, showBackButton = true
//   2. [DesktopShell] right sidebar — inline panel, showBackButton = false
//
// All audio state is read from [PlayerCubit]. To connect a real audio backend:
//   - Inject your audio service into [PlayerCubit].
//   - Implement [PlayerCubit.togglePlayPause], [seekTo], [setVolume], etc.
//   - The UI will update automatically via BLoC state emission.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/responsive/breakpoints.dart';
import '../cubits/player_cubit.dart';
import '../screens/queue/queue_screen.dart';
import 'album_art_widget.dart';
import 'squiggly_progress_bar.dart';

/// Renders the complete now-playing UI: artwork, song info, progress bar,
/// playback controls, and volume slider.
///
/// [showBackButton] – show the "chevron down" dismiss button (mobile only).
/// [artMaxSize]     – caps the artwork square size in pixels (useful for the
///                    fixed-width desktop sidebar).
class PlayerPanel extends StatelessWidget {
  final bool showBackButton;

  /// Maximum size for the album art square. Defaults to filling available space.
  final double? artMaxSize;

  const PlayerPanel({super.key, this.showBackButton = false, this.artMaxSize});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerCubit>().state;
    final cubit = context.read<PlayerCubit>();
    final song = state.currentSong;

    // Show placeholder when nothing is loaded.
    if (song == null) return const _EmptyPlayerPanel();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // ── Top bar: back button / title / more ─────────────────────────────
          _TopBar(showBackButton: showBackButton),
          const SizedBox(height: 12),

          // ── Album art ───────────────────────────────────────────────────────
          // Expanded fills remaining height; LayoutBuilder caps to a square.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxFromSpace =
                    constraints.maxHeight < constraints.maxWidth
                    ? constraints.maxHeight
                    : constraints.maxWidth;
                final size = artMaxSize != null
                    ? maxFromSpace.clamp(0.0, artMaxSize!)
                    : maxFromSpace;

                return Center(
                  child: AlbumArtWidget(
                    size: size,
                    colorPrimary: song.colorPrimary,
                    colorSecondary: song.colorSecondary,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // ── Song info + like button ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
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
                  size: 26,
                  color: state.isLiked(song)
                      ? const Color(0xFFEC4899)
                      : Colors.white.withAlpha(170),
                ),
                onPressed: () => cubit.toggleLike(song),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Squiggly progress bar ────────────────────────────────────────────
          SquigglyProgressBar(progress: state.progress, onSeek: cubit.seekTo),
          const SizedBox(height: 2),

          // Time labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                state.currentTimeString,
                style: TextStyle(
                  color: Colors.white.withAlpha(140),
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                state.totalTimeString,
                style: TextStyle(
                  color: Colors.white.withAlpha(140),
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Playback controls ────────────────────────────────────────────────
          _PlaybackControls(activeColor: song.colorPrimary),
          const SizedBox(height: 12),

          // ── Volume & Queue ────────────────────────────────────────────────────
          Builder(
            builder: (context) {
              final isDesktop = Breakpoints.isDesktop(
                MediaQuery.sizeOf(context).width,
              );
              if (isDesktop) {
                // Desktop: Volume + Queue button row
                return Row(
                  children: [
                    Expanded(
                      child: _VolumeRow(
                        volume: state.volume,
                        onChanged: cubit.setVolume,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        Icons.queue_music_rounded,
                        color: Colors.white.withAlpha(170),
                      ),
                      tooltip: 'Queue',
                      onPressed: () {
                        // Desktop app handles queue differently or pushes it.
                        // For now we just push the route.
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const QueueScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              } else {
                // Mobile: Only Queue button, no volume control
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.queue_music_rounded,
                        color: Colors.white.withAlpha(170),
                        size: 28,
                      ),
                      tooltip: 'Queue',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const QueueScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Shown when [PlayerCubit] has no current song.
class _EmptyPlayerPanel extends StatelessWidget {
  const _EmptyPlayerPanel();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.library_music_rounded,
            size: 64,
            color: Colors.white.withAlpha(40),
          ),
          const SizedBox(height: 16),
          Text(
            'Nothing playing',
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: Colors.white.withAlpha(80),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pick a song to start listening',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.white.withAlpha(50),
            ),
          ),
        ],
      ),
    );
  }
}

/// Top bar with optional back button, "Now Playing" label, and overflow menu.
class _TopBar extends StatelessWidget {
  final bool showBackButton;
  const _TopBar({required this.showBackButton});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (showBackButton)
          IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 32,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          )
        else
          // Spacer to keep the title centered
          const SizedBox(width: 48),
        Text(
          'Now Playing',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withAlpha(200),
            letterSpacing: 0.8,
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.more_vert_rounded,
            color: Colors.white.withAlpha(200),
          ),
          onPressed: () {
            // TODO: show track options (add to playlist, share, etc.)
          },
        ),
      ],
    );
  }
}

/// Shuffle / Previous / Play-Pause / Next / Repeat row.
///
/// Reads [PlayerCubit] independently so it rebuilds only on relevant changes.
class _PlaybackControls extends StatelessWidget {
  /// The primary color of the current song, used to tint active toggle icons.
  final Color activeColor;

  const _PlaybackControls({required this.activeColor});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerCubit>().state;
    final cubit = context.read<PlayerCubit>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Shuffle
        IconButton(
          icon: Icon(
            Icons.shuffle_rounded,
            color: state.isShuffle ? activeColor : Colors.white.withAlpha(170),
            size: 22,
          ),
          onPressed: cubit.toggleShuffle,
        ),
        // Previous
        IconButton(
          icon: const Icon(
            Icons.skip_previous_rounded,
            size: 42,
            color: Colors.white,
          ),
          onPressed: cubit.previous,
        ),
        // Play / Pause
        _PlayPauseButton(),
        // Next
        IconButton(
          icon: const Icon(
            Icons.skip_next_rounded,
            size: 42,
            color: Colors.white,
          ),
          onPressed: cubit.next,
        ),
        // Repeat
        IconButton(
          icon: Icon(
            Icons.repeat_rounded,
            color: state.isRepeat ? activeColor : Colors.white.withAlpha(170),
            size: 22,
          ),
          onPressed: cubit.toggleRepeat,
        ),
      ],
    );
  }
}

/// Circular play/pause button. Watches [PlayerCubit] independently.
class _PlayPauseButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerCubit>().state;
    final cubit = context.read<PlayerCubit>();

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withAlpha(60),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 38,
          color: Colors.black,
        ),
        onPressed: cubit.togglePlayPause,
      ),
    );
  }
}

/// Volume slider with mute/max icons.
class _VolumeRow extends StatelessWidget {
  final double volume;
  final ValueChanged<double> onChanged;

  const _VolumeRow({required this.volume, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.volume_down_rounded,
          color: Colors.white.withAlpha(140),
          size: 20,
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withAlpha(40),
              thumbColor: Colors.white,
              overlayColor: Colors.white.withAlpha(20),
            ),
            child: Slider(value: volume, onChanged: onChanged),
          ),
        ),
        Icon(
          Icons.volume_up_rounded,
          color: Colors.white.withAlpha(140),
          size: 20,
        ),
      ],
    );
  }
}

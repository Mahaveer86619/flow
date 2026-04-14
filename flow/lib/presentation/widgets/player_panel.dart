// ─────────────────────────────────────────────────────────────────────────────
// PlayerPanel — the full player UI as a self-contained widget.
//
// Used in two contexts:
//   1. [PlayerScreen] (mobile) — full-screen modal, showBackButton = true
//   2. [DesktopShell] right sidebar — inline panel, showBackButton = false
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/config/app_constants.dart';
import '../../core/responsive/breakpoints.dart';
import '../../../domain/entities/song.dart';
import '../blocs/player/player_bloc.dart';
import '../screens/queue/queue_screen.dart';
import 'album_art_widget.dart';
import 'squiggly_progress_bar.dart';

/// Renders the complete now-playing UI: artwork, song info, progress bar,
/// playback controls, and volume slider.
///
/// [showBackButton] – show the "chevron down" dismiss button (mobile only).
/// [artMaxSize]     – caps the artwork square size in pixels (useful for the
///                    fixed-width desktop sidebar).
import 'text_carousel.dart';

class PlayerPanel extends StatelessWidget {
  final bool showBackButton;
  final double? artMaxSize;

  const PlayerPanel({super.key, this.showBackButton = false, this.artMaxSize});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (prev, curr) => prev.currentSong?.id != curr.currentSong?.id,
      builder: (context, state) {
        final song = state.currentSong;
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
                      child: RepaintBoundary(
                        child: Hero(
                          tag: 'active_art_${song.id}',
                          child: AlbumArtWidget(
                            size: size,
                            colorPrimary: song.colorPrimary,
                            colorSecondary: song.colorSecondary,
                            thumbnailUrl: song.thumbnailUrl,
                          ),
                        ),
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
                        TextCarousel(
                          text: song.title,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.artist,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withAlpha(160),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  BlocBuilder<PlayerBloc, PlayerState>(
                    buildWhen: (prev, curr) =>
                        prev.likedSongIds != curr.likedSongIds,
                    builder: (context, state) {
                      final isLiked = state.isLiked(song);
                      return IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: child,
                            );
                          },
                          child: Icon(
                            isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            key: ValueKey(isLiked),
                            size: 28,
                            color: isLiked
                                ? const Color(0xFFEC4899)
                                : Colors.white.withAlpha(140),
                          ),
                        ),
                        onPressed: () => context.read<PlayerBloc>().add(
                          ToggleLikeEvent(song),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      song.isDownloaded
                          ? Icons.download_done_rounded
                          : Icons.download_for_offline_outlined,
                      size: 26,
                      color: song.isDownloaded
                          ? Colors.greenAccent
                          : Colors.white.withAlpha(140),
                    ),
                    onPressed: () {
                      context.read<PlayerBloc>().add(ToggleDownloadEvent(song));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Squiggly progress bar ────────────────────────────────────────────
              BlocBuilder<PlayerBloc, PlayerState>(
                buildWhen: (prev, curr) =>
                    prev.progress != curr.progress ||
                    prev.bufferProgress != curr.bufferProgress ||
                    prev.isInitialLoading != curr.isInitialLoading ||
                    prev.isBuffering != curr.isBuffering,
                builder: (context, state) {
                  return SquigglyProgressBar(
                    progress: state.progress,
                    bufferProgress: state.bufferProgress,
                    isInitialLoading: state.isInitialLoading,
                    isBuffering: state.isBuffering,
                    onSeek: (frac) =>
                        context.read<PlayerBloc>().add(SeekToEvent(frac)),
                  );
                },
              ),
              const SizedBox(height: 2),

              // Time labels
              BlocBuilder<PlayerBloc, PlayerState>(
                buildWhen: (prev, curr) =>
                    prev.currentTimeString != curr.currentTimeString ||
                    prev.totalTimeString != curr.totalTimeString,
                builder: (context, state) {
                  return Row(
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
                  );
                },
              ),
              const SizedBox(height: 16),

              // ── Playback controls ────────────────────────────────────────────────
              _PlaybackControls(activeColor: song.colorPrimary),
              const SizedBox(height: 12),

              // ── Volume (desktop) / Queue button ──────────────────────────────────
              Builder(
                builder: (context) {
                  final isDesktop = Breakpoints.isDesktop(
                    MediaQuery.sizeOf(context).width,
                  );
                  if (isDesktop) {
                    return Row(
                      children: [
                        Expanded(
                          child: BlocBuilder<PlayerBloc, PlayerState>(
                            buildWhen: (prev, curr) =>
                                prev.volume != curr.volume,
                            builder: (context, state) {
                              return _VolumeRow(
                                volume: state.volume,
                                onChanged: (v) => context
                                    .read<PlayerBloc>()
                                    .add(SetVolumeEvent(v)),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Icon(
                            Icons.queue_music_rounded,
                            color: Colors.white.withAlpha(170),
                          ),
                          tooltip: 'Queue',
                          onPressed: () => QueueScreen.show(context),
                        ),
                      ],
                    );
                  } else {
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
                          onPressed: () => QueueScreen.show(context),
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
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

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

class _TopBar extends StatelessWidget {
  final bool showBackButton;
  const _TopBar({required this.showBackButton});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerBloc>().state;
    final song = state.currentSong;

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
        _MoreOptionsButton(showBackButton: showBackButton, song: song),
      ],
    );
  }
}

class _MoreOptionsButton extends StatelessWidget {
  final bool showBackButton;
  final Song? song;

  const _MoreOptionsButton({required this.showBackButton, this.song});

  @override
  Widget build(BuildContext context) {
    // If showBackButton is true, we are in a mobile modal context.
    // If false, we are in the desktop sidebar.
    if (showBackButton) {
      return IconButton(
        icon: Icon(Icons.more_vert_rounded, color: Colors.white.withAlpha(200)),
        onPressed: () {
          if (song != null) {
            _showMobileOptions(context, song!);
          }
        },
      );
    }

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: Colors.white.withAlpha(200)),
      onSelected: (value) {
        if (song == null) return;
        if (value == 'radio') {
          context.read<PlayerBloc>().add(PlayRadioEvent(song!));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'radio',
          child: Row(
            children: [
              const Icon(Icons.radio_rounded, size: 20),
              const SizedBox(width: 12),
              const Text('Start radio'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'playlist',
          child: Row(
            children: [
              const Icon(Icons.playlist_add_rounded, size: 20),
              const SizedBox(width: 12),
              const Text('Add to playlist'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              const Icon(Icons.share_outlined, size: 20),
              const SizedBox(width: 12),
              const Text('Share'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'artist',
          child: Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 20),
              const SizedBox(width: 12),
              const Text('View artist'),
            ],
          ),
        ),
      ],
    );
  }

  void _showMobileOptions(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.radio_rounded, color: Colors.white),
              title: const Text(
                'Start radio',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                context.read<PlayerBloc>().add(PlayRadioEvent(song));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.playlist_add_rounded,
                color: Colors.white,
              ),
              title: const Text(
                'Add to playlist',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: Colors.white),
              title: const Text('Share', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
              ),
              title: const Text(
                'View artist',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

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
            color: state.isShuffle ? activeColor : Colors.white.withAlpha(170),
            size: 22,
          ),
          onPressed: () =>
              context.read<PlayerBloc>().add(const ToggleShuffleEvent()),
        ),
        IconButton(
          icon: const Icon(
            Icons.skip_previous_rounded,
            size: 42,
            color: Colors.white,
          ),
          onPressed: () =>
              context.read<PlayerBloc>().add(const SkipPreviousEvent()),
        ),
        _PlayPauseButton(),
        IconButton(
          icon: const Icon(
            Icons.skip_next_rounded,
            size: 42,
            color: Colors.white,
          ),
          onPressed: () =>
              context.read<PlayerBloc>().add(const SkipNextEvent()),
        ),
        IconButton(
          icon: Icon(
            Icons.repeat_rounded,
            color: state.isRepeat ? activeColor : Colors.white.withAlpha(170),
            size: 22,
          ),
          onPressed: () =>
              context.read<PlayerBloc>().add(const ToggleRepeatEvent()),
        ),
      ],
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerBloc>().state;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.white.withAlpha(230)],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha(80),
            blurRadius: 32,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withAlpha(100),
            blurRadius: 16,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () =>
              context.read<PlayerBloc>().add(const TogglePlayPauseEvent()),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                state.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                key: ValueKey(state.isPlaying),
                size: 42,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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

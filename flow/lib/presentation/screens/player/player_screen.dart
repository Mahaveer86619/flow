import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/song.dart';
import '../../blocs/player/player_bloc.dart';
import '../../widgets/album_art_widget.dart';
import '../../widgets/squiggly_progress_bar.dart';
import '../queue/queue_screen.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      enableDrag: false, // Handle drag manually via DraggableScrollableSheet
      builder: (context) => const PlayerScreen(),
    );
  }

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerBloc>().state;
    final song = state.currentSong;

    if (song == null) return const SizedBox.shrink();

    final primary = state.customPrimary ?? song.colorPrimary;
    final secondary = state.customSecondary ?? song.colorSecondary;

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        if (notification.extent <= 0.0) {
          Navigator.pop(context);
        }
        return true;
      },
      child: DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 0.0,
        maxChildSize: 1.0,
        snap: true,
        snapSizes: const [0.0, 1.0],
        builder: (context, scrollController) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            ),
            child: Scaffold(
              backgroundColor: const Color(0xFF0A0A14), // Solid background
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: const Alignment(0.6, 0.8),
                    colors: [
                      secondary.withAlpha(200),
                      primary.withAlpha(120),
                      const Color(0xFF0A0A14).withAlpha(0),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
                child: CustomScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    // ── Dynamic Top Padding ────────────────────────────────────
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.paddingOf(context).top,
                      ),
                    ),

                    // ── Drag Handle ──────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(80),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),

                    // ── 1. Main player ──────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: SizedBox(
                        // Dynamically adjust height to fill the screen nicely, subtracting top padding
                        height:
                            MediaQuery.sizeOf(context).height -
                            MediaQuery.paddingOf(context).top -
                            40,
                        child: _MainPlayerSection(
                          song: song,
                          onScrollRequest: () {
                            scrollController.animateTo(
                              MediaQuery.sizeOf(context).height,
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutCubic,
                            );
                          },
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
            ),
          );
        },
      ),
    );
  }
}

// ── _MainPlayerSection ──
class _MainPlayerSection extends StatelessWidget {
  final Song song;
  final VoidCallback onScrollRequest;
  const _MainPlayerSection({required this.song, required this.onScrollRequest});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerBloc>().state;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white.withAlpha(200),
                  ),
                  onPressed: () => _showSongOptions(context, song),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Album art ────────────────────────────────────────────────────
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.maxHeight < constraints.maxWidth
                    ? constraints.maxHeight
                    : constraints.maxWidth;
                return Center(
                  child: Hero(
                    tag: 'art_${song.id}',
                    child: AlbumArtWidget(
                      size: size,
                      colorPrimary: song.colorPrimary,
                      colorSecondary: song.colorSecondary,
                      thumbnailUrl: song.thumbnailUrl,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

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
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.8,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.white.withAlpha(160),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    state.isLiked(song)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey(state.isLiked(song)),
                    size: 28,
                    color: state.isLiked(song)
                        ? const Color(0xFFEC4899)
                        : Colors.white.withAlpha(140),
                  ),
                ),
                onPressed: () =>
                    context.read<PlayerBloc>().add(ToggleLikeEvent(song)),
              ),
              IconButton(
                icon: _DownloadIcon(song: song),
                onPressed: () =>
                    context.read<PlayerBloc>().add(ToggleDownloadEvent(song)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Squiggly progress bar ────────────────────────────────────────
          SquigglyProgressBar(
            progress: state.progress,
            bufferProgress: state.bufferProgress,
            onSeek: (fraction) =>
                context.read<PlayerBloc>().add(SeekToEvent(fraction)),
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

          // ── Playback controls ────────────────────────────────────────────
          _PlaybackControls(activeColor: song.colorPrimary),
          const SizedBox(height: 12),

          // ── Queue button + scroll-down hint ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.queue_music_rounded,
                  color: Colors.white.withAlpha(160),
                  size: 28,
                ),
                tooltip: 'Queue',
                onPressed: () => QueueScreen.show(context),
              ),
              GestureDetector(
                onTap: onScrollRequest,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Column(
                    children: [
                      Text(
                        'Artist & info',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withAlpha(100),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white.withAlpha(100),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showSongOptions(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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

class _DownloadIcon extends StatelessWidget {
  final Song song;
  const _DownloadIcon({required this.song});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PlayerBloc, PlayerState, double>(
      selector: (state) => state.getDownloadProgress(song.id),
      builder: (context, progress) {
        if (progress >= 0 && progress < 1.0) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2,
                  color: Colors.greenAccent,
                  backgroundColor: Colors.white10,
                ),
              ),
              const Icon(
                Icons.downloading_rounded,
                size: 16,
                color: Colors.greenAccent,
              ),
            ],
          );
        }
        return Icon(
          song.isDownloaded
              ? Icons.download_done_rounded
              : Icons.download_for_offline_outlined,
          size: 26,
          color: song.isDownloaded
              ? Colors.greenAccent
              : Colors.white.withAlpha(140),
        );
      },
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
            color: state.isShuffle ? activeColor : Colors.white.withAlpha(160),
            size: 24,
          ),
          onPressed: () =>
              context.read<PlayerBloc>().add(const ToggleShuffleEvent()),
        ),
        IconButton(
          icon: const Icon(
            Icons.skip_previous_rounded,
            size: 48,
            color: Colors.white,
          ),
          onPressed: () =>
              context.read<PlayerBloc>().add(const SkipPreviousEvent()),
        ),
        _PlayPauseButton(),
        IconButton(
          icon: const Icon(
            Icons.skip_next_rounded,
            size: 48,
            color: Colors.white,
          ),
          onPressed: () =>
              context.read<PlayerBloc>().add(const SkipNextEvent()),
        ),
        IconButton(
          icon: Icon(
            Icons.repeat_rounded,
            color: state.isRepeat ? activeColor : Colors.white.withAlpha(160),
            size: 24,
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

class _ArtistCard extends StatelessWidget {
  final Song song;
  const _ArtistCard({required this.song});

  @override
  Widget build(BuildContext context) {
    final name = song.artist;
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();

    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withAlpha(100),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Artist',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimaryContainer,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: song.thumbnailUrl != null
                    ? Image.network(
                        song.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _ArtistInitials(initials: initials, song: song),
                      )
                    : _ArtistInitials(initials: initials, song: song),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            name,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Artist',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.white.withAlpha(140),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ArtistInitials extends StatelessWidget {
  final String initials;
  final Song song;
  const _ArtistInitials({required this.initials, required this.song});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [song.colorPrimary, song.colorSecondary],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: Colors.white.withAlpha(200),
        ),
      ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  final Song song;
  const _MetadataCard({required this.song});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About this song',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 20),
          _MetaRow(
            icon: Icons.album_rounded,
            label: 'Album',
            value: song.album.isNotEmpty ? song.album : 'Unknown Album',
          ),
          const SizedBox(height: 16),
          _MetaRow(
            icon: Icons.person_outline_rounded,
            label: 'Artist',
            value: song.artist,
          ),
          const SizedBox(height: 16),
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
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: Colors.white.withAlpha(160)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.white.withAlpha(100),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

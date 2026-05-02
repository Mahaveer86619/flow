import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/song.dart';
import '../../blocs/player/player_bloc.dart';
import '../../widgets/album_art_widget.dart';
import '../../widgets/like_button.dart';
import '../../widgets/squiggly_progress_bar.dart';
import '../queue/queue_screen.dart';
import '../../cubits/song_details/song_details_cubit.dart';
import 'package:flow/data/sources/local/download_service.dart';
import 'package:flow/core/config/app_constants.dart';

import 'package:flow/core/storage/local_storage.dart';
import '../../widgets/text_carousel.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  static Future<void> show(BuildContext context) {
    final playerBloc = context.read<PlayerBloc>();
    final detailsCubit = context.read<SongDetailsCubit>();

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      enableDrag: false,
      useRootNavigator: true,
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider<PlayerBloc>.value(value: playerBloc),
          BlocProvider<SongDetailsCubit>.value(value: detailsCubit),
        ],
        child: const PlayerScreen(),
      ),
    );
  }

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  @override
  void initState() {
    super.initState();
    _fetchDetails();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PlayerBloc>().add(const SetPlayerVisibilityEvent(true));
    });
  }

  @override
  void dispose() {
    context.read<PlayerBloc>().add(const SetPlayerVisibilityEvent(false));
    super.dispose();
  }

  void _fetchDetails() {
    final song = context.read<PlayerBloc>().state.currentSong;
    if (song != null) {
      final artistId = song.extras?['artistId'] as String?;
      context.read<SongDetailsCubit>().fetchDetails(song.id, artistId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerBloc>().state;
    final song = state.currentSong;

    if (song == null) return const SizedBox.shrink();

    return BlocListener<PlayerBloc, PlayerState>(
      listenWhen: (prev, curr) => prev.currentSong?.id != curr.currentSong?.id,
      listener: (context, state) {
        _fetchDetails();
      },
      child: NotificationListener<DraggableScrollableNotification>(
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
            final primary = state.customPrimary ?? song.colorPrimary;
            final secondary = state.customSecondary ?? song.colorSecondary;

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              ),
              child: Scaffold(
                backgroundColor: const Color(0xFF0A0A14),
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
                      SliverToBoxAdapter(
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
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: _ArtistCard(song: song),
                        ),
                      ),
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
                      TextCarousel(
                        text: song.title,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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

                String? thumbUrl = song.thumbnailUrl;
                final metadata = LocalStorage.instance.getDownloadMetadata(
                  song.id,
                );
                if (metadata != null && metadata['thumbnailUrl'] != null) {
                  thumbUrl = metadata['thumbnailUrl'] as String;
                }

                return Center(
                  child: Hero(
                    tag: 'active_art_${song.id}',
                    child: AlbumArtWidget(
                      size: size,
                      colorPrimary: song.colorPrimary,
                      colorSecondary: song.colorSecondary,
                      thumbnailUrl: thumbUrl,
                      borderRadius: 10,
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
                        color: Colors.white.withAlpha(160),
                      ),
                    ),
                  ],
                ),
              ),
              LikeButton(
                isLiked: state.isLiked(song),
                onTap: () =>
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
            isInitialLoading: state.isInitialLoading,
            isBuffering: state.isBuffering,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
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

class _DownloadIcon extends StatelessWidget {
  final Song song;
  const _DownloadIcon({required this.song});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PlayerBloc, PlayerState, double>(
      selector: (state) => state.getDownloadProgress(song.id),
      builder: (context, progress) {
        bool isDownloaded = false;
        try {
          isDownloaded = DownloadService.instance.isDownloadedSync(song.id);
        } catch (_) {
          // Fallback for tests where DownloadService is not initialised
        }

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
          isDownloaded
              ? Icons.download_done_rounded
              : Icons.download_for_offline_outlined,
          size: 26,
          color: isDownloaded
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
    final detailsState = context.watch<SongDetailsCubit>().state;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ARTIST',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withAlpha(100),
                  letterSpacing: 1.5,
                ),
              ),
              if (detailsState.artistThumbnail != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(40),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Official',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 120,
              height: 120,
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
                child: detailsState.artistThumbnail != null
                    ? Image.network(
                        detailsState.artistThumbnail!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _ArtistInitials(initials: initials, song: song),
                      )
                    : (song.thumbnailUrl != null
                          ? Image.network(
                              song.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _ArtistInitials(
                                    initials: initials,
                                    song: song,
                                  ),
                            )
                          : _ArtistInitials(initials: initials, song: song)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            name,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (detailsState.biography != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                detailsState.biography!,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.white.withAlpha(180),
                  height: 1.5,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
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
          fontSize: 42,
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
    final detailsState = context.watch<SongDetailsCubit>().state;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRACK INFO',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white.withAlpha(100),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          if (detailsState.songDescription != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                detailsState.songDescription!,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.white.withAlpha(180),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _InfoChip(
                label: 'ALBUM',
                value: song.album.isNotEmpty ? song.album : 'Single',
                icon: Icons.album_rounded,
              ),
              _InfoChip(
                label: 'DURATION',
                value: _formatDuration(song.duration),
                icon: Icons.timer_outlined,
              ),
              if (song.extras?['year'] != null)
                _InfoChip(
                  label: 'RELEASED',
                  value: song.extras!['year'].toString(),
                  icon: Icons.calendar_today_rounded,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _MetaRow(
            icon: Icons.person_outline_rounded,
            label: 'Artist',
            value: song.artist,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10, color: Colors.white.withAlpha(100)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withAlpha(100),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
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

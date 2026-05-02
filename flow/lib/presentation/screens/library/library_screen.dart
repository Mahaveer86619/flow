import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/repositories/music_repository.dart';
import '../../cubits/library/library_cubit.dart';
import '../../widgets/error_view.dart';
import '../../widgets/section_header.dart';
import '../playlist/playlist_screen.dart';
import '../settings/settings_screen.dart';
import '../list/list_screen.dart';
import '../../widgets/skeleton.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/ui/app_snack_bar.dart';
import '../../widgets/flow_app_bar.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final columns = screenWidth > 1200 ? 5 : (screenWidth > 800 ? 3 : 2);
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () => context.read<LibraryCubit>().refresh(),
      backgroundColor: colorScheme.surfaceContainerHigh,
      color: colorScheme.primary,
      edgeOffset: 100, // Start below the app bar
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          FlowAppBar(
            title: 'Library',
            additionalActions: [
              IconButton(
                icon: const Icon(Icons.add_rounded),
                onPressed: () async {
                  final controller = TextEditingController();
                  final name = await showDialog<String>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Create Playlist'),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: 'Playlist Name',
                          border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                        onSubmitted: (value) => Navigator.pop(ctx, value),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, controller.text),
                          child: const Text('Create'),
                        ),
                      ],
                    ),
                  );
                  if (name?.trim().isNotEmpty ?? false) {
                    try {
                      final repo = context.read<MusicRepository>();
                      await repo.createFlowPlaylist(title: name!.trim());
                      if (context.mounted) {
                        context.read<LibraryCubit>().refresh();
                      }
                    } catch (e, st) {
                      if (context.mounted) {
                        AppSnackBar.showError(
                          context,
                          e,
                          stackTrace: st,
                          logTag: 'LibraryScreen',
                        );
                      }
                    }
                  }
                },
                tooltip: 'Create Playlist',
              ),
            ],
          ),

          BlocBuilder<LibraryCubit, LibraryState>(
            builder: (context, state) {
              if (state.isLoading && state.playlists.isEmpty) {
                return SliverMainAxisGroup(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Skeleton(height: 80, borderRadius: 20),
                            SizedBox(height: 12),
                            Skeleton(height: 80, borderRadius: 20),
                            SizedBox(height: 12),
                            Skeleton(height: 80, borderRadius: 20),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 32, 16, 16),
                        child: SkeletonText(width: 140, height: 20),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.82,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => const SkeletonPlaylistCard(),
                          childCount: 6,
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (state.error && state.playlists.isEmpty) {
                return SliverFillRemaining(
                  child: ErrorView(
                    errorType: state.errorType,
                    onRetry: () => context.read<LibraryCubit>().reload(),
                  ),
                );
              }

              return SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LibraryShortcuts(state: state),
                    const SizedBox(height: 24),
                    if (state.playlists.any((p) => p.type == 'flow'))
                      const SectionHeader(title: 'My Playlists'),
                  ],
                ),
              );
            },
          ),

          BlocBuilder<LibraryCubit, LibraryState>(
            builder: (context, state) {
              if (state.playlists.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final pl = state.playlists[i];
                    return _LibraryPlaylistCard(
                      title: pl.name,
                      subtitle: pl.description,
                      imageUrl: pl.thumbnailUrl,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaylistScreen(playlist: pl),
                        ),
                      ),
                    );
                  }, childCount: state.playlists.length),
                ),
              );
            },
          ),

          // Remote Playlists section header
          BlocBuilder<LibraryCubit, LibraryState>(
            builder: (context, state) {
              if (state.playlists.isEmpty ||
                  !state.playlists.any((p) => p.type != 'flow')) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: SectionHeader(title: 'Remote Playlists'),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

class _LibraryShortcuts extends StatelessWidget {
  final LibraryState state;
  const _LibraryShortcuts({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _LibraryChip(
            title: 'Downloads',
            icon: Icons.download_done_rounded,
            color: const Color(0xFF10B981),
            onTap: () => _openSongList(
              context,
              'Downloaded',
              state.downloadedSongs,
              ListCategory.downloaded,
            ),
          ),
          const SizedBox(width: 12),
          _LibraryChip(
            title: 'Favorites',
            icon: Icons.favorite_rounded,
            color: const Color(0xFFEC4899),
            onTap: () => _openSongList(
              context,
              'Flow Favourites',
              state.likedSongs,
              ListCategory.favourites,
            ),
          ),
          const SizedBox(width: 12),
          _LibraryChip(
            title: 'YT Liked',
            icon: Icons.subscriptions_rounded,
            color: const Color(0xFFFF0000),
            onTap: () => _openSongList(
              context,
              'YouTube Likes',
              state.remoteLikedSongs,
              ListCategory.youtubeLikes,
            ),
          ),
        ],
      ),
    );
  }

  void _openSongList(
    BuildContext context,
    String title,
    List<Song> songs,
    ListCategory category,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ListScreen(title: title, initialSongs: songs, category: category),
      ),
    );
  }
}

class _LibraryChip extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _LibraryChip({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh.withAlpha(180),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant.withAlpha(30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryPlaylistCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback onTap;

  const _LibraryPlaylistCard({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.fill,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: imageUrl == null
                  ? Center(
                      child: Icon(
                        Icons.playlist_play_rounded,
                        size: 40,
                        color: cs.onSurface.withAlpha(40),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withAlpha(120),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

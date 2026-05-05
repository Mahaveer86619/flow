import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/repositories/music_repository.dart';
import '../../cubits/library/library_cubit.dart';
import '../../widgets/error_view.dart';
import '../../widgets/section_header.dart';
import '../playlist/playlist_screen.dart';
import '../list/list_screen.dart';
import '../../widgets/skeleton.dart';
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

    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context.read<LibraryCubit>().refresh(),
          backgroundColor: colorScheme.surfaceContainerHigh,
          color: colorScheme.primary,
          edgeOffset: 100,
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
                    onPressed: () => _showCreatePlaylistDialog(context),
                    tooltip: 'Create Playlist',
                  ),
                ],
              ),

              if (state.isLoading && state.playlists.isEmpty)
                _buildShimmerLoading(columns)
              else if (state.error && state.playlists.isEmpty)
                SliverFillRemaining(
                  child: ErrorView(
                    errorType: state.errorType,
                    onRetry: () => context.read<LibraryCubit>().reload(),
                  ),
                )
              else ...[
                // Shortcuts (Grid style)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.2,
                    ),
                    delegate: SliverChildListDelegate([
                      _buildQuickAction(
                        context,
                        'Favourites',
                        Icons.favorite_rounded,
                        const Color(0xFFEC4899),
                        () => _openSongList(
                          context,
                          'Favourites',
                          state.likedSongs,
                          ListCategory.favourites,
                        ),
                      ),
                      _buildQuickAction(
                        context,
                        'Downloads',
                        Icons.download_done_rounded,
                        const Color(0xFF10B981),
                        () => _openSongList(
                          context,
                          'Downloads',
                          state.downloadedSongs,
                          ListCategory.downloaded,
                        ),
                      ),
                    ]),
                  ),
                ),

                // Playlists
                if (state.playlists.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Your Playlists',
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.78,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final pl = state.playlists[index];
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
                        },
                        childCount: state.playlists.length,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerLoading(int columns) {
    return SliverMainAxisGroup(
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Column(
              children: [
                Skeleton(height: 80, borderRadius: 20),
                SizedBox(height: 12),
                Skeleton(height: 80, borderRadius: 20),
              ],
            ),
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

  Widget _buildQuickAction(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(40), width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color.withAlpha(200),
              ),
            ),
          ],
        ),
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
        builder: (_) => ListScreen(
          title: title,
          initialSongs: songs,
          category: category,
        ),
      ),
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
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
                        fit: BoxFit.cover,
                      )
                    : null,
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

// ─────────────────────────────────────────────────────────────────────────────
// SearchScreen — search bar + category grid / results / recent searches.
//
// States:
//   - Idle (not focused, no query)  → Browse Categories grid
//   - Focused + no query            → Recent Searches list
//   - Has query + results           → Results list
//   - Has query + no results        → Empty state message
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../domain/entities/song.dart';
import '../../blocs/player/player_bloc.dart';
import '../../cubits/search/search_cubit.dart';
import '../../widgets/error_view.dart';
import '../../widgets/section_header.dart';
import '../player/player_screen.dart';
import '../settings/settings_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSmall = Breakpoints.isMobile(MediaQuery.sizeOf(context).width);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverAppBar(
          expandedHeight: 140,
          floating: true,
          pinned: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.paddingOf(context).top + 12,
                    16,
                    0,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Search',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: BlocBuilder<SearchCubit, SearchState>(
                    buildWhen: (prev, curr) => prev.hasQuery != curr.hasQuery,
                    builder: (context, state) => SearchBar(
                      controller: _textController,
                      focusNode: _focusNode,
                      hintText: 'Songs, artists, albums...',
                      hintStyle: WidgetStatePropertyAll(
                        TextStyle(
                          color: colorScheme.onSurface.withAlpha(100),
                          fontSize: 15,
                        ),
                      ),
                      leading: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(
                          Icons.search_rounded,
                          color: colorScheme.primary,
                        ),
                      ),
                      trailing: [
                        if (state.hasQuery)
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _textController.clear();
                              context.read<SearchCubit>().clearQuery();
                            },
                          ),
                      ],
                      onChanged: (v) =>
                          context.read<SearchCubit>().updateQuery(v),
                      onSubmitted: (v) {
                        if (v.isNotEmpty) {
                          context.read<SearchCubit>().addRecentSearch(v);
                        }
                      },
                      elevation: const WidgetStatePropertyAll(0),
                      backgroundColor: WidgetStatePropertyAll(
                        colorScheme.surfaceContainerHigh.withAlpha(180),
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Content: recent / results / empty / categories ────────────────────
        BlocBuilder<SearchCubit, SearchState>(
          builder: (context, state) {
            final showRecent =
                _isFocused &&
                !state.hasQuery &&
                state.recentSearches.isNotEmpty;

            if (showRecent) {
              return SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Searches',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: isSmall ? 14.0 : 16.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context
                                .read<SearchCubit>()
                                .clearRecentSearches(),
                            child: Text(
                              'Clear all',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, i) {
                      final query = state.recentSearches[i];
                      return ListTile(
                        leading: Icon(
                          Icons.history_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        title: Text(query),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => context
                              .read<SearchCubit>()
                              .removeRecentSearch(query),
                        ),
                        onTap: () {
                          _textController.text = query;
                          context.read<SearchCubit>().updateQuery(query);
                        },
                      );
                    }, childCount: state.recentSearches.length),
                  ),
                ],
              );
            } else if (state.isLoading) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (state.error && state.hasQuery) {
              return SliverFillRemaining(
                child: InlineErrorView(
                  errorType: state.errorType,
                  onRetry: () =>
                      context.read<SearchCubit>().updateQuery(state.query),
                ),
              );
            } else if (state.hasQuery && state.results.isNotEmpty) {
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => RepaintBoundary(
                    child: _ResultTile(
                      song: state.results[i],
                      allResults: state.results,
                      index: i,
                    ),
                  ),
                  childCount: state.results.length,
                ),
              );
            } else if (state.hasQuery && state.results.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 64),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 52,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No results for "${state.query}"',
                        style: GoogleFonts.outfit(
                          color: colorScheme.outline,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return SliverMainAxisGroup(
                slivers: [
                  const SliverToBoxAdapter(
                    child: SectionHeader(title: 'Browse Categories'),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.7,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => RepaintBoundary(
                          child: _CategoryTile(
                            name: state.categories[i]['name'] as String,
                            color: state.categories[i]['color'] as Color,
                            onTap: () {
                              final name =
                                  state.categories[i]['name'] as String;
                              _textController.text = name;
                              context
                                  .read<SearchCubit>()
                                  .updateQueryWithCategory(name);
                            },
                          ),
                        ),
                        childCount: state.categories.length,
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result tile
// ─────────────────────────────────────────────────────────────────────────────

class _ResultTile extends StatelessWidget {
  final Song song;
  final List<Song> allResults;
  final int index;
  const _ResultTile({
    required this.song,
    required this.allResults,
    required this.index,
  });

  Widget _songArtFallback(Song s) => AspectRatio(
    aspectRatio: 16 / 9,
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [s.colorPrimary, s.colorSecondary]),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
        size: 22,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SizedBox(
        width: 100, // 16:9 ratio
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: song.thumbnailUrl != null
              ? AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    song.thumbnailUrl!,
                    fit: BoxFit.cover,
                    cacheWidth: 320,
                    cacheHeight: 180,
                    errorBuilder: (_, __, ___) => _songArtFallback(song),
                  ),
                )
              : _songArtFallback(song),
        ),
      ),
      title: Text(
        song.title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${song.artist} • ${song.album}',
        style: GoogleFonts.outfit(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.play_circle_outline_rounded,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
        onPressed: () {
          context.read<PlayerBloc>().add(
            PlayQueueEvent(
              songs: List<Song>.from(allResults),
              startIndex: index,
            ),
          );
          if (!Breakpoints.isDesktop(MediaQuery.sizeOf(context).width)) {
            PlayerScreen.show(context);
          }
        },
      ),
      onTap: () {
        context.read<PlayerBloc>().add(
          PlayQueueEvent(songs: List<Song>.from(allResults), startIndex: index),
        );
        if (!Breakpoints.isDesktop(MediaQuery.sizeOf(context).width)) {
          PlayerScreen.show(context);
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category tile
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final String name;
  final Color color;
  final VoidCallback onTap;
  const _CategoryTile({
    required this.name,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withAlpha(180)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(40),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -15,
              bottom: -15,
              child: Transform.rotate(
                angle: 0.2,
                child: Icon(
                  Icons.music_note_rounded,
                  size: 72,
                  color: Colors.white.withAlpha(30),
                ),
              ),
            ),
            Text(
              name,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

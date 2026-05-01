// ─────────────────────────────────────────────────────────────────────────────
// SearchScreen — search bar + recent history / results / categories.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../cubits/search/search_cubit.dart';
import '../../widgets/error_view.dart';
import '../../widgets/song_tile.dart';
import '../../widgets/skeleton.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _showAllHistory = false;

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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: colorScheme.onSurface,
              ),
              onPressed: () => Navigator.maybePop(context),
            ),
            centerTitle: false,
            title: Text(
              'Search',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: colorScheme.onSurface,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                children: [
                  const SizedBox(height: 80),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: BlocBuilder<SearchCubit, SearchState>(
                      builder: (context, state) => SearchBar(
                        controller: _textController,
                        focusNode: _focusNode,
                        hintText: 'Songs, artists, albums...',
                        hintStyle: WidgetStatePropertyAll(
                          TextStyle(
                            color: colorScheme.onSurface.withAlpha(80),
                            fontSize: 15,
                          ),
                        ),
                        leading: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(
                            Icons.search_rounded,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        trailing: [
                          if (state.hasQuery)
                            IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: colorScheme.onSurface,
                              ),
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
                          colorScheme.onSurface.withAlpha(20),
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

          // ── Content ────────────────────
          BlocBuilder<SearchCubit, SearchState>(
            builder: (context, state) {
              if (state.isLoading) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => const SkeletonSongTile(),
                    childCount: 10,
                  ),
                );
              }

              if (state.hasQuery) {
                if (state.results.isNotEmpty) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => SongTile(
                        song: state.results[i],
                        queue: state.results,
                        index: i,
                        startRadio: true,
                        skipPlayerScreen: true,
                      ),
                      childCount: state.results.length,
                    ),
                  );
                } else if (!state.error) {
                  return _buildNoResults(state.query);
                } else {
                  return SliverFillRemaining(
                    child: InlineErrorView(
                      errorType: state.errorType,
                      onRetry: () =>
                          context.read<SearchCubit>().updateQuery(state.query),
                    ),
                  );
                }
              }

              // Idle state: Recent History + Categories
              return SliverMainAxisGroup(
                slivers: [
                  if (state.recentSearches.isNotEmpty) ...[
                    _buildHistoryHeader(context),
                    _buildHistoryList(state),
                  ],
                  _buildCategoryHeader(),
                  _buildCategoryGrid(state),
                ],
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 140)),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent History',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: () =>
                  context.read<SearchCubit>().clearRecentSearches(),
              child: Text(
                'Clear',
                style: TextStyle(
                  color: colorScheme.onSurface.withAlpha(150),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(SearchState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final history = state.recentSearches;
    final displayCount = _showAllHistory
        ? history.length
        : (history.length > 10 ? 10 : history.length);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          if (i == displayCount) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: () => setState(() => _showAllHistory = true),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.expand_more_rounded,
                        size: 20,
                        color: colorScheme.onSurface.withAlpha(150),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Load more',
                        style: GoogleFonts.outfit(
                          color: colorScheme.onSurface.withAlpha(150),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          final query = history[i];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(
              Icons.history_rounded,
              color: colorScheme.onSurface.withAlpha(80),
              size: 22,
            ),
            title: Text(
              query,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withAlpha(180),
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: colorScheme.onSurface.withAlpha(60),
              ),
              onPressed: () =>
                  context.read<SearchCubit>().removeRecentSearch(query),
            ),
            onTap: () {
              _textController.text = query;
              context.read<SearchCubit>().updateQuery(query);
            },
          );
        },
        childCount:
            displayCount + (!_showAllHistory && history.length > 10 ? 1 : 0),
      ),
    );
  }

  Widget _buildCategoryHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Text(
          'Browse Categories',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(SearchState state) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
        ),
        delegate: SliverChildBuilderDelegate((context, i) {
          final cat = state.categories[i];
          final name = cat['name'] as String;
          final colorInt = cat['color'] as int?;
          final color = colorInt != null ? Color(colorInt) : Colors.blueGrey;
          return _CategoryTile(
            name: name,
            color: color,
            onTap: () {
              _textController.text = name;
              context.read<SearchCubit>().updateQueryWithCategory(name);
            },
          );
        }, childCount: state.categories.length),
      ),
    );
  }

  Widget _buildNoResults(String query) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: colorScheme.onSurface.withAlpha(20),
            ),
            const SizedBox(height: 16),
            Text(
              'No results for "$query"',
              style: GoogleFonts.outfit(
                color: colorScheme.onSurface.withAlpha(100),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50), width: 1),
        ),
        child: Center(
          child: Text(
            name,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
            ),
          ),
        ),
      ),
    );
  }
}

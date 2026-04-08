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
import '../../../core/responsive/breakpoints.dart';
import '../../../domain/entities/song.dart';
import '../../blocs/player/player_bloc.dart';
import '../../cubits/search/search_cubit.dart';
import '../player/player_screen.dart';

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
    final state = context.watch<SearchCubit>().state;
    final colorScheme = Theme.of(context).colorScheme;
    final isSmall = Breakpoints.isMobile(MediaQuery.sizeOf(context).width);

    final showRecent =
        _isFocused && !state.hasQuery && state.recentSearches.isNotEmpty;

    return CustomScrollView(
      slivers: [
        // ── Search bar ────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: SearchBar(
              controller: _textController,
              focusNode: _focusNode,
              hintText: 'Songs, artists, albums...',
              leading: Icon(
                Icons.search_rounded,
                color: colorScheme.onSurfaceVariant,
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
              onChanged: (v) => context.read<SearchCubit>().updateQuery(v),
              onSubmitted: (v) {
                if (v.isNotEmpty) {
                  context.read<SearchCubit>().addRecentSearch(v);
                }
              },
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(
                colorScheme.surfaceContainerHigh,
              ),
            ),
          ),
        ),

        // ── Content: recent / results / empty / categories ────────────────────
        if (showRecent) ...[
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
                    onPressed: () =>
                        context.read<SearchCubit>().clearRecentSearches(),
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
                  onPressed: () =>
                      context.read<SearchCubit>().removeRecentSearch(query),
                ),
                onTap: () {
                  _textController.text = query;
                  context.read<SearchCubit>().updateQuery(query);
                },
              );
            }, childCount: state.recentSearches.length),
          ),
        ] else if (state.hasQuery && state.results.isNotEmpty) ...[
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _ResultTile(
                song: state.results[i],
                allResults: state.results,
                index: i,
              ),
              childCount: state.results.length,
            ),
          ),
        ] else if (state.hasQuery && state.results.isEmpty) ...[
          SliverToBoxAdapter(
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
          ),
        ] else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                'Browse Categories',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: isSmall ? 15.0 : 18.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _CategoryTile(
                  name: state.categories[i]['name'] as String,
                  color: state.categories[i]['color'] as Color,
                ),
                childCount: state.categories.length,
              ),
            ),
          ),
        ],

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

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [song.colorPrimary, song.colorSecondary],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.music_note_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
      title: Text(
        song.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${song.artist} • ${song.album}'),
      trailing: Icon(
        Icons.play_circle_outline_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      onTap: () {
        context.read<PlayerBloc>().add(
          PlayQueueEvent(
            songs: List<Song>.from(allResults),
            startIndex: index,
          ),
        );
        if (!Breakpoints.isDesktop(MediaQuery.sizeOf(context).width)) {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
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
  const _CategoryTile({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: -12,
            child: Icon(
              Icons.music_note_rounded,
              size: 64,
              color: Colors.white.withAlpha(35),
            ),
          ),
          Text(
            name,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

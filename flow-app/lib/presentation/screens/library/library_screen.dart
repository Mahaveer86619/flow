import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../domain/entities/song.dart';
import '../../blocs/player/player_bloc.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/library/library_cubit.dart';
import '../../widgets/error_view.dart';
import '../auth/auth_screen.dart';
import '../playlist/playlist_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LibraryCubit>().state;
    final likedCount = context.watch<PlayerBloc>().state.likedSongsCount;
    final colorScheme = Theme.of(context).colorScheme;
    final isSmall = Breakpoints.isMobile(MediaQuery.sizeOf(context).width);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 4, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Library',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: isSmall ? 16.0 : 20.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () {},
                  tooltip: 'Create playlist',
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: List.generate(LibraryState.filterOptions.length, (i) {
                final selected = state.filterIndex == i;
                return Padding(
                  padding: EdgeInsets.only(
                    right: i < LibraryState.filterOptions.length - 1 ? 8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () =>
                        context.read<LibraryCubit>().setFilter(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        LibraryState.filterOptions[i],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: selected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        if (state.isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
        if (state.error && state.errorType == AppErrorType.unauthenticated)
          SliverFillRemaining(
            child: _LibrarySignInPrompt(
              onSignIn: () {
                final authCubit = context.read<AuthCubit>();
                Navigator.of(context)
                    .push<bool>(MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: authCubit,
                        child: AuthScreen(
                          onSubmitHeaders: (h) => authCubit.submitHeaders(h),
                        ),
                      ),
                    ))
                    .then((success) {
                      if (success == true && context.mounted) {
                        context.read<LibraryCubit>().reload();
                      }
                    });
              },
            ),
          ),
        if (state.error && state.errorType != AppErrorType.unauthenticated)
          SliverFillRemaining(
            child: ErrorView(
              errorType: state.errorType,
              onRetry: () => context.read<LibraryCubit>().reload(),
            ),
          ),
        if (!state.isLoading && !state.error) ...[
        SliverToBoxAdapter(
          child: _SpecialPlaylistTile(
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFFEC4899),
            name: 'Liked Songs',
            subtitle: '$likedCount songs',
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => _PlaylistTile(playlist: state.playlists[i]),
            childCount: state.playlists.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ], // end !isLoading && !error
      ],
    );
  }
}

class _PlaylistArtFallback extends StatelessWidget {
  final Playlist playlist;
  const _PlaylistArtFallback({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      color: playlist.color,
      child: const Icon(Icons.queue_music_rounded, color: Colors.white, size: 28),
    );
  }
}

class _SpecialPlaylistTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String subtitle;
  const _SpecialPlaylistTile({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: iconColor.withAlpha(35),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 28),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {},
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  const _PlaylistTile({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: playlist.thumbnailUrl != null
            ? Image.network(
                playlist.thumbnailUrl!,
                width: 58,
                height: 58,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _PlaylistArtFallback(playlist: playlist),
              )
            : _PlaylistArtFallback(playlist: playlist),
      ),
      title: Text(
        playlist.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(playlist.description),
      trailing: IconButton(
        icon: Icon(
          Icons.more_vert_rounded,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
        ),
        onPressed: () {},
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlaylistScreen(playlist: playlist),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign-in prompt — full-screen centre, shown when library needs auth
// ─────────────────────────────────────────────────────────────────────────────

class _LibrarySignInPrompt extends StatelessWidget {
  final VoidCallback onSignIn;
  const _LibrarySignInPrompt({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.library_music_outlined,
              size: 64,
              color: colorScheme.onSurface.withAlpha(80),
            ),
            const SizedBox(height: 20),
            Text(
              'Sign in to see your library',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your playlists, liked songs, and albums live here.',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withAlpha(150),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onSignIn,
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('Sign in'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

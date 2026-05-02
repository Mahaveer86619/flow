import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/list/list_screen.dart';
import '../../core/storage/local_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/player/player_bloc.dart';

class FlowAppBar extends StatelessWidget {
  final String title;
  final bool pinned;
  final bool floating;
  final double expandedHeight;
  final List<Widget>? additionalActions;

  const FlowAppBar({
    super.key,
    required this.title,
    this.pinned = true,
    this.floating = false,
    this.expandedHeight = 100,
    this.additionalActions,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: floating,
      pinned: pinned,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      title: LayoutBuilder(
        builder: (context, constraints) {
          final top = constraints.biggest.height;
          final isCollapsed = top < (expandedHeight - 10);
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isCollapsed ? 1.0 : 0.0,
            child: Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          );
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.paddingOf(context).top + 12,
            16,
            0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
              const Spacer(),
              if (additionalActions != null) ...additionalActions!,
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () {
                  // TODO: Implement notifications screen
                },
                tooltip: 'Notifications',
              ),
              IconButton(
                icon: const Icon(Icons.history_rounded),
                onPressed: () {
                  final recent = context.read<PlayerBloc>().state.recentlyPlayed;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ListScreen(
                        title: 'Recently Played',
                        initialSongs: recent,
                        category: ListCategory.recentlyPlayed,
                      ),
                    ),
                  );
                },
                tooltip: 'Recently Played',
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
                tooltip: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

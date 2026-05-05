import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

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
    this.expandedHeight = 110,
    this.additionalActions,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: floating,
      pinned: pinned,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      actions: [
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
          onPressed: () => context.push('/history'),
          tooltip: 'Recently Played',
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push('/settings'),
          tooltip: 'Settings',
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(
          start: 16,
          bottom: 16,
        ),
        centerTitle: false,
        expandedTitleScale: 1.6,
        title: Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

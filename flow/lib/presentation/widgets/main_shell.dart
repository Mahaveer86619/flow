import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/platform/desktop_controller.dart';
import '../blocs/player/player_bloc.dart';
import 'mini_player.dart';

class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({
    super.key,
    required this.child,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final int currentIndex = _calculateSelectedIndex(location);

    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (prev, curr) => prev.isPlayerOpen != curr.isPlayerOpen,
      builder: (context, state) {
        final bool showBottomUI = !state.isPlayerOpen;

        return ValueListenableBuilder<bool>(
          valueListenable: DesktopController.instance.isMiniNotifier,
          builder: (context, isMini, _) {
            if (isMini) return widget.child; // Desktop mini player handled elsewhere

            final padding = MediaQuery.paddingOf(context);

            return Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  Positioned.fill(
                    child: widget.child,
                  ),

                  if (showBottomUI)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const MiniPlayer(),
                          ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                              child: Container(
                                height: 64 + padding.bottom,
                                padding: EdgeInsets.only(bottom: padding.bottom),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(200),
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.white.withAlpha(20),
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _BottomTabItem(
                                      icon: Icons.home_rounded,
                                      label: 'Home',
                                      isActive: currentIndex == 0,
                                      onTap: () => context.go('/'),
                                    ),
                                    _BottomTabItem(
                                      icon: Icons.search_rounded,
                                      label: 'Search',
                                      isActive: currentIndex == 1,
                                      onTap: () => context.go('/search'),
                                    ),
                                    _BottomTabItem(
                                      icon: Icons.library_music_rounded,
                                      label: 'Library',
                                      isActive: currentIndex == 2,
                                      onTap: () => context.go('/library'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  int _calculateSelectedIndex(String location) {
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/library')) return 2;
    return 0;
  }
}

class _BottomTabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomTabItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? cs.primary : Colors.white.withAlpha(120),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? cs.primary : Colors.white.withAlpha(120),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

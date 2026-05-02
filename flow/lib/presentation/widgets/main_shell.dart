import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/platform/desktop_controller.dart';
import '../../core/app_event_bus.dart';
import '../screens/home/home_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/library/library_screen.dart';
import 'mini_player.dart';
import 'desktop_mini_player.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  StreamSubscription? _eventSub;

  @override
  void initState() {
    super.initState();
    _eventSub = AppEventBus.instance.events.listen((event) {
      if (event is SwitchTabEvent) {
        setState(() => _currentIndex = event.index);
      }
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (prev, curr) => prev.isPlayerOpen != curr.isPlayerOpen,
      builder: (context, state) {
        final bool showBottomUI = !state.isPlayerOpen;

        return ValueListenableBuilder<bool>(
          valueListenable: DesktopController.instance.isMiniNotifier,
          builder: (context, isMini, _) {
            if (isMini) return const DesktopMiniPlayer();

            final cs = Theme.of(context).colorScheme;
            final padding = MediaQuery.paddingOf(context);

            return Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  // Content with Nested Navigators
                  Positioned.fill(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: [
                        _buildTabNav(0, const HomeScreen()),
                        _buildTabNav(1, const SearchScreen()),
                        _buildTabNav(2, const LibraryScreen()),
                      ],
                    ),
                  ),

                  // Persistent Bottom UI
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
                                      isActive: _currentIndex == 0,
                                      onTap: () => _onTabTapped(0),
                                    ),
                                    _BottomTabItem(
                                      icon: Icons.search_rounded,
                                      label: 'Search',
                                      isActive: _currentIndex == 1,
                                      onTap: () => _onTabTapped(1),
                                    ),
                                    _BottomTabItem(
                                      icon: Icons.library_music_rounded,
                                      label: 'Library',
                                      isActive: _currentIndex == 2,
                                      onTap: () => _onTabTapped(2),
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

  Widget _buildTabNav(int index, Widget root) {
    return Navigator(
      key: PageStorageKey('tab_$index'),
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (_) => root,
        settings: settings,
      ),
    );
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
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

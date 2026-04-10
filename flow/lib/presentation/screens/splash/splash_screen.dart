import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../auth/login_screen.dart';
import '../main/desktop_shell.dart';
import '../main/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _subtitleFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );

    _scaleAnim = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    );

    _controller.forward().then((_) async {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      // Wait for AuthCubit to finish initialising (it starts with isLoading: true).
      final authCubit = context.read<AuthCubit>();
      AuthState authState = authCubit.state;
      if (authState.isLoading) {
        authState = await authCubit.stream.firstWhere((s) => !s.isLoading);
      }
      if (!mounted) return;
      final Widget destination = authState.isAuthenticated
          ? const _RootShell()
          : const LoginScreen();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondary) => destination,
          transitionsBuilder: (context, anim, secondary, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070F),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: _fadeAnim.value,
                  child: Transform.scale(
                    scale: _scaleAnim.value,
                    child: Text(
                      'flow',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 80,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -5,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Opacity(
                  opacity: _subtitleFade.value,
                  child: Text(
                    'music flows through you',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withAlpha(110),
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RootShell — picks the correct layout shell based on screen size.
//
// This is the first real screen after the splash; it is never popped off the
// navigator stack. Resize the window on desktop and the shell switches live.
// ─────────────────────────────────────────────────────────────────────────────

class _RootShell extends StatelessWidget {
  const _RootShell();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (prev, curr) =>
          prev.isAuthenticated && !curr.isAuthenticated && !curr.isLoading,
      listener: (context, _) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const LoginScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
          (_) => false,
        );
      },
      child: ResponsiveLayout(
        mobile: (_) => const MainScreen(),
        desktop: (_) => const DesktopShell(),
      ),
    );
  }
}

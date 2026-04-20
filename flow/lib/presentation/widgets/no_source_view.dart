import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/auth/auth_cubit.dart';
import '../screens/settings/settings_screen.dart';

class NoSourceView extends StatelessWidget {
  const NoSourceView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isAuth = context.watch<AuthCubit>().state.isAuthenticated;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: cs.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAuth ? Icons.feed_outlined : Icons.account_circle_outlined,
                size: 40,
                color: cs.primary.withAlpha(180),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isAuth ? 'Personalized Feed Unavailable' : 'Not signed in',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isAuth
                  ? 'Your personalized home feed is currently empty. Connect your YouTube Music account in settings to see your recommendations.'
                  : 'Sign in to access your music library and personalized recommendations.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: cs.onSurface.withAlpha(140),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              icon: const Icon(Icons.account_tree_outlined, size: 18),
              label: Text(isAuth ? 'Configure Source' : 'Go to Settings'),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

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
                color: cs.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAuth ? Icons.link_off_rounded : Icons.account_circle_outlined,
                size: 40,
                color: cs.onSurface.withAlpha(80),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isAuth ? 'No source connected' : 'Not signed in',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isAuth
                  ? 'Connect your YouTube Music account to get a personalised feed.'
                  : 'Sign in or set up a self-hosted server to access your music.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: cs.onSurface.withAlpha(140),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: Text(isAuth ? 'Connect a source' : 'Go to Settings'),
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

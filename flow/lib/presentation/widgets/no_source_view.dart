import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/settings/settings_screen.dart';

class NoSourceView extends StatelessWidget {
  const NoSourceView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                Icons.link_off_rounded,
                size: 40,
                color: cs.onSurface.withAlpha(80),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No source connected',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Connect your YouTube Music account to get a personalised feed.',
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
              label: const Text('Connect a source'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

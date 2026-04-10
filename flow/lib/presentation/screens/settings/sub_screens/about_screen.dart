import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'About Flow',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(28),
              ),
              alignment: Alignment.center,
              child: Text(
                'f',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: cs.onPrimaryContainer,
                  letterSpacing: -3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'flow',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Version 1.0.0',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: cs.outline,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'A self-hosted music streaming client\npowered by YouTube Music.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: cs.onSurface.withAlpha(180),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _InfoRow(label: 'Built with', value: 'Flutter + BLoC'),
          _InfoRow(label: 'Backend', value: 'FastAPI + ytmusicapi + yt-dlp'),
          _InfoRow(label: 'Audio', value: 'just_audio'),
          _InfoRow(label: 'Developer', value: 'Mahaveer'),
          const SizedBox(height: 32),
          Divider(color: cs.outlineVariant.withAlpha(60)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Streams music via your own server.\nNo data is sent to third-party services.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: cs.outline,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.outfit(color: cs.outline, fontSize: 14)),
          Text(value,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }
}

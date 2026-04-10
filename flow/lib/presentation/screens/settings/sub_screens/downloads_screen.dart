import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../presentation/cubits/settings/settings_cubit.dart';

const _kQualities = ['Low (128 kbps)', 'Medium (192 kbps)', 'High (320 kbps)'];

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.watch<SettingsCubit>();
    final currentQuality = cubit.state.downloadQuality;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Downloads',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: cs.outline),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Offline downloads are coming soon. '
                    'Quality preference will apply when the feature is available.',
                    style: GoogleFonts.outfit(fontSize: 13, color: cs.outline),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Download Quality',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 1.1,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 12),
          ..._kQualities.map((q) {
            final label = q.split(' ').first; // "Low", "Medium", "High"
            final selected = currentQuality == label;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: selected ? cs.primaryContainer : cs.surfaceContainer,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                title: Text(
                  q,
                  style: TextStyle(
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? cs.onPrimaryContainer : null,
                  ),
                ),
                trailing: selected
                    ? Icon(Icons.check_circle_rounded, color: cs.primary)
                    : null,
                onTap: () => cubit.setDownloadQuality(label),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            );
          }),
        ],
      ),
    );
  }
}

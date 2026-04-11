import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/platform/permission_service.dart';
import '../../../../presentation/cubits/settings/settings_cubit.dart';

const _kQualities = ['Low (128 kbps)', 'Medium (192 kbps)', 'High (320 kbps)'];

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.watch<SettingsCubit>();
    final currentQuality = cubit.state.downloadQuality;
    final currentPath = cubit.state.downloadPath;

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
                    'Downloaded songs will be saved to the selected location for offline playback.',
                    style: GoogleFonts.outfit(fontSize: 13, color: cs.outline),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle('Download Location'),
          const SizedBox(height: 12),
          Card(
            color: cs.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
              title: Text(
                currentPath ?? 'Default (App Internal)',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                currentPath == null ? 'Internal storage' : 'Custom location',
                style: TextStyle(color: cs.onSurface.withAlpha(120)),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.folder_open_rounded),
                onPressed: () => _pickDirectory(context),
              ),
              onTap: () => _pickDirectory(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle('Download Quality'),
          const SizedBox(height: 12),
          ..._kQualities.map((q) {
            final label = q.split(' ').first; // "Low", "Medium", "High"
            final selected = currentQuality == label;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: selected ? cs.primaryContainer : cs.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                title: Text(
                  q,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? cs.onPrimaryContainer : null,
                  ),
                ),
                trailing: selected
                    ? Icon(Icons.check_circle_rounded, color: cs.primary)
                    : null,
                onTap: () => cubit.setDownloadQuality(label),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _pickDirectory(BuildContext context) async {
    final cubit = context.read<SettingsCubit>();

    // Check/request permissions if needed (Android)
    final hasPermission = await PermissionService.instance
        .requestStoragePermission();
    if (!hasPermission) return;

    try {
      String? selectedDirectory = await FilePicker.getDirectoryPath();
      if (selectedDirectory != null) {
        cubit.setDownloadPath(selectedDirectory);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking directory: $e')));
      }
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
        fontWeight: FontWeight.w600,
        fontSize: 11,
        letterSpacing: 1.1,
        color: cs.primary,
      ),
    );
  }
}

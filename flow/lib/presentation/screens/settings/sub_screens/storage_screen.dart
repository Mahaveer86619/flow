import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/platform/permission_service.dart';
import '../../../../core/ui/app_snack_bar.dart';
import '../../../../presentation/cubits/settings/settings_cubit.dart';

const List<int?> _kCacheTiers = [0, 250, 500, 1024, 2048, 5120, null];
const List<String> _kFormats = ['mp3', 'flac', 'opus'];
const List<int> _kBitrates = [128, 192, 256, 320];

class StorageScreen extends StatelessWidget {
  const StorageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.watch<SettingsCubit>();
    final state = cubit.state;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Storage & Downloads',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('Cache Management'),
          const SizedBox(height: 12),
          _CacheBudgetSlider(
            currentBudget: state.cacheBudgetMB,
            onChanged: (val) => cubit.setCacheBudgetMB(val),
          ),
          const SizedBox(height: 8),
          Text(
            _getCacheHint(state.cacheBudgetMB),
            style: GoogleFonts.outfit(fontSize: 12, color: cs.outline),
          ),
          const SizedBox(height: 32),
          _SectionTitle('Download Settings'),
          const SizedBox(height: 12),
          _DownloadConfigCard(
            format: state.downloadFormat,
            bitrate: state.downloadBitrate,
            onFormatChanged: (f) => cubit.setDownloadFormat(f!),
            onBitrateChanged: (b) => cubit.setDownloadBitrate(b!),
          ),
          const SizedBox(height: 24),
          _SectionTitle('Download Location'),
          const SizedBox(height: 12),
          Card(
            color: cs.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                  leading: Icon(
                    state.downloadPath == null
                        ? Icons.smartphone_rounded
                        : Icons.sd_card_rounded,
                    color: state.downloadPath == null ? cs.primary : cs.secondary,
                  ),
                  title: Text(
                    state.downloadPath ?? 'Default (App Internal)',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    state.downloadPath == null
                        ? 'Internal storage'
                        : 'Custom location',
                    style: TextStyle(color: cs.onSurface.withAlpha(120)),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: cs.outline,
                  ),
                  onTap: () => _pickDirectory(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                if (state.downloadPath != null) ...[
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    dense: true,
                    title: const Text(
                      'Reset to Default',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    leading: const Icon(
                      Icons.settings_backup_restore_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    onTap: () => cubit.clearDownloadPath(),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCacheHint(int? mb) => switch (mb) {
        0 => "⚠️ No audio stored. Network dependent.",
        250 => "~80 songs. Light offline support.",
        500 => "~160 songs. Good baseline.",
        1024 => "~320 songs. Solid offline radio.",
        2048 => "~650 songs. Weekly digest offline.",
        5120 => "~1600 songs. Near-full library offline.",
        null => "✓ Best experience. All scored songs auto-cached.",
        _ => "",
      };

  Future<void> _pickDirectory(BuildContext context) async {
    final cubit = context.read<SettingsCubit>();
    final hasPermission =
        await PermissionService.instance.requestStoragePermission();
    if (!hasPermission) return;

    try {
      // ignore: undefined_getter
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        cubit.setDownloadPath(selectedDirectory);
      }
    } catch (e, st) {


      if (context.mounted) {
        AppSnackBar.showError(context, e,
            stackTrace: st, logTag: 'StorageScreen');
      }
    }
  }
}

class _CacheBudgetSlider extends StatelessWidget {
  final int? currentBudget;
  final ValueChanged<int?> onChanged;

  const _CacheBudgetSlider({
    required this.currentBudget,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final index = _kCacheTiers.indexOf(currentBudget);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget',
              style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
            ),
            Text(
              currentBudget == null ? 'Unlimited' : '$currentBudget MB',
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: index.toDouble(),
          min: 0,
          max: (_kCacheTiers.length - 1).toDouble(),
          divisions: _kCacheTiers.length - 1,
          onChanged: (val) => onChanged(_kCacheTiers[val.toInt()]),
        ),
      ],
    );
  }
}

class _DownloadConfigCard extends StatelessWidget {
  final String format;
  final int bitrate;
  final ValueChanged<String?> onFormatChanged;
  final ValueChanged<int?> onBitrateChanged;

  const _DownloadConfigCard({
    required this.format,
    required this.bitrate,
    required this.onFormatChanged,
    required this.onBitrateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            _DropdownTile<String>(
              label: 'Format',
              value: format,
              items: _kFormats,
              onChanged: onFormatChanged,
              itemLabel: (f) => f.toUpperCase(),
            ),
            const Divider(height: 1),
            _DropdownTile<int>(
              label: 'Bitrate',
              value: bitrate,
              items: _kBitrates,
              onChanged: onBitrateChanged,
              itemLabel: (b) => '$b kbps',
              enabled: format != 'flac', // flac is lossless
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownTile<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T) itemLabel;
  final bool enabled;

  const _DropdownTile({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemLabel,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: const TextStyle(fontSize: 15)),
        trailing: DropdownButton<T>(
          value: value,
          underline: const SizedBox(),
          onChanged: enabled ? onChanged : null,
          items: items
              .map((i) => DropdownMenuItem(
                    value: i,
                    child: Text(itemLabel(i)),
                  ))
              .toList(),
        ),
      ),
    );
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

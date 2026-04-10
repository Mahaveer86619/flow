import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../presentation/cubits/settings/settings_cubit.dart';

const _kPresets = [
  'Normal',
  'Bass Boost',
  'Rock',
  'Pop',
  'Classical',
  'Jazz',
  'Electronic',
  'Hip-Hop',
];

class EqualizerScreen extends StatelessWidget {
  const EqualizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.watch<SettingsCubit>();
    final current = cubit.state.eqPreset;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Equalizer',
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
                    'Audio processing requires platform-specific support. '
                    'Preset selection is saved and will be applied when EQ is available.',
                    style: GoogleFonts.outfit(fontSize: 13, color: cs.outline),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Presets',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 1.1,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.8,
            children: _kPresets.map((preset) {
              final selected = preset == current;
              return GestureDetector(
                onTap: () => cubit.setEqPreset(preset),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: selected ? cs.primaryContainer : cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(14),
                    border: selected
                        ? Border.all(color: cs.primary, width: 1.5)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    preset,
                    style: GoogleFonts.outfit(
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? cs.onPrimaryContainer : cs.onSurface,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

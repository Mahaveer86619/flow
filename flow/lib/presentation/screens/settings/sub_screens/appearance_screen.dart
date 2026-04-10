import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../presentation/cubits/settings/settings_cubit.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.watch<SettingsCubit>();
    final current = cubit.state.themeMode;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Appearance',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Theme',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 1.1,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 12),
          _ThemeOption(
            label: 'Dark',
            icon: Icons.dark_mode_outlined,
            selected: current == ThemeMode.dark,
            onTap: () => cubit.setThemeMode(ThemeMode.dark),
          ),
          _ThemeOption(
            label: 'Light',
            icon: Icons.light_mode_outlined,
            selected: current == ThemeMode.light,
            onTap: () => cubit.setThemeMode(ThemeMode.light),
          ),
          _ThemeOption(
            label: 'System default',
            icon: Icons.brightness_auto_outlined,
            selected: current == ThemeMode.system,
            onTap: () => cubit.setThemeMode(ThemeMode.system),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: selected ? cs.primaryContainer : cs.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, color: selected ? cs.onPrimaryContainer : null),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? cs.onPrimaryContainer : null,
          ),
        ),
        trailing: selected
            ? Icon(Icons.check_circle_rounded, color: cs.primary)
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

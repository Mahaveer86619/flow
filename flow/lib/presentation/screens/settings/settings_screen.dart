import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/server_config.dart';
import '../../cubits/settings/settings_cubit.dart';
import 'sub_screens/about_screen.dart';
import 'sub_screens/appearance_screen.dart';
import 'sub_screens/downloads_screen.dart';
import 'sub_screens/equalizer_screen.dart';
import 'sub_screens/server_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsCubit>().state;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Settings',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _Section(title: 'Audio', children: [
            _Tile(
              icon: Icons.equalizer_rounded,
              title: 'Equalizer',
              subtitle: settings.eqPreset,
              onTap: () => _push(context, const EqualizerScreen()),
            ),
          ]),
          _Section(title: 'Storage', children: [
            _Tile(
              icon: Icons.download_outlined,
              title: 'Downloads',
              subtitle: '${settings.downloadQuality} quality',
              onTap: () => _push(context, const DownloadsScreen()),
            ),
          ]),
          _Section(title: 'Display', children: [
            _Tile(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              subtitle: _themeLabel(settings.themeMode),
              onTap: () => _push(context, const AppearanceScreen()),
            ),
          ]),
          _Section(title: 'Connection', children: [
            _Tile(
              icon: Icons.dns_outlined,
              title: 'Server',
              subtitle: ServerConfig.instance.isCustom
                  ? 'Custom — ${ServerConfig.instance.baseUrl}'
                  : 'Default',
              onTap: () => _push(context, const ServerScreen()),
            ),
          ]),
          _Section(title: 'Info', children: [
            _Tile(
              icon: Icons.info_outline_rounded,
              title: 'About Flow',
              subtitle: 'v1.0.0',
              onTap: () => _push(context, const AboutScreen()),
            ),
          ]),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'Light',
    ThemeMode.system => 'System',
    _ => 'Dark',
  };
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: cs.primary,
            ),
          ),
        ),
        ...children,
        Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: cs.outlineVariant.withAlpha(60),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

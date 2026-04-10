import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/config/server_config.dart';
import '../../../core/storage/local_storage.dart';
import '../../../data/sources/auth_data_source.dart';
import '../../cubits/home/home_cubit.dart';
import '../../cubits/settings/settings_cubit.dart';
import 'sub_screens/about_screen.dart';
import 'sub_screens/appearance_screen.dart';
import 'sub_screens/downloads_screen.dart';
import 'sub_screens/equalizer_screen.dart';
import 'sub_screens/server_screen.dart';
import 'sub_screens/yt_connect_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsCubit>().state;
    final authState = context.watch<AuthCubit>().state;

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
          if (authState.isAuthenticated)
            _AccountCard(
              username: authState.username ?? '',
              email: authState.email ?? '',
              onLogout: () => context.read<AuthCubit>().logout(),
            ),
          _Section(title: 'Sources', children: [
            _SourceTile(
              connected: authState.hasYtAuth,
              onTap: () => authState.hasYtAuth
                  ? _disconnectYT(context)
                  : _push(context, const YTConnectScreen()),
            ),
          ]),
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

  Future<void> _disconnectYT(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect YouTube Music'),
        content: const Text(
            'Are you sure you want to disconnect your YouTube Music account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final token = LocalStorage.instance.jwtToken;
    if (token == null) return;

    try {
      await AuthDataSource().disconnectYT(token);
      if (!context.mounted) return;
      context.read<AuthCubit>().setYtAuth(false);
      context.read<HomeCubit>().reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('YouTube Music disconnected'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to disconnect: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
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

class _AccountCard extends StatelessWidget {
  final String username;
  final String email;
  final VoidCallback onLogout;

  const _AccountCard({
    required this.username,
    required this.email,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial =
        username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: cs.primaryContainer,
              child: Text(
                initial,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withAlpha(140),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Logout'),
              style: TextButton.styleFrom(
                foregroundColor: cs.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final bool connected;
  final VoidCallback onTap;

  const _SourceTile({required this.connected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFF0000).withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.music_video_rounded,
          color: Color(0xFFFF0000),
          size: 22,
        ),
      ),
      title: const Text(
        'YouTube Music',
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connected
                  ? const Color(0xFF22C55E)
                  : cs.onSurface.withAlpha(80),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            connected ? 'Connected' : 'Not connected',
            style: TextStyle(
              fontSize: 13,
              color: connected
                  ? const Color(0xFF22C55E)
                  : cs.onSurface.withAlpha(140),
            ),
          ),
        ],
      ),
      trailing: Icon(
        connected
            ? Icons.link_off_rounded
            : Icons.chevron_right_rounded,
      ),
      onTap: onTap,
    );
  }
}

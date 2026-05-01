import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../cubits/home/home_cubit.dart';
import '../../cubits/settings/settings_cubit.dart';
import 'sub_screens/about_screen.dart';
import 'sub_screens/appearance_screen.dart';
import 'sub_screens/storage_screen.dart';
import 'sub_screens/equalizer_screen.dart';
import 'sub_screens/yt_connect_screen.dart';
import 'sub_screens/connections_screen.dart';
import '../stats/stats_screen.dart';

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
          _Section(
            title: 'Sources',
            children: [
              _SourceTile(
                name: 'YouTube Music',
                color: const Color(0xFFFF0000),
                icon: Icons.music_video_rounded,
                connected: authState.hasYtAuth,
                onTap: () => authState.hasYtAuth
                    ? _disconnectSource(context, 'YouTube Music')
                    : _push(context, const YTConnectScreen()),
              ),
              _SourceTile(
                name: 'Spotify',
                color: const Color(0xFF1DB954),
                icon: Icons.podcasts_rounded,
                connected: authState.hasSpotifyAuth,
                onTap: () => authState.hasSpotifyAuth
                    ? _disconnectSource(context, 'Spotify')
                    : _showSpotifyComingSoon(context),
              ),
            ],
          ),
          _Section(
            title: 'Audio',
            children: [
              _Tile(
                icon: Icons.equalizer_rounded,
                title: 'Equalizer',
                subtitle: settings.eqPreset,
                onTap: () => _push(context, const EqualizerScreen()),
              ),
            ],
          ),
          _Section(
            title: 'Insights',
            children: [
              _Tile(
                icon: Icons.bar_chart_rounded,
                title: 'Listening Insights',
                subtitle: 'Top artists, genres & activity',
                onTap: () => _push(context, const StatsScreen()),
              ),
            ],
          ),
          _Section(
            title: 'Networking & Social',
            children: [
              _Tile(
                icon: Icons.hub_outlined,
                title: 'Connections',
                subtitle: 'Link devices & friends',
                onTap: () => _push(context, const ConnectionsScreen()),
              ),
            ],
          ),
          _Section(
            title: 'Storage',
            children: [
              _Tile(
                icon: Icons.storage_rounded,
                title: 'Storage & Downloads',
                subtitle: '${settings.cacheBudgetMB ?? "Unlimited"} MB Cache · ${settings.downloadFormat.toUpperCase()}',
                onTap: () => _push(context, const StorageScreen()),
              ),
            ],
          ),



          _Section(
            title: 'Display',
            children: [
              _Tile(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                subtitle: _themeLabel(settings.themeMode),
                onTap: () => _push(context, const AppearanceScreen()),
              ),
            ],
          ),
          _Section(
            title: 'Info',
            children: [
              _Tile(
                icon: Icons.info_outline_rounded,
                title: 'About Flow',
                subtitle: 'v1.0.0 Standalone',
                onTap: () => _push(context, const AboutScreen()),
              ),
            ],
          ),
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

  Future<void> _disconnectSource(BuildContext context, String source) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Disconnect $source'),
        content: Text(
          'Are you sure you want to disconnect your $source account locally?',
        ),
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

    if (source == 'YouTube Music') {
      await SecureStorageService.instance.saveYoutubeCookies('');
      if (context.mounted) {
        context.read<AuthCubit>().setYtAuth(false);
        context.read<HomeCubit>().reload();
      }
    } else if (source == 'Spotify') {
      await SecureStorageService.instance.saveSpotifyCookies('');
      if (context.mounted) {
        context.read<AuthCubit>().setSpotifyAuth(false);
        context.read<HomeCubit>().reload();
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$source disconnected'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSpotifyComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Spotify Support'),
        content: const Text(
          'Spotify integration is coming in Phase 3. Stay tuned!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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

class _SourceTile extends StatelessWidget {
  final String name;
  final Color color;
  final IconData icon;
  final bool connected;
  final VoidCallback onTap;

  const _SourceTile({
    required this.name,
    required this.color,
    required this.icon,
    required this.connected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: color,
          size: 22,
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.w500),
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
        connected ? Icons.link_off_rounded : Icons.chevron_right_rounded,
      ),
      onTap: onTap,
    );
  }
}

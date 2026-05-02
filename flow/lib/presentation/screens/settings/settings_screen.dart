import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../cubits/home/home_cubit.dart';
import '../../cubits/settings/settings_cubit.dart';
import 'sub_screens/storage_screen.dart';
import 'sub_screens/equalizer_screen.dart';
import 'sub_screens/yt_connect_screen.dart';
import 'sub_screens/connections_screen.dart';
import 'sub_screens/playback_settings_screen.dart';
import '../stats/stats_screen.dart';
import '../../../core/auth/auth_cubit.dart';

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
              _Tile(
                icon: Icons.slow_motion_video_rounded,
                title: 'Playback',
                subtitle: 'Crossfade & speed',
                onTap: () => _push(context, const PlaybackSettingsScreen()),
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
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _disconnectSource(BuildContext context, String source) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Disconnect $source?'),
        content: Text('Are you sure you want to disconnect your $source account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      if (source == 'YouTube Music') {
        await context.read<AuthCubit>().disconnectYoutube();
      } else {
        await context.read<AuthCubit>().disconnectSpotify();
      }
      if (context.mounted) {
        context.read<HomeCubit>().refresh();
      }
    }
  }

  void _showSpotifyComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Spotify integration coming soon!')),
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
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
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
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _Tile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: cs.onSurface.withAlpha(200)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: cs.onSurface.withAlpha(140), fontSize: 13)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
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
  const _SourceTile({required this.name, required this.color, required this.icon, required this.connected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: connected ? Colors.green : cs.onSurface.withAlpha(60)),
          ),
          const SizedBox(width: 6),
          Text(
            connected ? 'Connected' : 'Not linked',
            style: TextStyle(
              fontSize: 12,
              color: connected ? Colors.green : cs.onSurface.withAlpha(140),
            ),
          ),
        ],
      ),
      trailing: Icon(connected ? Icons.link_off_rounded : Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

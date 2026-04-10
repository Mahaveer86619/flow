import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/logger/app_logger.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../auth/auth_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SettingsScreen — dedicated settings page.
//
// Sections:
//   • Account  — auth status, sign in / sign out
//   • Audio    — quality, equalizer, downloads (placeholder)
//   • Appearance — theme (placeholder)
//   • About    — version, licenses
// ─────────────────────────────────────────────────────────────────────────────

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        children: [
          // ── Account ───────────────────────────────────────────────────────
          _SectionLabel('Account'),
          const _AccountSection(),

          // ── Audio ─────────────────────────────────────────────────────────
          _SectionLabel('Audio'),
          const _SettingTile(
            icon: Icons.graphic_eq_rounded,
            title: 'Audio Quality',
            subtitle: 'High (320 kbps)',
          ),
          const _SettingTile(
            icon: Icons.equalizer_rounded,
            title: 'Equalizer',
            subtitle: 'Off',
          ),
          const _SettingTile(
            icon: Icons.download_outlined,
            title: 'Downloads',
            subtitle: 'Manage offline content',
          ),

          // ── Appearance ────────────────────────────────────────────────────
          _SectionLabel('Appearance'),
          const _SettingTile(
            icon: Icons.dark_mode_outlined,
            title: 'Theme',
            subtitle: 'Dark',
          ),

          // ── About ─────────────────────────────────────────────────────────
          _SectionLabel('About'),
          const _SettingTile(
            icon: Icons.info_outline_rounded,
            title: 'flow',
            subtitle: 'Version 1.0.0',
          ),
          _SettingTile(
            icon: Icons.article_outlined,
            title: 'Open Source Licenses',
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'flow',
              applicationVersion: '1.0.0',
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account section — shows auth state and sign in / out controls.
// ─────────────────────────────────────────────────────────────────────────────

class _AccountSection extends StatelessWidget {
  const _AccountSection();

  static const _tag = 'SettingsScreen/_AccountSection';

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final colorScheme = Theme.of(context).colorScheme;

    if (authState.isChecking) {
      return ListTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary,
          ),
        ),
        title: const Text('Checking status…'),
      );
    }

    if (authState.isAuthenticated) {
      return Column(
        children: [
          ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_rounded,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            title: const Text(
              'YouTube Music',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Connected',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
          ListTile(
            leading: Icon(Icons.logout_rounded, color: colorScheme.error),
            title: Text(
              'Sign out',
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () => _confirmLogout(context),
          ),
        ],
      );
    }

    // Not authenticated
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Not signed in',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sign in for personalised music and your library.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => _openAuthScreen(context),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          'Sign out?',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'You will lose access to your library and personalised music.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        AppLogger.i(_tag, 'User confirmed sign out');
        context.read<AuthCubit>().logout();
      }
    });
  }

  void _openAuthScreen(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: authCubit,
          child: AuthScreen(
            onSubmitHeaders: (h) => authCubit.submitHeaders(h),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right_rounded) : null,
      onTap: onTap,
    );
  }
}

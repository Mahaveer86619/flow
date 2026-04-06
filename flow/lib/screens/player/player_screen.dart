// ─────────────────────────────────────────────────────────────────────────────
// PlayerScreen — full-screen player used on mobile / tablet.
//
// On desktop this screen is never pushed; the [PlayerPanel] is rendered
// permanently inside [DesktopShell]'s right sidebar.
//
// The gradient background follows the current song's colors.
// All player logic lives in [PlayerCubit]; this file is purely presentational.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/player_cubit.dart';
import '../../widgets/player_panel.dart';

/// Full-screen player for mobile.
///
/// Pushed via [Navigator] from [SongCard], [MiniPlayer], and similar widgets.
/// On desktop, use [DesktopShell] instead — the sidebar is always visible.
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final song = context.watch<PlayerCubit>().state.currentSong;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // Gradient follows the current song; falls back to a dark background.
          gradient: song != null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomCenter,
                  colors: [
                    song.colorPrimary.withAlpha(180),
                    const Color(0xFF0A0A14),
                    const Color(0xFF0A0A14),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                )
              : null,
          color: song != null ? null : const Color(0xFF0A0A14),
        ),
        child: SafeArea(
          child: PlayerPanel(
            // Show the back/dismiss chevron on mobile.
            showBackButton: true,
          ),
        ),
      ),
    );
  }
}

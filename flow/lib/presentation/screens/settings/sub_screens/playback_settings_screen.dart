import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../blocs/player/player_bloc.dart';

class PlaybackSettingsScreen extends StatelessWidget {
  const PlaybackSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        title: Text('Playback', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
      ),
      body: BlocBuilder<PlayerBloc, PlayerState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionTitle('Speed'),
              const SizedBox(height: 12),
              _PlaybackSpeedCard(
                currentSpeed: state.playbackSpeed,
                onChanged: (val) => context.read<PlayerBloc>().add(SetPlaybackSpeedEvent(val)),
              ),
              const SizedBox(height: 32),
              _SectionTitle('Transitions'),
              const SizedBox(height: 12),
              _CrossfadeCard(
                currentDuration: state.crossfadeDuration,
                onChanged: (val) => context.read<PlayerBloc>().add(SetCrossfadeDurationEvent(val)),
              ),
              const SizedBox(height: 8),
              Text(
                'Crossfade creates a smooth transition between tracks.',
                style: GoogleFonts.outfit(fontSize: 12, color: cs.outline),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlaybackSpeedCard extends StatelessWidget {
  final double currentSpeed;
  final ValueChanged<double> onChanged;

  const _PlaybackSpeedCard({required this.currentSpeed, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Speed', style: TextStyle(fontWeight: FontWeight.w500)),
                Text('${currentSpeed.toStringAsFixed(2)}x', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: currentSpeed,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _CrossfadeCard extends StatelessWidget {
  final Duration currentDuration;
  final ValueChanged<Duration> onChanged;

  const _CrossfadeCard({required this.currentDuration, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Crossfade', style: TextStyle(fontWeight: FontWeight.w500)),
                Text('${currentDuration.inSeconds}s', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: currentDuration.inSeconds.toDouble(),
              min: 0,
              max: 12,
              divisions: 12,
              onChanged: (val) => onChanged(Duration(seconds: val.toInt())),
            ),
          ],
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

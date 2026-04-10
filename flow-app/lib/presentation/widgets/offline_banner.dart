import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/network/network_cubit.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OfflineBanner — animated top banner that appears when the device goes offline
// and dismisses when connectivity is restored.
//
// Wrap around your content Column and it handles itself:
//   Column(children: [
//     const OfflineBanner(),
//     Expanded(child: yourContent),
//   ])
// ─────────────────────────────────────────────────────────────────────────────

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkCubit, NetworkState>(
      buildWhen: (prev, curr) => prev != curr,
      builder: (context, state) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: state == NetworkState.offline
              ? _BannerContent()
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

class _BannerContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You\'re offline — some content may be unavailable',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

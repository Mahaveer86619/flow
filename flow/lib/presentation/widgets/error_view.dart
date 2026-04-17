import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/error/app_exception.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ErrorView — full-area error widget shown when a screen fails to load.
//
// Variants driven by [AppErrorType]:
//   network    → wifi_off icon, "No internet"
//   serverDown → cloud_off icon, "Server offline"
//   serverError→ error icon, "Something went wrong"
//   parse      → code icon, "Bad data"
//   unknown    → generic error icon
//
// Always shows a [Retry] button. Optional [secondary] action (e.g. "Use mock").
// ─────────────────────────────────────────────────────────────────────────────

class ErrorView extends StatefulWidget {
  final AppErrorType errorType;
  final String? customMessage;
  final VoidCallback onRetry;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const ErrorView({
    super.key,
    required this.errorType,
    required this.onRetry,
    this.customMessage,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  State<ErrorView> createState() => _ErrorViewState();
}

class _ErrorViewState extends State<ErrorView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final spec = _spec(widget.errorType, cs);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon container ───────────────────────────────────────────
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: spec.color.withAlpha(20),
                  ),
                  child: Icon(spec.icon, size: 40, color: spec.color),
                ),
                const SizedBox(height: 24),

                // ── Title ────────────────────────────────────────────────────
                Text(
                  spec.title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // ── Subtitle ─────────────────────────────────────────────────
                Text(
                  widget.customMessage ?? spec.subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: cs.onSurface.withAlpha(160),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // ── Retry button ─────────────────────────────────────────────
                FilledButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try again'),
                  style: FilledButton.styleFrom(
                    backgroundColor: spec.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // ── Optional secondary action ─────────────────────────────────
                if (widget.onSecondary != null) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: widget.onSecondary,
                    child: Text(
                      widget.secondaryLabel ?? 'Other option',
                      style: TextStyle(
                        color: cs.onSurface.withAlpha(140),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact inline error — for small spaces (e.g. inside a card)
// ─────────────────────────────────────────────────────────────────────────────

class InlineErrorView extends StatelessWidget {
  final AppErrorType errorType;
  final VoidCallback onRetry;

  const InlineErrorView({
    super.key,
    required this.errorType,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final spec = _spec(errorType, cs);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        children: [
          Icon(spec.icon, size: 22, color: spec.color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              spec.title,
              style: TextStyle(
                color: cs.onSurface.withAlpha(180),
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Spec helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Spec {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _Spec({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

_Spec _spec(AppErrorType type, ColorScheme cs) {
  switch (type) {
    case AppErrorType.network:
      return _Spec(
        icon: Icons.wifi_off_rounded,
        color: const Color(0xFF6366F1),
        title: 'No internet connection',
        subtitle: 'Check your Wi-Fi or mobile data and try again.',
      );
    case AppErrorType.serverDown:
      return _Spec(
        icon: Icons.cloud_off_rounded,
        color: const Color(0xFFF59E0B),
        title: 'Server is offline',
        subtitle:
            'The music server couldn\'t be reached. It may be down or the address is incorrect.',
      );
    case AppErrorType.serverError:
      return _Spec(
        icon: Icons.dns_rounded,
        color: const Color(0xFFEF4444),
        title: 'Server error',
        subtitle:
            'The server returned an unexpected response. Try again shortly.',
      );
    case AppErrorType.parse:
      return _Spec(
        icon: Icons.data_object_rounded,
        color: const Color(0xFFEC4899),
        title: 'Bad data',
        subtitle: 'Received unexpected data from the server.',
      );
    case AppErrorType.unauthorized:
      return _Spec(
        icon: Icons.lock_person_rounded,
        color: const Color(0xFF8B5CF6),
        title: 'Session expired',
        subtitle: 'Please sign in again to continue.',
      );
    case AppErrorType.ytAuthExpired:
      return _Spec(
        icon: Icons.sync_problem_rounded,
        color: const Color(0xFFF59E0B),
        title: 'YouTube Music disconnected',
        subtitle:
            'Your YouTube Music session has expired. Please reconnect in settings.',
      );
    case AppErrorType.unknown:
      return _Spec(
        icon: Icons.error_outline_rounded,
        color: cs.error,
        title: 'Something went wrong',
        subtitle: 'An unexpected error occurred. Tap below to try again.',
      );
  }
}

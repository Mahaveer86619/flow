import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/logger/app_logger.dart';
import '../../cubits/auth/auth_cubit.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthScreen — foundation for Google/YouTube Music sign-in.
//
// The intended flow:
//   1. User taps "Sign in with YouTube Music".
//   2. A WebView opens music.youtube.com (user signs in there normally).
//   3. We intercept the request headers containing the session cookies.
//   4. Those cookies are POSTed to the backend /api/auth endpoint.
//   5. AuthCubit.onAuthSuccess() is called and the screen pops.
//
// For now the WebView is a placeholder — the manual-headers flow works today
// and the WebView can be dropped in once the flutter_inappwebview package
// is added to pubspec.yaml.
// ─────────────────────────────────────────────────────────────────────────────

class AuthScreen extends StatefulWidget {
  /// Callback that actually sends headers to the server.
  /// Injected to keep this screen decoupled from [ApiSongDataSource].
  final Future<void> Function(String headersOrCurl) onSubmitHeaders;

  const AuthScreen({super.key, required this.onSubmitHeaders});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const _tag = 'AuthScreen';

  final _headersController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _headersController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = _headersController.text.trim();
    if (raw.isEmpty) {
      setState(() => _errorMessage = 'Paste your request headers or cURL command.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onSubmitHeaders(raw);
      if (!mounted) return;
      context.read<AuthCubit>().onAuthSuccess();
      Navigator.of(context).pop(true); // pop with success
    } catch (e) {
      AppLogger.e(_tag, 'Auth submit failed', e, StackTrace.current);
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Authentication failed. Check your headers and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero ──────────────────────────────────────────────────────────
            Text(
              'Connect YouTube Music',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to get personalised recommendations, access your playlists, and more.',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withAlpha(160),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            // ── WebView placeholder (future) ───────────────────────────────
            _WebViewPlaceholder(),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),

            // ── Manual headers fallback ────────────────────────────────────
            Text(
              'Advanced: paste request headers',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withAlpha(160),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Open music.youtube.com in your browser, copy a network request as cURL (or copy the raw request headers), then paste below.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withAlpha(120),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _headersController,
              maxLines: 8,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: 'curl "https://music.youtube.com/" \\\n  -H "cookie: ..." \\\n  ...',
                hintStyle: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withAlpha(80),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHigh,
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: colorScheme.error, fontSize: 13),
              ),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Authenticate'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WebView placeholder — swap this for flutter_inappwebview later.
// ─────────────────────────────────────────────────────────────────────────────

class _WebViewPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withAlpha(60),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.open_in_browser_rounded,
            size: 40,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'One-tap sign in coming soon',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A built-in browser will open YouTube Music so you can sign in without leaving the app.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withAlpha(140),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/auth/auth_cubit.dart';
import '../../../../core/ui/app_snack_bar.dart';
import '../../../cubits/home/home_cubit.dart';
import '../../../cubits/yt_connect/yt_connect_cubit.dart';

class YTConnectScreen extends StatefulWidget {
  const YTConnectScreen({super.key});

  @override
  State<YTConnectScreen> createState() => _YTConnectScreenState();
}

enum ConnectMethod { standard, oauth }

class _YTConnectScreenState extends State<YTConnectScreen> {
  InAppWebViewController? _webCtrl;
  bool _pageLoaded = false;
  bool _extracting = false;
  ConnectMethod _method = ConnectMethod.oauth; // Default to reliable method

  // Must be present to confirm the user is signed in.
  static const _requiredCookies = [
    '__Secure-3PAPISID',
    '__Secure-3PSID',
    'HSID',
    'SSID',
    'APISID',
    'SAPISID',
  ];

  // All YouTube/Google cookies that help yt-dlp bypass bot detection.
  static const _ytCookieNames = {
    'SID', 'HSID', 'SSID', 'APISID', 'SAPISID', 'LOGIN_INFO',
    '__Secure-1PSID', '__Secure-1PAPISID',
    '__Secure-3PSID', '__Secure-3PAPISID',
    'VISITOR_INFO1_LIVE', 'YSC', 'PREF', '__Secure-YEC',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (_) => YTConnectCubit(),
      child: BlocConsumer<YTConnectCubit, YTConnectState>(
        listener: (ctx, state) async {
          if (state.isSuccess) {
            ctx.read<AuthCubit>().setYtAuth(true);
            ctx.read<HomeCubit>().reload();
            if (!mounted) return;
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text('YouTube Music connected!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            await Future.delayed(const Duration(milliseconds: 600));
            if (mounted) Navigator.of(ctx).pop(true);
          } else if (state.isError) {
            setState(() => _extracting = false);
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Connection failed'),
                backgroundColor: cs.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (ctx, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Connect YT Music',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
              actions: [
                if (_method == ConnectMethod.standard)
                  if (state.isLoading || _extracting)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton(
                        onPressed: _pageLoaded ? () => _onDone(ctx) : null,
                        child: const Text('Done'),
                      ),
                    ),
              ],
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SegmentedButton<ConnectMethod>(
                    segments: const [
                      ButtonSegment(
                        value: ConnectMethod.oauth,
                        label: Text('Reliable (TV Style)'),
                        icon: Icon(Icons.verified_user_rounded),
                      ),
                      ButtonSegment(
                        value: ConnectMethod.standard,
                        label: Text('Fast (Cookies)'),
                        icon: Icon(Icons.cookie_rounded),
                      ),
                    ],
                    selected: {_method},
                    onSelectionChanged: (set) {
                      setState(() => _method = set.first);
                      if (_method == ConnectMethod.oauth &&
                          state.status == YTConnectStatus.idle) {
                        ctx.read<YTConnectCubit>().startOAuth();
                      }
                    },
                  ),
                ),
                Expanded(
                  child: _method == ConnectMethod.standard
                      ? _buildWebView(cs)
                      : _buildOAuthView(ctx, state, cs),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWebView(ColorScheme cs) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: cs.primaryContainer.withAlpha(80),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sign in below, then tap "Done". (May be blocked by Google)',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withAlpha(160),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri('https://music.youtube.com'),
            ),
            initialSettings: InAppWebViewSettings(
              userAgent:
                  'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
                  'AppleWebKit/537.36 (KHTML, like Gecko) '
                  'Chrome/120.0.0.0 Mobile Safari/537.36',
              javaScriptEnabled: true,
              domStorageEnabled: true,
              cacheEnabled: true,
            ),
            onWebViewCreated: (c) => _webCtrl = c,
            onLoadStop: (_, __) => setState(() => _pageLoaded = true),
          ),
        ),
      ],
    );
  }

  Widget _buildOAuthView(
    BuildContext context,
    YTConnectState state,
    ColorScheme cs,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == YTConnectStatus.idle) {
      return Center(
        child: FilledButton.icon(
          onPressed: () => context.read<YTConnectCubit>().startOAuth(),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start Authorization'),
        ),
      );
    }

    if (state.isOAuthPending) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.tv_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              'Authorize on the Server',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This is the most reliable method. It creates a connection directly on the server to avoid bot detection.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            const Text('STEP 1: VISIT URL'),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => launchUrl(Uri.parse(state.verificationUrl!)),
              child: Text(
                state.verificationUrl ?? '',
                style: TextStyle(
                  color: cs.primary,
                  decoration: TextDecoration.underline,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text('STEP 2: ENTER CODE'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.userCode ?? '',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: state.userCode ?? ''),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied!')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 16),
            const Text(
              'Waiting for you to complete authorization...',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _onDone(BuildContext context) async {
    setState(() => _extracting = true);
    try {
      final cookies = await CookieManager.instance().getCookies(
        webViewController: _webCtrl,
        url: WebUri('https://music.youtube.com'),
      );

      final cookieMap = <String, String>{
        for (final c in cookies) c.name: c.value.toString(),
      };

      final missing = _requiredCookies
          .where((n) => !cookieMap.containsKey(n))
          .toList();

      if (missing.isNotEmpty) {
        setState(() => _extracting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Not signed in yet — please log in to YouTube Music first.',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Send all recognised YT/Google cookies — the superset gives yt-dlp the
      // best chance of bypassing bot detection, not just the required minimum.
      final allCookies = <String, String>{
        for (final entry in cookieMap.entries)
          if (_ytCookieNames.contains(entry.key)) entry.key: entry.value,
      };
      // Always include required cookies even if not in the named set.
      for (final k in _requiredCookies) {
        allCookies[k] = cookieMap[k]!;
      }

      if (mounted) context.read<YTConnectCubit>().connect(allCookies);
    } catch (e, st) {
      setState(() => _extracting = false);
      if (mounted) {
        AppSnackBar.showError(context, e, stackTrace: st, logTag: 'YTConnectScreen');
      }
    }
  }
}

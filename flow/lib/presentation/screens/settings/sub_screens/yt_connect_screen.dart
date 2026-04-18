import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/auth/auth_cubit.dart';
import '../../../../core/ui/app_snack_bar.dart';
import '../../../cubits/home/home_cubit.dart';
import '../../../cubits/yt_connect/yt_connect_cubit.dart';

class YTConnectScreen extends StatefulWidget {
  const YTConnectScreen({super.key});

  @override
  State<YTConnectScreen> createState() => _YTConnectScreenState();
}

class _YTConnectScreenState extends State<YTConnectScreen> {
  InAppWebViewController? _webCtrl;
  bool _pageLoaded = false;
  bool _extracting = false;

  // Must be present to confirm the user is signed in.
  static const _requiredCookies = [
    '__Secure-3PAPISID',
    '__Secure-3PSID',
    'HSID',
    'SSID',
    'APISID',
    'SAPISID',
  ];

  // All YouTube/Google cookies that help bypass bot detection.
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
            // Update local auth state and reload home
            ctx.read<AuthCubit>().setYtAuth(true);
            ctx.read<HomeCubit>().reload();
            
            if (!mounted) return;
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text('YouTube Music connected locally!'),
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: cs.primaryContainer.withAlpha(80),
                  child: Row(
                    children: [
                      Icon(Icons.security_rounded, size: 18, color: cs.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Sign in to YouTube Music below. Once the page loads and you are signed in, tap "Done" to extract session cookies locally.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface.withAlpha(180),
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
            ),
          );
        },
      ),
    );
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

      final allCookies = <String, String>{
        for (final entry in cookieMap.entries)
          if (_ytCookieNames.contains(entry.key)) entry.key: entry.value,
      };
      // Always include required cookies
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

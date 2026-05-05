import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../../core/auth/auth_cubit.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../cubits/home/home_cubit.dart';

class YTConnectScreen extends StatefulWidget {
  const YTConnectScreen({super.key});

  @override
  State<YTConnectScreen> createState() => _YTConnectScreenState();
}

class _YTConnectScreenState extends State<YTConnectScreen> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  final CookieManager _cookieManager = CookieManager.instance();
  static const _tag = 'YTConnectScreen';

  @override
  void initState() {
    super.initState();
    AppLogger.i(_tag, 'YTConnectScreen initialized');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('YT Music'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _webViewController?.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: _extractCookies,
          ),
        ],
      ),
      // Use Column so the WebView gets a bounded height
      body: SafeArea(
        child: Column(
          children: [
            // Loading progress bar at top — doesn't fight with WebView layout
            if (_isLoading)
              const LinearProgressIndicator(
                color: Colors.red,
                backgroundColor: Colors.black26,
              ),
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(
                    'https://accounts.google.com/ServiceLogin?hl=en&passive=true&continue=https://music.youtube.com/',
                  ),
                ),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  // FIX: was true but no handler was provided — this blocks
                  // all navigation on Android. Set to false unless you need
                  // custom URL interception.
                  useShouldOverrideUrlLoading: false,
                  isInspectable: true,
                  useHybridComposition: true,
                  domStorageEnabled: true,
                  databaseEnabled: true,
                  thirdPartyCookiesEnabled: true,
                  verticalScrollBarEnabled: true,
                  horizontalScrollBarEnabled: true,
                  // Helps with Google login UA checks
                  userAgent:
                      'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 '
                      '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                  AppLogger.i(_tag, 'WebView created');
                },
                onLoadStart: (controller, url) {
                  AppLogger.i(_tag, 'Page load start: $url');
                  if (mounted) setState(() => _isLoading = true);
                },
                onLoadStop: (controller, url) async {
                  AppLogger.i(_tag, 'Page load stop: $url');
                  if (mounted) setState(() => _isLoading = false);
                },
                onReceivedError: (controller, request, error) {
                  AppLogger.e(_tag, 'WebView error: ${error.description}');
                  if (mounted) setState(() => _isLoading = false);
                },
                onConsoleMessage: (controller, consoleMessage) {
                  AppLogger.d(_tag, 'JS: ${consoleMessage.message}');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _extractCookies() async {
    try {
      AppLogger.i(_tag, 'Extracting cookies...');

      final currentUrl = await _webViewController?.getUrl();
      AppLogger.d(_tag, 'Current URL at extraction: $currentUrl');

      // Collect cookies from all relevant Google/YT domains
      final results = await Future.wait([
        _cookieManager.getCookies(url: WebUri('https://music.youtube.com/')),
        _cookieManager.getCookies(url: WebUri('https://www.youtube.com/')),
        _cookieManager.getCookies(url: WebUri('https://accounts.google.com/')),
      ]);

      final Map<String, String> allCookies = {};
      for (final cookieList in results) {
        for (final c in cookieList) {
          // Later entries (more specific domains) win
          allCookies[c.name] = c.value;
        }
      }

      AppLogger.d(
        _tag,
        'Found ${allCookies.length} cookies: ${allCookies.keys.toList()}',
      );

      final cookieString = allCookies.entries
          .map((e) => '${e.key}=${e.value}')
          .join('; ');

      final hasValidAuth =
          allCookies.containsKey('LOGIN_INFO') ||
          allCookies.containsKey('__Secure-3PAPISID') ||
          allCookies.containsKey('SAPISID') ||
          allCookies.containsKey('__Secure-1PSID') ||
          allCookies.containsKey('HSID');

      if (hasValidAuth) {
        await SecureStorageService.instance.saveYoutubeCookies(cookieString);

        // FIX: evaluateJavascript can return dynamic; cast safely
        final dynamic uaResult = await _webViewController?.evaluateJavascript(
          source: 'navigator.userAgent',
        );
        if (uaResult != null) {
          final userAgent = uaResult.toString().replaceAll('"', '').trim();
          if (userAgent.isNotEmpty) {
            await SecureStorageService.instance.saveYoutubeUserAgent(userAgent);
            AppLogger.d(_tag, 'Saved user agent: $userAgent');
          }
        }

        AppLogger.i(_tag, 'Success: Auth cookies captured');

        if (mounted) {
          context.read<AuthCubit>().setYtAuth(true);
          context.read<HomeCubit>().refresh();
          Navigator.pop(context);
        }
      } else {
        AppLogger.w(
          _tag,
          'Auth cookies not found. Present keys: ${allCookies.keys.toList()}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Login not detected. Please complete the sign-in process first.',
              ),
            ),
          );
        }
      }
    } catch (e, stack) {
      AppLogger.e(_tag, 'Cookie extraction error', e);
      AppLogger.e(_tag, 'Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error extracting cookies: $e')));
      }
    }
  }
}

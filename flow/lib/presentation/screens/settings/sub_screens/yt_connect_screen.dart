import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/auth/auth_cubit.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../cubits/home/home_cubit.dart';

class YTConnectScreen extends StatefulWidget {
  const YTConnectScreen({super.key});

  @override
  State<YTConnectScreen> createState() => _YTConnectScreenState();
}

class _YTConnectScreenState extends State<YTConnectScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            _checkIfLoggedIn();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(
          'https://accounts.google.com/ServiceLogin?hl=en&passive=true&continue=https://music.youtube.com/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect YouTube Music'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: _extractCookies,
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Future<void> _checkIfLoggedIn() async {
    final url = await _controller.currentUrl();
    if (url != null && url.contains('music.youtube.com')) {
      // Potentially already logged in or reached destination
    }
  }

  Future<void> _extractCookies() async {
    try {
      final Object cookies =
          await _controller.runJavaScriptReturningResult('document.cookie');
      final cookieString = cookies.toString().replaceAll('"', '');

      if (cookieString.contains('LOGIN_INFO') || (cookieString.contains('SAPISID') && cookieString.contains('HSID'))) {
        await SecureStorageService.instance.saveYoutubeCookies(cookieString);
        
        final userAgent = await _controller.runJavaScriptReturningResult('navigator.userAgent');
        await SecureStorageService.instance.saveYoutubeUserAgent(userAgent.toString().replaceAll('"', ''));

        if (mounted) {
          context.read<AuthCubit>().setYtAuth(true);
          context.read<HomeCubit>().refresh();
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Could not find authentication cookies. Please sign in.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error extracting cookies: $e')),
        );
      }
    }
  }
}

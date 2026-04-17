import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/auth/auth_cubit.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/ui/app_snack_bar.dart';
import '../../../../data/sources/admin_data_source.dart';

class ServerBrowserScreen extends StatefulWidget {
  const ServerBrowserScreen({super.key});

  @override
  State<ServerBrowserScreen> createState() => _ServerBrowserScreenState();
}

class _ServerBrowserScreenState extends State<ServerBrowserScreen> {
  static const _tag = 'ServerBrowserScreen';
  static const _browserAspectW = 1280.0;
  static const _browserAspectH = 720.0;

  final _source = AdminDataSource();
  final _textController = TextEditingController();
  final _imageKey = GlobalKey();

  Uint8List? _imageBytes;
  bool _starting = true;
  bool _busy = false;
  Timer? _pollTimer;
  String? _token;

  @override
  void initState() {
    super.initState();
    _token = LocalStorage.instance.jwtToken;
    _startBrowser();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textController.dispose();
    // Best-effort stop — don't await in dispose
    if (_token != null) _source.browserStop(_token!).catchError((_) {});
    super.dispose();
  }

  Future<void> _startBrowser() async {
    if (_token == null) return;
    try {
      final frame = await _source.browserStart(_token!);
      if (!mounted) return;
      setState(() {
        _imageBytes = base64Decode(frame.screenshot);
        _starting = false;
      });
      _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
    } catch (e, st) {
      if (mounted) {
        setState(() => _starting = false);
        AppSnackBar.showError(context, e, stackTrace: st, logTag: _tag);
      }
    }
  }

  Future<void> _poll() async {
    if (_busy || _token == null || !mounted) return;
    try {
      final frame = await _source.browserFrame(_token!);
      if (mounted && frame.isActive && frame.screenshot.isNotEmpty) {
        setState(() => _imageBytes = base64Decode(frame.screenshot));
      }
    } catch (_) {}
  }

  Future<void> _onTap(TapUpDetails details) async {
    if (_busy || _token == null) return;
    final box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final size = box.size;
    final scale = min(size.width / _browserAspectW, size.height / _browserAspectH);
    final dispW = _browserAspectW * scale;
    final dispH = _browserAspectH * scale;
    final offsetX = (size.width - dispW) / 2;
    final offsetY = (size.height - dispH) / 2;

    final local = details.localPosition;
    final xFrac = ((local.dx - offsetX) / dispW).clamp(0.0, 1.0);
    final yFrac = ((local.dy - offsetY) / dispH).clamp(0.0, 1.0);

    _setAction(true);
    try {
      final frame = await _source.browserTap(_token!, xFrac, yFrac);
      if (mounted) setState(() => _imageBytes = base64Decode(frame.screenshot));
    } catch (e, st) {
      if (mounted) AppSnackBar.showError(context, e, stackTrace: st, logTag: _tag);
    } finally {
      _setAction(false);
    }
  }

  Future<void> _sendText() async {
    final text = _textController.text;
    if (text.isEmpty || _busy || _token == null) return;
    _textController.clear();
    _setAction(true);
    try {
      final frame = await _source.browserType(_token!, text);
      if (mounted) setState(() => _imageBytes = base64Decode(frame.screenshot));
    } catch (e, st) {
      if (mounted) AppSnackBar.showError(context, e, stackTrace: st, logTag: _tag);
    } finally {
      _setAction(false);
    }
  }

  Future<void> _pressKey(String key) async {
    if (_busy || _token == null) return;
    _setAction(true);
    try {
      final frame = await _source.browserKey(_token!, key);
      if (mounted) setState(() => _imageBytes = base64Decode(frame.screenshot));
    } catch (e, st) {
      if (mounted) AppSnackBar.showError(context, e, stackTrace: st, logTag: _tag);
    } finally {
      _setAction(false);
    }
  }

  Future<void> _save() async {
    if (_token == null) return;
    _pollTimer?.cancel();
    _setAction(true);
    try {
      final count = await _source.browserSave(_token!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved $count cookies from server browser.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Reflect updated YT connection state
      context.read<AuthCubit>().setYtAuth(true);
      Navigator.of(context).pop(true);
    } catch (e, st) {
      _setAction(false);
      if (mounted) AppSnackBar.showError(context, e, stackTrace: st, logTag: _tag);
      _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
    }
  }

  void _setAction(bool busy) {
    if (mounted) setState(() => _busy = busy);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Server Login',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Cookies'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            color: cs.primaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Log in to YouTube/Google in this browser. '
              'Cookies will be saved to the server (same IP as yt-dlp).',
              style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer),
            ),
          ),

          // Browser screenshot
          Expanded(
            child: _starting
                ? const Center(child: CircularProgressIndicator())
                : _imageBytes == null
                ? const Center(child: Text('Browser not available'))
                : GestureDetector(
                    onTapUp: _onTap,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: _browserAspectW / _browserAspectH,
                        child: Image.memory(
                          key: _imageKey,
                          _imageBytes!,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  ),
          ),

          // Keyboard row
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  _KeyBtn('⌫', () => _pressKey('Backspace')),
                  _KeyBtn('Tab', () => _pressKey('Tab')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Type here…',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      onSubmitted: (_) => _pressKey('Enter'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _KeyBtn('↵', _sendText, primary: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;
  const _KeyBtn(this.label, this.onTap, {this.primary = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: FilledButton.tonal(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: primary ? cs.primary : null,
          foregroundColor: primary ? cs.onPrimary : null,
          minimumSize: const Size(44, 40),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: Text(label),
      ),
    );
  }
}

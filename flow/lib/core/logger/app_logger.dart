import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppLogger — singleton debug-gated logger.
// ─────────────────────────────────────────────────────────────────────────────

class AppLogger {
  AppLogger._();

  static Logger? _logger;
  static bool _debug = false;

  /// Must be called once in main() after dotenv.load().
  static void init() {
    // Fallback to kDebugMode if .env is not loaded or missing DEBUG key
    _debug = dotenv.env['DEBUG']?.toLowerCase() == 'true' || kDebugMode;

    // Always print to console during init to verify
    print('AppLogger: Initializing (DEBUG=$_debug, kDebugMode=$kDebugMode)');

    _logger = Logger(
      level: _debug ? Level.debug : Level.info, // Use Info as minimum for now
      printer: PrettyPrinter(
        methodCount: _debug ? 2 : 0,
        errorMethodCount: 8,
        lineLength: 100,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
    );

    i('AppLogger', 'Logger initialized. Level: ${_debug ? "DEBUG" : "INFO"}');
  }

  static bool get isDebug => _debug;

  // ── Log levels ───────────────────────────────────────────────────────────────

  static void d(String tag, String msg, [Object? extra]) {
    if (!_debug) return;
    _logger?.d('[$tag] $msg', error: extra);
  }

  static void i(String tag, String msg, [Object? extra]) {
    if (_logger == null) {
      print('INFO: [$tag] $msg ${extra ?? ""}');
      return;
    }
    _logger?.i('[$tag] $msg', error: extra);
  }

  static void w(String tag, String msg, [Object? extra]) {
    if (_logger == null) {
      print('WARN: [$tag] $msg ${extra ?? ""}');
      return;
    }
    _logger?.w('[$tag] $msg', error: extra);
  }

  static void e(
    String tag,
    String msg, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (_logger == null) {
      print('ERROR: [$tag] $msg $error\n$stackTrace');
      return;
    }
    _logger?.e('[$tag] $msg', error: error, stackTrace: stackTrace);
  }
}

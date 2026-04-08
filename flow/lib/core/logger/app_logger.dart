import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppLogger — singleton debug-gated logger.
//
// Reads DEBUG from .env at startup.
//   DEBUG=true  → Level.debug, full stack traces, pretty-printed with colours.
//   DEBUG=false → Level.warning only; errors always surface regardless.
//
// Usage:
//   AppLogger.d('Tag', 'message');   // debug only
//   AppLogger.i('Tag', 'message');   // info
//   AppLogger.w('Tag', 'message');   // warning
//   AppLogger.e('Tag', 'msg', err, stackTrace);  // error — always shown
// ─────────────────────────────────────────────────────────────────────────────

class AppLogger {
  AppLogger._();

  static late final Logger _logger;
  static bool _debug = false;

  /// Must be called once in main() after dotenv.load().
  static void init() {
    _debug = dotenv.env['DEBUG']?.toLowerCase() == 'true';

    _logger = Logger(
      level: _debug ? Level.debug : Level.warning,
      printer: PrettyPrinter(
        methodCount: _debug ? 3 : 0,
        errorMethodCount: 10,
        lineLength: 110,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
    );

    i('AppLogger', 'Logger ready  •  DEBUG=$_debug');
  }

  static bool get isDebug => _debug;

  // ── Log levels ───────────────────────────────────────────────────────────────

  /// Verbose debug trace — suppressed unless DEBUG=true.
  static void d(String tag, String msg, [Object? extra]) {
    if (!_debug) return;
    _logger.d('[$tag] $msg', error: extra);
  }

  /// Informational message.
  static void i(String tag, String msg, [Object? extra]) {
    _logger.i('[$tag] $msg', error: extra);
  }

  /// Warning — unexpected but recoverable.
  static void w(String tag, String msg, [Object? extra]) {
    _logger.w('[$tag] $msg', error: extra);
  }

  /// Error — always emitted regardless of DEBUG flag.
  static void e(
    String tag,
    String msg, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _logger.e('[$tag] $msg', error: error, stackTrace: stackTrace);
  }
}

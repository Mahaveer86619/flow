// ─────────────────────────────────────────────────────────────────────────────
// AppException hierarchy
//
// Thrown by the data layer and caught by cubits/bloc to produce typed
// error states that the UI can render with the right copy and icon.
// ─────────────────────────────────────────────────────────────────────────────

/// Base class for all Flow application exceptions.
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => 'AppException: $message';
}

/// Thrown when the device has no internet connection.
class NetworkException extends AppException {
  const NetworkException([
    super.message = 'No internet connection. Check your network and try again.',
  ]);
}

/// Thrown when the server is reachable but returns a non-2xx response.
class ServerException extends AppException {
  final int? statusCode;
  const ServerException({required String message, this.statusCode})
      : super(message);

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Thrown when the server returns 401 — user not authenticated.
class AuthException extends AppException {
  const AuthException([
    super.message = 'Sign in to access this content.',
  ]);
}

/// Thrown when the server is unreachable (connection refused / timeout).
class ServerUnreachableException extends AppException {
  const ServerUnreachableException([
    super.message =
        'Cannot reach the server. It may be offline or the address is wrong.',
  ]);
}

/// Thrown for unexpected JSON parsing failures.
class ParseException extends AppException {
  const ParseException([super.message = 'Failed to parse server response.']);
}

/// Thrown on local storage read/write failures.
class CacheException extends AppException {
  const CacheException([super.message = 'Local storage error.']);
}

// ─────────────────────────────────────────────────────────────────────────────
// Typed error categories used by UI state — derived from exceptions.
// ─────────────────────────────────────────────────────────────────────────────

enum AppErrorType {
  network,         // offline
  serverDown,      // server unreachable
  serverError,     // server returned an error response
  unauthenticated, // 401 — needs sign-in
  parse,           // bad data
  unknown,         // catch-all
}

extension AppExceptionExt on AppException {
  AppErrorType get errorType {
    if (this is NetworkException) return AppErrorType.network;
    if (this is ServerUnreachableException) return AppErrorType.serverDown;
    if (this is AuthException) return AppErrorType.unauthenticated;
    if (this is ServerException) return AppErrorType.serverError;
    if (this is ParseException) return AppErrorType.parse;
    return AppErrorType.unknown;
  }
}

/// Converts any raw exception to an [AppException].
AppException toAppException(Object e) {
  if (e is AppException) return e;
  final msg = e.toString();
  if (msg.contains('SocketException') ||
      msg.contains('Connection refused') ||
      msg.contains('Network is unreachable') ||
      msg.contains('Failed host lookup')) {
    return const ServerUnreachableException();
  }
  if (msg.contains('TimeoutException')) {
    return const ServerUnreachableException('Request timed out.');
  }
  return e is AppException ? e : _UnknownException(msg);
}

class _UnknownException extends AppException {
  const _UnknownException(super.message);
}

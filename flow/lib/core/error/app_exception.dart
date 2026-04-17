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

/// Thrown when the server returns a 401 Unauthorized response.
class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'Session expired. Please sign in again.',
  ]);
}

/// Thrown when YT Music session is expired (403 Forbidden from backend).
class YTSessionExpiredException extends AppException {
  const YTSessionExpiredException([
    super.message = 'YouTube Music session expired. Please reconnect.',
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
  network, // offline
  serverDown, // server unreachable
  serverError, // server returned an error response
  unauthorized, // 401
  ytAuthExpired, // 403
  parse, // bad data
  unknown, // catch-all
}

extension AppExceptionExt on AppException {
  AppErrorType get errorType {
    if (this is NetworkException) return AppErrorType.network;
    if (this is ServerUnreachableException) return AppErrorType.serverDown;
    if (this is UnauthorizedException) return AppErrorType.unauthorized;
    if (this is YTSessionExpiredException) return AppErrorType.ytAuthExpired;
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

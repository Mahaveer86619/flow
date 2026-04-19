import 'package:flutter/material.dart';
import '../error/app_exception.dart';
import '../logger/app_logger.dart';

class AppSnackBar {
  static const _tag = 'AppSnackBar';

  static String humanMessage(Object e) {
    if (e is NetworkException) return 'No internet connection.';
    if (e is YTSessionExpiredException) {
      return 'YouTube Music session expired. Please reconnect.';
    }
    if (e is UnauthorizedException) return 'Unauthorized. Please sign in again.';
    if (e is RemoteUnreachableException) return 'Remote service is unreachable. Try again later.';
    if (e is ParseException) return 'Failed to load data. Please try again.';
    if (e is CacheException) return 'Storage error. Please try again.';
    if (e is SourceException) return 'Something went wrong. Please try again.';
    if (e is AppException) return e.message;
    return 'An unexpected error occurred. Please try again.';
  }

  static void showError(
    BuildContext context,
    Object e, {
    StackTrace? stackTrace,
    String logTag = _tag,
  }) {
    AppLogger.e(logTag, e.runtimeType.toString(), e, stackTrace);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(humanMessage(e)),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

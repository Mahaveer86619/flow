import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/ui/app_snack_bar.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'yt_connect_state.dart';

export 'yt_connect_state.dart';

class YTConnectCubit extends Cubit<YTConnectState> {
  static const _tag = 'YTConnectCubit';

  YTConnectCubit() : super(const YTConnectState());

  Future<void> connect(Map<String, String> cookies, String userAgent) async {
    AppLogger.i(_tag, 'Connecting YouTube Music locally via cookies');
    emit(const YTConnectState(status: YTConnectStatus.loading));
    try {
      final cookieString = cookies.entries
          .map((e) => '${e.key}=${e.value}')
          .join('; ');

      await SecureStorageService.instance.saveYoutubeCookies(cookieString);
      await SecureStorageService.instance.saveYoutubeUserAgent(userAgent);

      // EXTREMELY HELPFUL FOR RESEARCH: Dump cookies to a local file if in debug mode
      if (kDebugMode) {
        try {
          // Attempt to find the project root by looking for pubspec.yaml
          // This is a bit of a hack but works if run from the project directory
          final binDir = Directory('bin');
          if (binDir.existsSync()) {
            final cookieFile = File('bin/cookies.txt');
            await cookieFile.writeAsString(cookieString);
            AppLogger.i(
              _tag,
              'DEBUG: Cookies dumped to ${cookieFile.absolute.path}',
            );
          }
        } catch (e) {
          AppLogger.w(_tag, 'DEBUG: Failed to dump cookies to file: $e');
        }
      }

      AppLogger.i(_tag, 'Local YouTube Music connection successful');
      emit(const YTConnectState(status: YTConnectStatus.success));
    } catch (e, st) {
      AppLogger.e(_tag, 'Local YouTube Music connection failed', e, st);
      emit(
        YTConnectState(
          status: YTConnectStatus.error,
          errorMessage: AppSnackBar.humanMessage(e),
        ),
      );
    }
  }

  Future<void> disconnect() async {
    AppLogger.i(_tag, 'Disconnecting YouTube Music locally');
    emit(const YTConnectState(status: YTConnectStatus.loading));
    try {
      await SecureStorageService.instance.saveYoutubeCookies('');
      AppLogger.i(_tag, 'Local YouTube Music disconnection successful');
      emit(const YTConnectState(status: YTConnectStatus.success));
    } catch (e, st) {
      AppLogger.e(_tag, 'Local YouTube Music disconnection failed', e, st);
      emit(
        YTConnectState(
          status: YTConnectStatus.error,
          errorMessage: AppSnackBar.humanMessage(e),
        ),
      );
    }
  }

  void reset() => emit(const YTConnectState());
}

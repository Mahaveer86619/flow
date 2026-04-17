import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/ui/app_snack_bar.dart';
import '../../../data/sources/auth_data_source.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/storage/local_storage.dart';
import 'yt_connect_state.dart';

export 'yt_connect_state.dart';
class YTConnectCubit extends Cubit<YTConnectState> {
  static const _tag = 'YTConnectCubit';
  final AuthDataSource _authSource;
  Timer? _pollTimer;

  YTConnectCubit({AuthDataSource? authSource})
      : _authSource = authSource ?? AuthDataSource(),
        super(const YTConnectState());

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }

  Future<void> startOAuth() async {
    AppLogger.i(_tag, 'Starting YT OAuth flow');
    emit(const YTConnectState(status: YTConnectStatus.loading));
    try {
      final token = LocalStorage.instance.jwtToken;
      if (token == null) {
        emit(const YTConnectState(status: YTConnectStatus.error, errorMessage: 'Not logged in'));
        return;
      }

      final data = await _authSource.initYTOAuth(token);
      final userCode = data['user_code'];
      final verificationUrl = data['verification_url'];
      final deviceCode = data['device_code'];
      final interval = data['interval'] as int? ?? 5;

      emit(YTConnectState(
        status: YTConnectStatus.oauthPending,
        userCode: userCode,
        verificationUrl: verificationUrl,
        deviceCode: deviceCode,
      ));

      _startPolling(token, deviceCode, interval);
    } catch (e, st) {
      AppLogger.e(_tag, 'OAuth init failed', e, st);
      emit(YTConnectState(status: YTConnectStatus.error, errorMessage: AppSnackBar.humanMessage(e)));
    }
  }

  void _startPolling(String token, String deviceCode, int intervalSeconds) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) async {
      try {
        final data = await _authSource.checkYTOAuth(token, deviceCode);
        final status = data['status'];

        if (status == 'success') {
          timer.cancel();
          AppLogger.i(_tag, 'OAuth success');
          emit(const YTConnectState(status: YTConnectStatus.success));
        } else if (status == 'expired' || status == 'declined') {
          timer.cancel();
          AppLogger.w(_tag, 'OAuth $status');
          emit(YTConnectState(status: YTConnectStatus.error, errorMessage: data['message']));
        }
        // If pending, just continue polling
      } catch (e) {
        AppLogger.w(_tag, 'OAuth poll error: $e');
        // Don't stop timer on transient network errors
      }
    });
  }

  Future<void> connect(Map<String, String> cookies) async {
    AppLogger.i(_tag, 'Starting YouTube Music connection process');
    emit(const YTConnectState(status: YTConnectStatus.loading));
    try {
      final token = LocalStorage.instance.jwtToken;
      if (token == null) {
        AppLogger.w(_tag, 'Connection failed: No local session found');
        emit(
          const YTConnectState(
            status: YTConnectStatus.error,
            errorMessage: 'Not logged in',
          ),
        );
        return;
      }
      await _authSource.connectYTCookies(token, cookies);
      AppLogger.i(_tag, 'YouTube Music connection successful');
      emit(const YTConnectState(status: YTConnectStatus.success));
    } catch (e, st) {
      AppLogger.e(_tag, 'YouTube Music connection failed', e, st);
      emit(
        YTConnectState(
          status: YTConnectStatus.error,
          errorMessage: AppSnackBar.humanMessage(e),
        ),
      );
    }
  }

  Future<void> disconnect() async {
    AppLogger.i(_tag, 'Starting YouTube Music disconnection process');
    emit(const YTConnectState(status: YTConnectStatus.loading));
    try {
      final token = LocalStorage.instance.jwtToken;
      if (token == null) {
        AppLogger.w(_tag, 'Disconnection failed: No local session found');
        emit(
          const YTConnectState(
            status: YTConnectStatus.error,
            errorMessage: 'Not logged in',
          ),
        );
        return;
      }
      await _authSource.disconnectYT(token);
      AppLogger.i(_tag, 'YouTube Music disconnection successful');
      emit(const YTConnectState(status: YTConnectStatus.success));
    } catch (e, st) {
      AppLogger.e(_tag, 'YouTube Music disconnection failed', e, st);
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

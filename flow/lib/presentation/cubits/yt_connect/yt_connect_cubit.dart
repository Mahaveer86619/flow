import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/sources/auth_data_source.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/storage/local_storage.dart';
import 'yt_connect_state.dart';

export 'yt_connect_state.dart';

class YTConnectCubit extends Cubit<YTConnectState> {
  static const _tag = 'YTConnectCubit';
  final AuthDataSource _authSource;

  YTConnectCubit({AuthDataSource? authSource})
      : _authSource = authSource ?? AuthDataSource(),
        super(const YTConnectState());

  Future<void> connect(Map<String, String> cookies) async {
    emit(const YTConnectState(status: YTConnectStatus.loading));
    try {
      final token = LocalStorage.instance.jwtToken;
      if (token == null) {
        emit(const YTConnectState(
            status: YTConnectStatus.error,
            errorMessage: 'Not logged in'));
        return;
      }
      await _authSource.connectYTCookies(token, cookies);
      emit(const YTConnectState(status: YTConnectStatus.success));
    } catch (e) {
      AppLogger.e(_tag, 'connect failed', e);
      emit(YTConnectState(
        status: YTConnectStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> disconnect() async {
    emit(const YTConnectState(status: YTConnectStatus.loading));
    try {
      final token = LocalStorage.instance.jwtToken;
      if (token == null) {
        emit(const YTConnectState(
            status: YTConnectStatus.error,
            errorMessage: 'Not logged in'));
        return;
      }
      await _authSource.disconnectYT(token);
      emit(const YTConnectState(status: YTConnectStatus.success));
    } catch (e) {
      AppLogger.e(_tag, 'disconnect failed', e);
      emit(YTConnectState(
        status: YTConnectStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void reset() => emit(const YTConnectState());
}

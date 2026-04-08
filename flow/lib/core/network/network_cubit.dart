import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logger/app_logger.dart';
import 'connectivity_service.dart';

export 'connectivity_service.dart' show NetworkStatus;

// ─────────────────────────────────────────────────────────────────────────────
// NetworkCubit — exposes connectivity as BLoC state so any widget in the
// tree can watch it via context.watch<NetworkCubit>().
// ─────────────────────────────────────────────────────────────────────────────

enum NetworkState { online, offline }

class NetworkCubit extends Cubit<NetworkState> {
  final ConnectivityService _service;
  late final StreamSubscription<NetworkStatus> _sub;

  NetworkCubit(this._service)
      : super(_service.isOnline ? NetworkState.online : NetworkState.offline) {
    AppLogger.i('NetworkCubit', 'Created with initial state: $state');
    _sub = _service.statusStream.listen(_onStatusChanged);
  }

  bool get isOnline => state == NetworkState.online;

  void _onStatusChanged(NetworkStatus s) {
    final next =
        s == NetworkStatus.online ? NetworkState.online : NetworkState.offline;
    AppLogger.i('NetworkCubit', 'Emitting $next');
    emit(next);
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}

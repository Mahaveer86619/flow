import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../logger/app_logger.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConnectivityService — singleton that monitors network reachability.
//
// Uses connectivity_plus v6 (onConnectivityChanged returns
// Stream<List<ConnectivityResult>>).
//
// Initialise with [init()] after AppLogger.init() in main().
// ─────────────────────────────────────────────────────────────────────────────

enum NetworkStatus { online, offline }

class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final _controller = StreamController<NetworkStatus>.broadcast();
  late StreamSubscription<List<ConnectivityResult>> _sub;

  NetworkStatus _current = NetworkStatus.online;

  NetworkStatus get current => _current;
  bool get isOnline => _current == NetworkStatus.online;
  Stream<NetworkStatus> get statusStream => _controller.stream;

  Future<void> init() async {
    final initial = await Connectivity().checkConnectivity();
    _current = _fromList(initial);
    AppLogger.i('Connectivity', 'Initial status: $_current  ($initial)');

    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final status = _fromList(results);
      if (status == _current) return;
      _current = status;
      AppLogger.i('Connectivity', 'Changed → $status  ($results)');
      _controller.add(status);
    });
  }

  static NetworkStatus _fromList(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none)
          ? NetworkStatus.online
          : NetworkStatus.offline;

  void dispose() {
    _sub.cancel();
    _controller.close();
  }
}

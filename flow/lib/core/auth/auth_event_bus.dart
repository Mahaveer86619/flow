import 'dart:async';

/// Global event bus for authentication events.
///
/// Data sources push to this when they encounter a 401 Unauthorized,
/// and the [AuthCubit] listens to it to trigger a global logout.
class AuthEventBus {
  AuthEventBus._();
  static final _unauthorizedController = StreamController<void>.broadcast();

  /// Stream of unauthorized events.
  static Stream<void> get unauthorized => _unauthorizedController.stream;

  /// Notify that an unauthorized response was received.
  static void notifyUnauthorized() {
    _unauthorizedController.add(null);
  }
}

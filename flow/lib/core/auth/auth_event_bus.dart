import 'dart:async';

/// Global event bus for authentication events.
///
/// Data sources push to this when they encounter a 401 Unauthorized,
/// and the [AuthCubit] listens to it to trigger a global logout.
class AuthEventBus {
  AuthEventBus._();
  static final _unauthorizedController = StreamController<void>.broadcast();
  static final _settingsLoadedController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of unauthorized events.
  static Stream<void> get unauthorized => _unauthorizedController.stream;

  /// Stream of remote settings loaded events.
  static Stream<Map<String, dynamic>> get settingsLoaded =>
      _settingsLoadedController.stream;

  /// Notify that an unauthorized response was received.
  static void notifyUnauthorized() {
    _unauthorizedController.add(null);
  }

  /// Notify that remote settings were fetched.
  static void notifySettingsLoaded(Map<String, dynamic> settings) {
    _settingsLoadedController.add(settings);
  }
}

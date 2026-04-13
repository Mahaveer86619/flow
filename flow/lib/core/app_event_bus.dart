import 'dart:async';

/// A simple singleton event bus for app-wide signals.
class AppEventBus {
  AppEventBus._();
  static final AppEventBus instance = AppEventBus._();

  final _controller = StreamController<AppEvent>.broadcast();
  Stream<AppEvent> get events => _controller.stream;

  void fire(AppEvent event) => _controller.add(event);
}

abstract class AppEvent {}

/// Fired when the user wants to retry all failed sections.
class GlobalRetryEvent extends AppEvent {}

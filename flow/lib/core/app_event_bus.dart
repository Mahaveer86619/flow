import 'dart:async';

/// A simple singleton event bus for app-wide signals.
class AppEventBus {
  AppEventBus._();
  static final AppEventBus instance = AppEventBus._();

  final _controller = StreamController<AppEvent>.broadcast();
  Stream<AppEvent> get events => _controller.stream;

  void fire(AppEvent event) => _controller.add(event);
}

abstract class AppEvent {
  const AppEvent();
}

/// Fired when the user wants to retry all failed sections.
class GlobalRetryEvent extends AppEvent {
  const GlobalRetryEvent();
}

/// Fired to refresh the home feed.
class RefreshHomeEvent extends AppEvent {
  const RefreshHomeEvent();
}

/// Fired to switch to a specific tab.
class SwitchTabEvent extends AppEvent {
  final int index;
  const SwitchTabEvent(this.index);
}

/// Fired when a peer sync is completed.
class PeerSyncEvent extends AppEvent {
  final String peerId;
  const PeerSyncEvent(this.peerId);
}

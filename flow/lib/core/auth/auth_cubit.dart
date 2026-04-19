import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logger/app_logger.dart';
import '../storage/local_storage.dart';
import '../storage/secure_storage_service.dart';
import 'auth_event_bus.dart';
import 'auth_state.dart';

export 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  static const _tag = 'AuthCubit';
  StreamSubscription? _unauthorizedSub;

  AuthCubit() : super(const AuthState(isLoading: true)) {
    _init();
    _unauthorizedSub = AuthEventBus.unauthorized.listen((_) {
      AppLogger.w(_tag, 'Received global unauthorized event, logging out');
      logout();
    });
  }

  @override
  Future<void> close() {
    _unauthorizedSub?.cancel();
    return super.close();
  }

  Future<void> _init() async {
    AppLogger.i(_tag, 'Initializing AuthCubit (Standalone)');
    
    // Check local secure storage for cookies
    final ytCookies = await SecureStorageService.instance.getYoutubeCookies();
    final spotifyCookies = await SecureStorageService.instance.getSpotifyCookies();
    
    final hasYt = ytCookies != null && ytCookies.isNotEmpty;
    final hasSpotify = spotifyCookies != null && spotifyCookies.isNotEmpty;

    // In standalone, we always treat the user as "authenticated" locally 
    // to allow access to the home feed and search.
    final token = LocalStorage.instance.jwtToken ?? 'local_session';
    final username = LocalStorage.instance.cachedUsername ?? 'Guest';

    emit(
      AuthState(
        isAuthenticated: true,
        token: token,
        username: username,
        email: LocalStorage.instance.cachedEmail ?? '',
        hasYtAuth: hasYt,
        hasSpotifyAuth: hasSpotify,
      ),
    );
  }

  Future<void> login(String username, String password) async {
    AppLogger.i(_tag, 'login($username) - Standalone (Mock success)');
    emit(state.copyWith(isLoading: true));
    
    // In standalone, we don't have a backend to verify credentials.
    // We just create a local session.
    await Future.delayed(const Duration(milliseconds: 500));
    
    final token = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final user = {
      'username': username,
      'email': '$username@local.flow',
      'has_yt_auth': state.hasYtAuth,
    };
    
    _persist(token, user);
    AppLogger.i(_tag, 'Login flow complete for: $username (Local)');
  }

  Future<void> signup(String username, String email, String password) async {
    AppLogger.i(_tag, 'signup($username) - Standalone (Mock success)');
    emit(state.copyWith(isLoading: true));
    
    await Future.delayed(const Duration(milliseconds: 500));
    await login(username, password);
  }

  Future<void> logout() async {
    AppLogger.i(_tag, 'Logging out — clearing local session');
    LocalStorage.instance.clearAuth();
    if (!isClosed) {
      emit(AuthState(
        hasYtAuth: state.hasYtAuth,
        hasSpotifyAuth: state.hasSpotifyAuth,
      ));
    }
  }

  void setYtAuth(bool connected) {
    AppLogger.i(_tag, 'YouTube Music connection state changed: $connected');
    if (!isClosed) emit(state.copyWith(hasYtAuth: connected));
  }

  void setSpotifyAuth(bool connected) {
    AppLogger.i(_tag, 'Spotify connection state changed: $connected');
    if (!isClosed) emit(state.copyWith(hasSpotifyAuth: connected));
  }

  void _persist(String token, Map<String, dynamic> user) {
    final username = user['username'] as String;
    AppLogger.d(_tag, 'Persisting session for $username');
    LocalStorage.instance.saveAuth(
      token: token,
      username: username,
      email: user['email'] as String,
      hasYtAuth: (user['has_yt_auth'] as bool?) ?? false,
    );
    if (user['settings'] != null) {
      AuthEventBus.notifySettingsLoaded(
        user['settings'] as Map<String, dynamic>,
      );
    }
    if (!isClosed) {
      emit(
        state.copyWith(
          isAuthenticated: true,
          token: token,
          username: username,
          email: user['email'] as String,
          isLoading: false,
        ),
      );
    }
  }
}

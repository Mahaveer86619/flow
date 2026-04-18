import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../error/app_exception.dart';
import '../logger/app_logger.dart';
import '../storage/local_storage.dart';
import '../storage/secure_storage_service.dart';
import '../../data/sources/auth_data_source.dart';
import 'auth_event_bus.dart';
import 'auth_state.dart';

export 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  static const _tag = 'AuthCubit';
  final AuthDataSource _authSource;
  StreamSubscription? _unauthorizedSub;

  AuthCubit({AuthDataSource? authSource})
    : _authSource = authSource ?? AuthDataSource(),
      super(const AuthState(isLoading: true)) {
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
    AppLogger.i(_tag, 'Initializing AuthCubit');
    
    // Check local secure storage for cookies (The new "Standalone" source of truth)
    final ytCookies = await SecureStorageService.instance.getYoutubeCookies();
    final spotifyCookies = await SecureStorageService.instance.getSpotifyCookies();
    
    final hasYt = ytCookies != null && ytCookies.isNotEmpty;
    final hasSpotify = spotifyCookies != null && spotifyCookies.isNotEmpty;

    final token = LocalStorage.instance.jwtToken;
    if (token == null) {
      AppLogger.i(_tag, 'No cached session found');
      emit(AuthState(
        hasYtAuth: hasYt,
        hasSpotifyAuth: hasSpotify,
      ));
      return;
    }

    AppLogger.i(
      _tag,
      'Cached session found for: ${LocalStorage.instance.cachedUsername}',
    );
    emit(
      AuthState(
        isAuthenticated: true,
        token: token,
        username: LocalStorage.instance.cachedUsername,
        email: LocalStorage.instance.cachedEmail,
        hasYtAuth: hasYt,
        hasSpotifyAuth: hasSpotify,
      ),
    );
    _validateToken(token);
  }

  Future<void> _validateToken(String token) async {
    // ── STANDALONE MODE (Phase 2) ──────────────────────────────────────────
    // In a fully standalone app, we don't need to validate the JWT against
    // a legacy server. If the token exists, we treat it as valid for local
    // session persistence. 
    //
    // If we ever implement a new P2P/Decentralized auth, it will go here.
    
    AppLogger.i(_tag, 'Standalone mode: Skipping remote token validation');
    
    // We keep the state as authenticated.
    // If we have YT cookies, the app will work regardless of the server.
    return;
  }

  Future<void> login(String username, String password) async {
    AppLogger.i(_tag, 'login($username) triggered');
    emit(state.copyWith(isLoading: true));
    try {
      final token = await _authSource.login(username, password);
      final user = await _authSource.getMe(token);
      _persist(token, user);
      AppLogger.i(_tag, 'Login flow complete for: $username');
    } catch (e) {
      AppLogger.w(_tag, 'Login failed: $e');
      emit(state.copyWith(isLoading: false));
      rethrow;
    }
  }

  Future<void> signup(String username, String email, String password) async {
    AppLogger.i(_tag, 'signup($username) triggered');
    emit(state.copyWith(isLoading: true));
    try {
      await _authSource.signup(username, email, password);
      AppLogger.i(_tag, 'Signup successful, proceeding to login');
      await login(username, password);
    } catch (e) {
      AppLogger.w(_tag, 'Signup flow failed: $e');
      emit(state.copyWith(isLoading: false));
      rethrow;
    }
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

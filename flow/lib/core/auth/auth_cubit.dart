import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../error/app_exception.dart';
import '../logger/app_logger.dart';
import '../storage/local_storage.dart';
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
    final token = LocalStorage.instance.jwtToken;
    if (token == null) {
      AppLogger.i(_tag, 'No cached session found');
      emit(const AuthState());
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
        hasYtAuth: LocalStorage.instance.cachedHasYtAuth,
      ),
    );
    _validateToken(token);
  }

  Future<void> _validateToken(String token) async {
    AppLogger.d(_tag, 'Validating session token');
    try {
      final user = await _authSource.getMe(token);
      final hasYt = (user['has_yt_auth'] as bool?) ?? false;
      final ytName = user['yt_name'] as String?;
      final ytAvatar = user['yt_avatar_url'] as String?;

      AppLogger.i(_tag, 'Token valid. YT connected: $hasYt');

      LocalStorage.instance.saveHasYtAuth(hasYt);
      if (user['settings'] != null) {
        AppLogger.d(_tag, 'Loading remote user settings');
        AuthEventBus.notifySettingsLoaded(
          user['settings'] as Map<String, dynamic>,
        );
      }
      if (!isClosed) {
        emit(
          state.copyWith(
            hasYtAuth: hasYt,
            ytName: ytName,
            ytAvatarUrl: ytAvatar,
          ),
        );
      }

      // Refresh YT profile if connected but name missing
      if (hasYt && ytName == null) {
        AppLogger.i(_tag, 'YT connected but profile info missing — refreshing');
        try {
          final refreshed = await _authSource.refreshProfile(token);
          if (!isClosed) {
            emit(
              state.copyWith(
                ytName: refreshed['yt_name'] as String?,
                ytAvatarUrl: refreshed['yt_avatar_url'] as String?,
              ),
            );
          }
        } catch (e) {
          AppLogger.w(_tag, 'Failed to refresh YT profile: $e');
        }
      }
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        AppLogger.w(_tag, 'Token expired or invalid, logging out');
        await logout();
      } else {
        AppLogger.e(_tag, 'Server error during token validation', e);
      }
    } catch (e, st) {
      AppLogger.e(_tag, 'Unexpected error during token validation', e, st);
    }
  }

  Future<void> login(String username, String password) async {
    AppLogger.i(_tag, 'login($username) triggered');
    emit(const AuthState(isLoading: true));
    try {
      final token = await _authSource.login(username, password);
      final user = await _authSource.getMe(token);
      _persist(token, user);
      AppLogger.i(_tag, 'Login flow complete for: $username');
    } catch (e) {
      AppLogger.w(_tag, 'Login failed: $e');
      emit(const AuthState());
      rethrow;
    }
  }

  Future<void> signup(String username, String email, String password) async {
    AppLogger.i(_tag, 'signup($username) triggered');
    emit(const AuthState(isLoading: true));
    try {
      await _authSource.signup(username, email, password);
      AppLogger.i(_tag, 'Signup successful, proceeding to login');
      await login(username, password);
    } catch (e) {
      AppLogger.w(_tag, 'Signup flow failed: $e');
      emit(const AuthState());
      rethrow;
    }
  }

  Future<void> logout() async {
    AppLogger.i(_tag, 'Logging out — clearing local session');
    LocalStorage.instance.clearAuth();
    if (!isClosed) emit(const AuthState());
  }

  void setYtAuth(bool connected) {
    AppLogger.i(_tag, 'YouTube Music connection state changed: $connected');
    LocalStorage.instance.saveHasYtAuth(connected);
    if (!isClosed) emit(state.copyWith(hasYtAuth: connected));
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
        AuthState(
          isAuthenticated: true,
          token: token,
          username: username,
          email: user['email'] as String,
          hasYtAuth: (user['has_yt_auth'] as bool?) ?? false,
        ),
      );
    }
  }
}

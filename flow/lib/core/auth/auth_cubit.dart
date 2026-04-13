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
    final token = LocalStorage.instance.jwtToken;
    if (token == null) {
      emit(const AuthState());
      return;
    }
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
    try {
      final user = await _authSource.getMe(token);
      final hasYt = (user['has_yt_auth'] as bool?) ?? false;
      LocalStorage.instance.saveHasYtAuth(hasYt);
      if (user['settings'] != null) {
        AuthEventBus.notifySettingsLoaded(
          user['settings'] as Map<String, dynamic>,
        );
      }
      if (!isClosed) emit(state.copyWith(hasYtAuth: hasYt));
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        AppLogger.w(_tag, 'Token expired, logging out');
        await logout();
      }
    } catch (e) {
      AppLogger.w(_tag, 'Token validation failed: $e');
    }
  }

  Future<void> login(String username, String password) async {
    emit(const AuthState(isLoading: true));
    try {
      final token = await _authSource.login(username, password);
      final user = await _authSource.getMe(token);
      _persist(token, user);
    } catch (_) {
      emit(const AuthState());
      rethrow;
    }
  }

  Future<void> signup(String username, String email, String password) async {
    emit(const AuthState(isLoading: true));
    try {
      await _authSource.signup(username, email, password);
      await login(username, password);
    } catch (_) {
      emit(const AuthState());
      rethrow;
    }
  }

  Future<void> logout() async {
    LocalStorage.instance.clearAuth();
    if (!isClosed) emit(const AuthState());
  }

  void setYtAuth(bool connected) {
    LocalStorage.instance.saveHasYtAuth(connected);
    if (!isClosed) emit(state.copyWith(hasYtAuth: connected));
  }

  void _persist(String token, Map<String, dynamic> user) {
    LocalStorage.instance.saveAuth(
      token: token,
      username: user['username'] as String,
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
          username: user['username'] as String,
          email: user['email'] as String,
          hasYtAuth: (user['has_yt_auth'] as bool?) ?? false,
        ),
      );
    }
  }
}

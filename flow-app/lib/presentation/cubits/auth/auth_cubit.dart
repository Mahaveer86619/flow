import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/storage/local_storage.dart';
import '../../../data/sources/api_song_data_source.dart';
import 'auth_state.dart';

export 'auth_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthCubit
//
// Manages authentication state for the app:
//   - On creation: immediately checks server auth status (isChecking=true).
//   - Persists result to LocalStorage so other cubits get the cached value
//     before the network check completes.
//   - Exposes refresh() and logout() for the auth screen.
//
// The [ApiSongDataSource] is used directly here instead of going through a
// use-case because auth is infra-level, not domain-level.
// ─────────────────────────────────────────────────────────────────────────────

class AuthCubit extends Cubit<AuthState> {
  static const _tag = 'AuthCubit';

  final ApiSongDataSource _api;

  AuthCubit({required ApiSongDataSource api})
      : _api = api,
        super(AuthState(
          isChecking: true,
          // seed from cache so the rest of the app sees a sane value immediately
          isAuthenticated: LocalStorage.instance.isAuthenticated,
        )) {
    AppLogger.i(_tag, 'Created — cached auth=${LocalStorage.instance.isAuthenticated}');
    _checkServer();
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Re-checks auth status with the server (e.g., after login/logout).
  Future<void> refresh() {
    emit(state.copyWith(isChecking: true));
    return _checkServer();
  }

  /// Called after the auth screen successfully submits credentials.
  void onAuthSuccess() {
    LocalStorage.instance.saveIsAuthenticated(true);
    emit(state.copyWith(isChecking: false, isAuthenticated: true));
    AppLogger.i(_tag, 'Marked authenticated');
  }

  /// Submits raw headers / cURL to the server and marks as authenticated.
  Future<void> submitHeaders(String headersOrCurl) async {
    await _api.submitAuthHeaders(headersOrCurl);
    onAuthSuccess();
  }

  /// Clears auth on the server and updates local state.
  Future<void> logout() async {
    AppLogger.i(_tag, 'logout()');
    try {
      await _api.logout();
    } catch (e) {
      AppLogger.w(_tag, 'Logout request failed (continuing anyway): $e');
    }
    LocalStorage.instance.saveIsAuthenticated(false);
    emit(state.copyWith(isChecking: false, isAuthenticated: false));
  }

  // ── Internal ─────────────────────────────────────────────────────────────────

  Future<void> _checkServer() async {
    try {
      final authenticated = await _api.checkAuthStatus();
      if (isClosed) return;
      AppLogger.i(_tag, 'Server auth status: $authenticated');
      LocalStorage.instance.saveIsAuthenticated(authenticated);
      emit(AuthState(isChecking: false, isAuthenticated: authenticated));
    } catch (e) {
      if (isClosed) return;
      // If the server is unreachable, fall back to cached value but stop checking.
      AppLogger.w(_tag, 'Status check failed — using cached: ${LocalStorage.instance.isAuthenticated}');
      emit(AuthState(
        isChecking: false,
        isAuthenticated: LocalStorage.instance.isAuthenticated,
      ));
    }
  }
}

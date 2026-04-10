// ─────────────────────────────────────────────────────────────────────────────
// AuthState — emitted by AuthCubit.
//
// isChecking  — true only during the initial server status check on app start.
// isAuthenticated — whether the server has a valid auth.json on disk.
// ─────────────────────────────────────────────────────────────────────────────

class AuthState {
  final bool isChecking;
  final bool isAuthenticated;

  const AuthState({
    this.isChecking = false,
    this.isAuthenticated = false,
  });

  AuthState copyWith({bool? isChecking, bool? isAuthenticated}) => AuthState(
        isChecking: isChecking ?? this.isChecking,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      );

  @override
  String toString() =>
      'AuthState(isChecking: $isChecking, isAuthenticated: $isAuthenticated)';
}

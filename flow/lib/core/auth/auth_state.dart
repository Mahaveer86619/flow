class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? token;
  final String? username;
  final String? email;
  final bool hasYtAuth;
  final String? ytName;
  final String? ytAvatarUrl;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.token,
    this.username,
    this.email,
    this.hasYtAuth = false,
    this.ytName,
    this.ytAvatarUrl,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? token,
    String? username,
    String? email,
    bool? hasYtAuth,
    String? ytName,
    String? ytAvatarUrl,
  }) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        token: token ?? this.token,
        username: username ?? this.username,
        email: email ?? this.email,
        hasYtAuth: hasYtAuth ?? this.hasYtAuth,
        ytName: ytName ?? this.ytName,
        ytAvatarUrl: ytAvatarUrl ?? this.ytAvatarUrl,
      );
}

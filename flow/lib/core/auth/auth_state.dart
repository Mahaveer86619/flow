class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? token;
  final String? username;
  final String? email;
  final String? error;
  final bool hasYtAuth;
  final bool hasSpotifyAuth;
  final String? ytName;
  final String? ytAvatarUrl;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.token,
    this.username,
    this.email,
    this.error,
    this.hasYtAuth = false,
    this.hasSpotifyAuth = false,
    this.ytName,
    this.ytAvatarUrl,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? token,
    String? username,
    String? email,
    String? error,
    bool? hasYtAuth,
    bool? hasSpotifyAuth,
    String? ytName,
    String? ytAvatarUrl,
  }) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        token: token ?? this.token,
        username: username ?? this.username,
        email: email ?? this.email,
        error: error,
        hasYtAuth: hasYtAuth ?? this.hasYtAuth,
        hasSpotifyAuth: hasSpotifyAuth ?? this.hasSpotifyAuth,
        ytName: ytName ?? this.ytName,
        ytAvatarUrl: ytAvatarUrl ?? this.ytAvatarUrl,
      );
}

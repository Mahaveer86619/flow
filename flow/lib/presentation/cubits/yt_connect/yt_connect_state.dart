enum YTConnectStatus {
  idle,
  loading,
  success,
  error,
  oauthPending, // Waiting for user to enter code on google.com/device
}

class YTConnectState {
  final YTConnectStatus status;
  final String? errorMessage;

  // OAuth details
  final String? userCode;
  final String? verificationUrl;
  final String? deviceCode;

  const YTConnectState({
    this.status = YTConnectStatus.idle,
    this.errorMessage,
    this.userCode,
    this.verificationUrl,
    this.deviceCode,
  });

  bool get isLoading => status == YTConnectStatus.loading;
  bool get isSuccess => status == YTConnectStatus.success;
  bool get isError => status == YTConnectStatus.error;
  bool get isOAuthPending => status == YTConnectStatus.oauthPending;

  YTConnectState copyWith({
    YTConnectStatus? status,
    String? errorMessage,
    String? userCode,
    String? verificationUrl,
    String? deviceCode,
  }) {
    return YTConnectState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      userCode: userCode ?? this.userCode,
      verificationUrl: verificationUrl ?? this.verificationUrl,
      deviceCode: deviceCode ?? this.deviceCode,
    );
  }
}

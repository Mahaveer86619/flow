enum YTConnectStatus { idle, loading, success, error }

class YTConnectState {
  final YTConnectStatus status;
  final String? errorMessage;

  const YTConnectState({
    this.status = YTConnectStatus.idle,
    this.errorMessage,
  });

  bool get isLoading => status == YTConnectStatus.loading;
  bool get isSuccess => status == YTConnectStatus.success;
  bool get isError => status == YTConnectStatus.error;
}

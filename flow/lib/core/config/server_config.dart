// Legacy stub — server-side config removed in standalone mode.
// These references compile but are no longer functional.
class ServerConfig {
  ServerConfig._();
  static final ServerConfig instance = ServerConfig._();
  final String baseUrl = '';
  final String fallbackUrl = '';
  final bool isCustom = false;
  void setCustomUrl(String url) {}
  void clearCustomUrl() {}
}

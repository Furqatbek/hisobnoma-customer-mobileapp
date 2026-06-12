/// Runtime API configuration. Override at build/run time, e.g.:
///   flutter run --dart-define=API_BASE_URL=https://shop.example.com/api/v1 \
///               --dart-define=API_TENANT_ID=1
class ApiConfig {
  /// Base URL up to and including `/api/v1` (paths add `/web/...`).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  /// Tenant header value (single-shop installs default to "1").
  static const String tenantId = String.fromEnvironment(
    'API_TENANT_ID',
    defaultValue: '1',
  );

  /// Shop contact details (not exposed by the API — app config).
  static const String shopPhone =
      String.fromEnvironment('SHOP_PHONE', defaultValue: '+998 71 200 00 00');
  static const String shopTelegram =
      String.fromEnvironment('SHOP_TELEGRAM', defaultValue: '@hisobnoma_shop');

  /// Wallet QR deep-link config. The QR encodes
  /// `$walletQrBase/$tenantSlug/$customerCode` (a public loyalty deep link).
  /// Leave [tenantSlug] empty to source it from the API (/web/me) instead.
  static const String walletQrBase =
      String.fromEnvironment('WALLET_QR_BASE', defaultValue: 'https://hisobnoma.uz/w');
  static const String tenantSlug =
      String.fromEnvironment('API_TENANT_SLUG', defaultValue: '');

  /// Origin (scheme://host:port) used to resolve relative image URLs like
  /// `/uploads/products/1/main.jpg`.
  static String get imageOrigin => Uri.parse(baseUrl).origin;

  /// Resolves a possibly-relative image path to an absolute URL.
  static String? imageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return imageOrigin + (path.startsWith('/') ? path : '/$path');
  }
}

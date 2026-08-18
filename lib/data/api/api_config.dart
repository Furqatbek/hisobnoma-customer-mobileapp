/// Runtime API configuration. Override at build/run time, e.g.:
///   flutter run --dart-define=API_BASE_URL=https://shop.example.com/api/v1 \
///               --dart-define=API_TENANT_ID=1
class ApiConfig {
  /// Base URL up to and including `/api/v1` (paths add `/web/...`).
  /// Defaults to the production shop; point elsewhere for local dev, e.g.
  ///   flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://temurmchj.uz/api/v1',
  );

  /// Tenant header value (single-shop installs default to "1").
  static const String tenantId = String.fromEnvironment(
    'API_TENANT_ID',
    defaultValue: '1',
  );

  /// Whether online card payment (Payme / Click / Uzum) is actually wired up
  /// on the backend. While false, choosing "card" means "pay the courier by
  /// card on delivery" and the online payment screen is skipped entirely —
  /// showing providers whose checkout call would 404 is worse than not
  /// offering them. Flip on once `POST /web/orders/{n}/payment` exists:
  ///   flutter run --dart-define=ONLINE_PAYMENT=true
  static const bool onlinePaymentEnabled =
      bool.fromEnvironment('ONLINE_PAYMENT', defaultValue: false);

  /// Optional comma-separated host allowlist for provider checkout URLs
  /// (empty = allow any HTTPS host). Lock down per deployment, e.g.:
  ///   --dart-define=PAYMENT_HOSTS=checkout.paycom.uz,my.click.uz
  static const String paymentHostAllowlist =
      String.fromEnvironment('PAYMENT_HOSTS', defaultValue: '');

  /// Optional URL the payment provider should redirect back to when done.
  /// Pair with platform app-links to reopen the app (see README).
  static const String paymentReturnUrl =
      String.fromEnvironment('PAYMENT_RETURN_URL', defaultValue: '');

  /// True when the API base uses TLS — money must not move over cleartext.
  static bool get apiIsSecure => baseUrl.startsWith('https://');

  /// Whether a provider checkout URL is safe to hand to the OS: it must be
  /// HTTPS (blocks `payme://`, `intent://`, `javascript:`, cleartext) and,
  /// when [paymentHostAllowlist] is set, come from an allowed host.
  static bool isAllowedPaymentUrl(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme.toLowerCase() != 'https' || uri.host.isEmpty) return false;
    if (paymentHostAllowlist.isEmpty) return true;
    final host = uri.host.toLowerCase();
    return paymentHostAllowlist
        .split(',')
        .map((h) => h.trim().toLowerCase())
        .where((h) => h.isNotEmpty)
        .any((h) => host == h || host.endsWith('.$h'));
  }

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

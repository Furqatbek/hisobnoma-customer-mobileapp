import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Securely persists the web-customer JWT obtained from `POST /web/auth/verify`.
class TokenStore {
  static const _key = 'hisobnoma-shop-jwt';
  final _storage = const FlutterSecureStorage();

  String? _cached;

  /// In-memory token for synchronous interceptor access (loaded once at boot).
  String? get current => _cached;

  Future<String?> load() async {
    _cached = await _storage.read(key: _key);
    return _cached;
  }

  Future<void> save(String token) async {
    _cached = token;
    await _storage.write(key: _key, value: token);
  }

  Future<void> clear() async {
    _cached = null;
    await _storage.delete(key: _key);
  }
}

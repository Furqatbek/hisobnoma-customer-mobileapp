// Named params can't be private, so the private deps below are assigned in the
// initializer list — `prefer_initializing_formals` can't actually apply here.
// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api/api_client.dart';
import '../data/api/token_store.dart';
import '../data/format.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import '../data/strings.dart';

const _otpUntilKey = 'hisobnoma-shop-otp-until';

/// The authenticated customer's world: the session itself, the OTP-resend
/// throttle, the server-backed wishlist and the unread-notification count —
/// all created/cleared together on login/logout/expiry. Toasting is delegated
/// back to the app via [_toast]; navigation is left to the facade.
class SessionController extends ChangeNotifier {
  SessionController({
    required SharedPreferences prefs,
    required TokenStore tokens,
    required ApiClient api,
    required this.auth,
    required this.wishlistApi,
    required this.notificationsApi,
    required this.deviceTokens,
    required void Function(String) toast,
  })  : _prefs = prefs,
        _tokens = tokens,
        _api = api,
        _toast = toast {
    final until = _prefs.getInt(_otpUntilKey);
    if (until != null) otpCooldownUntil = DateTime.fromMillisecondsSinceEpoch(until);
    _api.onUnauthorized = _onUnauthorized;
  }

  final SharedPreferences _prefs;
  final TokenStore _tokens;
  final ApiClient _api;
  final void Function(String) _toast;
  final AuthRepository auth;
  final WishlistRepository wishlistApi;
  final NotificationRepository notificationsApi;
  final DeviceTokenRepository deviceTokens;

  // ── session ────────────────────────────────────────────────
  ShopUser? user;
  bool get isLoggedIn => user != null;

  /// When the OTP-resend throttle expires. Held here (and persisted) rather
  /// than in the login screen's state, so leaving and re-opening login can't
  /// reset the client-side cooldown.
  DateTime? otpCooldownUntil;
  int get otpCooldownRemaining {
    final u = otpCooldownUntil;
    if (u == null) return 0;
    final s = u.difference(DateTime.now()).inMilliseconds / 1000;
    return s <= 0 ? 0 : s.ceil();
  }

  void startOtpCooldown([int seconds = 60]) {
    otpCooldownUntil = DateTime.now().add(Duration(seconds: seconds));
    _prefs.setInt(_otpUntilKey, otpCooldownUntil!.millisecondsSinceEpoch);
    notifyListeners();
  }

  // ── wishlist (server-backed) ───────────────────────────────
  List<WishlistItem> wishlistItems = [];
  Set<int> wishlistIds = {};
  int get wishAlertCount => wishlistItems.where((w) => w.priceDrop).length;
  bool isWished(int id) => wishlistIds.contains(id);

  // ── notifications ──────────────────────────────────────────
  int unreadCount = 0;

  Future<void> refreshUnread() async {
    if (!isLoggedIn) return;
    try {
      unreadCount = await notificationsApi.unreadCount();
      notifyListeners();
    } catch (_) {}
  }

  /// Locally decrement the badge when one notification is opened.
  void noteRead() {
    if (unreadCount > 0) {
      unreadCount--;
      notifyListeners();
    }
  }

  Future<void> markAllNotificationsRead() async {
    unreadCount = 0;
    notifyListeners();
    try {
      await notificationsApi.markAllRead();
    } catch (_) {}
  }

  // ── bootstrap (restore session on launch) ──────────────────
  Future<void> bootstrap() async {
    try {
      user = await auth.me();
      await refreshWishlist();
      await refreshUnread();
    } catch (_) {
      user = null; // no/expired token
    }
    notifyListeners();
  }

  // ── auth ───────────────────────────────────────────────────
  Future<void> requestOtp(String local9) async {
    await auth.requestOtp(phoneToE164(local9));
    startOtpCooldown(); // throttle survives screen re-entry / restart
  }

  Future<void> verifyOtp(String local9, String code, {String? name, String? referralCode}) async {
    final session = await auth.verify(phoneToE164(local9), code, name: name, referralCode: referralCode);
    await _tokens.save(session.token);
    // Pull the full profile (customerCode etc.); fall back to the verify payload.
    try {
      user = await auth.me();
    } catch (_) {
      user = ShopUser(phone: phoneFromE164(session.phone), name: session.name);
    }
    await refreshWishlist();
    await refreshUnread();
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await deviceTokens.removeAll();
    } catch (_) {}
    await _tokens.clear();
    _clearSession();
    notifyListeners();
  }

  void _onUnauthorized() {
    final wasLoggedIn = user != null;
    _tokens.clear();
    _clearSession();
    // Explain the drop — but only if we thought we were logged in, so a stale
    // token at cold start doesn't toast on every launch.
    if (wasLoggedIn) {
      _toast(tr2('Сессия тугади. Қайта киринг.', 'Сессия истекла. Войдите снова.'));
    }
    notifyListeners();
  }

  void _clearSession() {
    user = null;
    wishlistItems = [];
    wishlistIds = {};
    unreadCount = 0;
  }

  // ── wishlist (server) ──────────────────────────────────────
  Future<void> refreshWishlist() async {
    if (!isLoggedIn) return;
    try {
      final page = await wishlistApi.list(size: 50);
      wishlistItems = page.content;
      wishlistIds = wishlistItems.map((w) => w.catalogItemId).toSet();
    } catch (_) {}
  }

  /// Toggle a like. Returns false (and does nothing) when not logged in, so the
  /// caller can route to login — per the API contract.
  bool toggleWish(int id) {
    if (!isLoggedIn) return false;
    final wasWished = wishlistIds.contains(id);
    if (wasWished) {
      wishlistIds.remove(id);
      wishlistItems.removeWhere((w) => w.catalogItemId == id);
      _toast(tr('Севимлилардан олиб ташланди'));
    } else {
      wishlistIds.add(id);
      _toast(tr('Севимлиларга қўшилди'));
    }
    notifyListeners();
    () async {
      try {
        wasWished ? await wishlistApi.unlike(id) : await wishlistApi.like(id);
        await refreshWishlist();
        notifyListeners();
      } catch (_) {
        // revert on failure
        if (wasWished) {
          wishlistIds.add(id);
        } else {
          wishlistIds.remove(id);
        }
        notifyListeners();
      }
    }();
    return true;
  }
}

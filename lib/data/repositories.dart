import 'api/api_client.dart';
import 'api/api_config.dart';
import 'models.dart';

/// One repository per domain of the public mobile API.

class CatalogRepository {
  CatalogRepository(this._c);
  final ApiClient _c;

  Future<List<Category>> categories() async {
    final data = await _c.getData('/web/catalog/categories') as List? ?? [];
    return data.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Page<Product>> products({String? search, int? categoryId, int page = 0, int size = 20}) {
    return _c.getPage('/web/catalog/products', Product.fromJson, query: {
      if (search != null && search.isNotEmpty) 'search': search,
      'categoryId': ?categoryId,
      'page': page,
      'size': size,
    });
  }

  Future<Product> product(int id) async =>
      Product.fromJson(await _c.getData('/web/catalog/products/$id') as Map<String, dynamic>);
}

class DeliveryRepository {
  DeliveryRepository(this._c);
  final ApiClient _c;

  Future<List<Region>> regions() async {
    final data = await _c.getData('/web/delivery/regions') as List? ?? [];
    return data.map((e) => Region.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Village>> villages({int? regionId}) async {
    final data = await _c.getData('/web/delivery/villages',
        query: {'regionId': ?regionId}) as List? ?? [];
    return data.map((e) => Village.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class CartRepository {
  CartRepository(this._c);
  final ApiClient _c;

  Future<CartPricing> price(Map<int, int> lines) async {
    final data = await _c.postData('/web/cart/price', body: {
      'lines': lines.entries.map((e) => {'catalogItemId': e.key, 'quantity': e.value}).toList(),
    });
    return CartPricing.fromJson(data as Map<String, dynamic>);
  }

  /// Returns the discount if valid, or null if the code is rejected.
  Future<double?> validateCoupon(String code, Map<int, int> lines) async {
    final data = await _c.postData('/web/cart/validate-coupon', body: {
      'code': code,
      'lines': lines.entries.map((e) => {'catalogItemId': e.key, 'quantity': e.value}).toList(),
    }) as Map<String, dynamic>;
    return data['valid'] == true ? (data['discount'] as num).toDouble() : null;
  }
}

class OrderRepository {
  OrderRepository(this._c);
  final ApiClient _c;

  Future<Order> create({
    required String customerName,
    required String phoneE164,
    int? regionId,
    int? villageId,
    String? address,
    String? note,
    String? couponCode,
    int? pointsToSpend,
    String? paymentMethod,
    required Map<int, int> lines,
  }) async {
    final data = await _c.postData('/web/orders', body: {
      'customerName': customerName,
      'phone': phoneE164,
      'regionId': ?regionId,
      'villageId': ?villageId,
      if (address != null && address.isNotEmpty) 'address': address,
      if (note != null && note.isNotEmpty) 'note': note,
      if (couponCode != null && couponCode.isNotEmpty) 'couponCode': couponCode,
      if (pointsToSpend != null && pointsToSpend > 0) 'pointsToSpend': pointsToSpend,
      if (paymentMethod != null && paymentMethod.isNotEmpty) 'paymentMethod': paymentMethod,
      'lines': lines.entries.map((e) => {'catalogItemId': e.key, 'quantity': e.value}).toList(),
    });
    return Order.fromJson(data as Map<String, dynamic>);
  }

  Future<Order> lookup(String orderNumber, String phoneE164) async =>
      Order.fromJson(await _c.getData('/web/orders/$orderNumber', query: {'phone': phoneE164})
          as Map<String, dynamic>);

  Future<Page<Order>> myOrders({int page = 0, int size = 20}) =>
      _c.getPage('/web/me/orders', Order.fromJson, query: {'page': page, 'size': size});
}

/// Online payment for an order. The phone authorises *creating* a payment and
/// is sent in the POST body (never a query string); status is then polled by
/// the opaque payment id the create call returns, so no PII rides in URLs.
class PaymentRepository {
  PaymentRepository(this._c);
  final ApiClient _c;

  /// Creates (or returns the pending) payment and the provider checkout URL.
  Future<OrderPayment> create(String orderNumber,
      {required String phoneE164, required String provider}) async {
    final data = await _c.postData('/web/orders/$orderNumber/payment', body: {
      'phone': phoneE164,
      'provider': provider,
      if (ApiConfig.paymentReturnUrl.isNotEmpty) 'returnUrl': ApiConfig.paymentReturnUrl,
    });
    return OrderPayment.fromJson(data as Map<String, dynamic>);
  }

  /// Current status of a payment, by its opaque id (no PII in the URL).
  Future<OrderPayment> status(String paymentId) async {
    final data = await _c.getData('/web/payments/$paymentId');
    return OrderPayment.fromJson(data as Map<String, dynamic>);
  }
}

class AuthRepository {
  AuthRepository(this._c);
  final ApiClient _c;

  Future<void> requestOtp(String phoneE164) =>
      _c.postData('/web/auth/request-otp', body: {'phone': phoneE164});

  Future<AuthSession> verify(String phoneE164, String code, {String? name, String? referralCode}) async {
    final data = await _c.postData('/web/auth/verify', body: {
      'phone': phoneE164,
      'code': code,
      if (name != null && name.isNotEmpty) 'name': name,
      if (referralCode != null && referralCode.isNotEmpty) 'referralCode': referralCode,
    });
    return AuthSession.fromJson(data as Map<String, dynamic>);
  }

  Future<ShopUser> me() async => ShopUser.fromJson(await _c.getData('/web/me') as Map<String, dynamic>);
}

class LoyaltyRepository {
  LoyaltyRepository(this._c);
  final ApiClient _c;
  Future<LoyaltyData> loyalty() async =>
      LoyaltyData.fromJson(await _c.getData('/web/me/loyalty') as Map<String, dynamic>);
}

class WishlistRepository {
  WishlistRepository(this._c);
  final ApiClient _c;

  Future<Page<WishlistItem>> list({int page = 0, int size = 20}) =>
      _c.getPage('/web/me/wishlist', WishlistItem.fromJson, query: {'page': page, 'size': size});

  Future<List<int>> ids() async {
    final data = await _c.getData('/web/me/wishlist/ids') as List? ?? [];
    return data.map((e) => (e as num).toInt()).toList();
  }

  Future<void> like(int id) => _c.put('/web/me/wishlist/$id');
  Future<void> unlike(int id) => _c.delete('/web/me/wishlist/$id');
}

class ReferralRepository {
  ReferralRepository(this._c);
  final ApiClient _c;
  Future<String> code() async {
    final data = await _c.getData('/web/me/referral-code') as Map<String, dynamic>;
    return (data['code'] ?? '') as String;
  }

  Future<ReferralStats> stats() async =>
      ReferralStats.fromJson(await _c.getData('/web/me/referral-stats') as Map<String, dynamic>);
}

class NotificationRepository {
  NotificationRepository(this._c);
  final ApiClient _c;

  Future<Page<ShopNotification>> list({int page = 0, int size = 20}) =>
      _c.getPage('/web/me/notifications', ShopNotification.fromJson, query: {'page': page, 'size': size});

  Future<int> unreadCount() async {
    final data = await _c.getData('/web/me/notifications/unread-count') as Map<String, dynamic>;
    return (data['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(int id) => _c.put('/web/me/notifications/$id/read');
  Future<void> markAllRead() => _c.put('/web/me/notifications/read-all');
}

class CouponRepository {
  CouponRepository(this._c);
  final ApiClient _c;
  Future<List<Coupon>> list() async {
    final data = await _c.getData('/web/me/coupons') as List? ?? [];
    return data.map((e) => Coupon.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class DeviceTokenRepository {
  DeviceTokenRepository(this._c);
  final ApiClient _c;
  Future<void> register(String token, String platform) =>
      _c.postData('/web/me/device-token', body: {'token': token, 'platform': platform});
  Future<void> removeAll() => _c.delete('/web/me/device-token');
}

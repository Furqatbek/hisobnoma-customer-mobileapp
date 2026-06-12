import 'package:flutter/widgets.dart';

import 'api/api_config.dart';

double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;
int _i(dynamic v) => (v as num?)?.toInt() ?? 0;

class Category {
  final int id;
  final String name;
  const Category({required this.id, required this.name});
  factory Category.fromJson(Map<String, dynamic> j) =>
      Category(id: _i(j['id']), name: (j['name'] ?? '') as String);
}

class Product {
  final int id;
  final String name;
  final String shortDescription;
  final String description;

  /// Original list price.
  final double basePrice;

  /// Discounted price when a web promotion applies (else null).
  final double? salePrice;
  final String? promotionLabel;
  final int categoryId;
  final String categoryName;
  final String? brandName;
  final String unitName;
  final bool inStock;
  final List<String> imageUrls; // absolute, resolved

  const Product({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.description,
    required this.basePrice,
    this.salePrice,
    this.promotionLabel,
    required this.categoryId,
    required this.categoryName,
    this.brandName,
    required this.unitName,
    required this.inStock,
    this.imageUrls = const [],
  });

  /// Effective price shown as the main figure.
  double get price => salePrice ?? basePrice;

  /// Struck-through original price when discounted.
  double? get oldPrice => salePrice != null ? basePrice : null;

  String? get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  factory Product.fromJson(Map<String, dynamic> j) {
    final imgs = <String>[];
    final list = j['images'];
    if (list is List) {
      for (final p in list) {
        final u = ApiConfig.imageUrl(p as String?);
        if (u != null) imgs.add(u);
      }
    }
    if (imgs.isEmpty) {
      final u = ApiConfig.imageUrl(j['imageUrl'] as String?);
      if (u != null) imgs.add(u);
    }
    return Product(
      id: _i(j['id']),
      name: (j['name'] ?? '') as String,
      shortDescription: (j['shortDescription'] ?? '') as String,
      description: (j['description'] ?? '') as String,
      basePrice: _d(j['price']),
      salePrice: j['salePrice'] == null ? null : _d(j['salePrice']),
      promotionLabel: j['promotionLabel'] as String?,
      categoryId: _i(j['categoryId']),
      categoryName: (j['categoryName'] ?? '') as String,
      brandName: j['brandName'] as String?,
      unitName: (j['unitName'] ?? '') as String,
      inStock: j['inStock'] == true,
      imageUrls: imgs,
    );
  }
}

class Region {
  final int id;
  final String name;
  final double deliveryFee;
  const Region({required this.id, required this.name, required this.deliveryFee});
  factory Region.fromJson(Map<String, dynamic> j) =>
      Region(id: _i(j['id']), name: (j['name'] ?? '') as String, deliveryFee: _d(j['deliveryFee']));
}

class Village {
  final int id;
  final String name;
  final int regionId;
  const Village({required this.id, required this.name, required this.regionId});
  factory Village.fromJson(Map<String, dynamic> j) =>
      Village(id: _i(j['id']), name: (j['name'] ?? '') as String, regionId: _i(j['regionId']));
}

class OrderLine {
  final String productName;
  final num quantity;
  final double unitPrice;
  final double lineTotal;
  const OrderLine({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });
  factory OrderLine.fromJson(Map<String, dynamic> j) => OrderLine(
        productName: (j['productName'] ?? '') as String,
        quantity: (j['quantity'] as num?) ?? 0,
        unitPrice: _d(j['unitPrice']),
        lineTotal: _d(j['lineTotal']),
      );
}

class Order {
  final String orderNumber;
  final String status;
  final double deliveryFee;
  final double discountTotal;
  final String? couponCode;
  final double couponDiscount;
  final double pointsSpent;
  final double totalAmount;

  /// CASH | CARD; empty when the API doesn't expose it (legacy orders).
  final String paymentMethod;
  final String createdAt; // ISO 8601
  final List<OrderLine> lines;

  const Order({
    required this.orderNumber,
    required this.status,
    required this.deliveryFee,
    required this.discountTotal,
    this.couponCode,
    required this.couponDiscount,
    required this.pointsSpent,
    required this.totalAmount,
    this.paymentMethod = '',
    required this.createdAt,
    required this.lines,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        orderNumber: (j['orderNumber'] ?? '') as String,
        status: (j['status'] ?? 'NEW') as String,
        deliveryFee: _d(j['deliveryFee']),
        discountTotal: _d(j['discountTotal']),
        couponCode: j['couponCode'] as String?,
        couponDiscount: _d(j['couponDiscount']),
        pointsSpent: _d(j['pointsSpent']),
        totalAmount: _d(j['totalAmount']),
        paymentMethod: ((j['paymentMethod'] ?? '') as String).toUpperCase(),
        createdAt: (j['createdAt'] ?? '') as String,
        lines: ((j['lines'] as List?) ?? [])
            .map((e) => OrderLine.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class LoyaltyEntry {
  final int id;
  final String type; // EARN | SPEND | EXPIRE | ADJUST
  final double amount;
  final String? orderNumber;
  final String? note;
  final String createdAt;
  const LoyaltyEntry({
    required this.id,
    required this.type,
    required this.amount,
    this.orderNumber,
    this.note,
    required this.createdAt,
  });
  factory LoyaltyEntry.fromJson(Map<String, dynamic> j) => LoyaltyEntry(
        id: _i(j['id']),
        type: (j['type'] ?? '') as String,
        amount: _d(j['amount']),
        orderNumber: j['orderNumber'] as String?,
        note: j['note'] as String?,
        createdAt: (j['createdAt'] ?? '') as String,
      );
}

class LoyaltyData {
  final double balance;
  final bool enabled;
  final double minRedeem;
  final int maxRedeemPercent;
  final List<LoyaltyEntry> entries;
  const LoyaltyData({
    required this.balance,
    required this.enabled,
    required this.minRedeem,
    required this.maxRedeemPercent,
    required this.entries,
  });
  factory LoyaltyData.fromJson(Map<String, dynamic> j) => LoyaltyData(
        balance: _d(j['balance']),
        enabled: j['enabled'] == true,
        minRedeem: _d(j['minRedeem']),
        maxRedeemPercent: _i(j['maxRedeemPercent']),
        entries: ((j['entries'] as List?) ?? [])
            .map((e) => LoyaltyEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class WishlistItem {
  final int catalogItemId;
  final String name;
  final double basePrice;
  final double? salePrice;
  final String? promotionLabel;
  final bool inStock;
  final bool available;
  final List<String> imageUrls;
  final String addedAt;
  final bool priceDrop;

  const WishlistItem({
    required this.catalogItemId,
    required this.name,
    required this.basePrice,
    this.salePrice,
    this.promotionLabel,
    required this.inStock,
    required this.available,
    this.imageUrls = const [],
    required this.addedAt,
    required this.priceDrop,
  });

  double get price => salePrice ?? basePrice;
  double? get oldPrice => salePrice != null ? basePrice : null;
  String? get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  factory WishlistItem.fromJson(Map<String, dynamic> j) {
    final u = ApiConfig.imageUrl(j['imageUrl'] as String?);
    return WishlistItem(
      catalogItemId: _i(j['catalogItemId']),
      name: (j['name'] ?? '') as String,
      basePrice: _d(j['price']),
      salePrice: j['salePrice'] == null ? null : _d(j['salePrice']),
      promotionLabel: j['promotionLabel'] as String?,
      inStock: j['inStock'] == true,
      available: j['available'] == true,
      imageUrls: u == null ? const [] : [u],
      addedAt: (j['addedAt'] ?? '') as String,
      priceDrop: j['priceDrop'] == true,
    );
  }
}

/// Authenticated session returned by `POST /web/auth/verify`.
class AuthSession {
  final String token;
  final String phone;
  final String name;
  const AuthSession({required this.token, required this.phone, required this.name});
  factory AuthSession.fromJson(Map<String, dynamic> j) => AuthSession(
        token: (j['token'] ?? '') as String,
        phone: (j['phone'] ?? '') as String,
        name: (j['name'] ?? '') as String,
      );
}

/// Current customer (from `/web/me` or the verify response).
class ShopUser {
  final String phone;
  final String name;

  /// Public loyalty identifier (e.g. "WC-00001"); empty until the API exposes
  /// it on /web/me. Used to build the wallet QR deep link.
  final String customerCode;

  /// Tenant slug for the deep link; empty falls back to ApiConfig.tenantSlug.
  final String tenantSlug;

  const ShopUser({
    required this.phone,
    required this.name,
    this.customerCode = '',
    this.tenantSlug = '',
  });

  factory ShopUser.fromJson(Map<String, dynamic> j) => ShopUser(
        phone: (j['phone'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        customerCode: (j['customerCode'] ?? '') as String,
        tenantSlug: (j['tenantSlug'] ?? '') as String,
      );
}

/// Cart pricing preview from `POST /web/cart/price`.
class CartPricing {
  final double subtotal;
  final double discountTotal;
  final double total;
  final List<String> appliedPromotions;
  const CartPricing({
    required this.subtotal,
    required this.discountTotal,
    required this.total,
    required this.appliedPromotions,
  });
  factory CartPricing.fromJson(Map<String, dynamic> j) => CartPricing(
        subtotal: _d(j['subtotal']),
        discountTotal: _d(j['discountTotal']),
        total: _d(j['total']),
        appliedPromotions:
            ((j['appliedPromotions'] as List?) ?? []).map((e) => e.toString()).toList(),
      );
}

/// In-app notification from `/web/me/notifications` (persisted push history).
class ShopNotification {
  final int id;
  final String type;
  final String title;
  final String body;
  final bool read;
  final String createdAt;
  const ShopNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });
  factory ShopNotification.fromJson(Map<String, dynamic> j) => ShopNotification(
        id: _i(j['id']),
        type: (j['type'] ?? '') as String,
        title: (j['title'] ?? '') as String,
        body: (j['body'] ?? j['message'] ?? '') as String,
        read: j['read'] == true,
        createdAt: (j['createdAt'] ?? '') as String,
      );
}

/// A coupon available to the customer (`/web/me/coupons`). Field names mirror
/// the documented coupon/promotion DTOs, read defensively.
class Coupon {
  final String code;
  final String title;
  final String? discountType; // PERCENT* | FIXED/AMOUNT
  final double? discountValue;
  final String? endDate;
  final double? minOrderAmount;
  const Coupon({
    required this.code,
    required this.title,
    this.discountType,
    this.discountValue,
    this.endDate,
    this.minOrderAmount,
  });

  bool get isPercent => (discountType ?? '').toUpperCase().startsWith('PERC');
  bool get isFixed => (discountType ?? '').toUpperCase().startsWith('FIX');

  factory Coupon.fromJson(Map<String, dynamic> j) => Coupon(
        code: (j['code'] ?? '') as String,
        title: (j['description'] ?? '') as String,
        discountType: j['discountType'] as String?,
        discountValue: j['discountValue'] == null ? null : _d(j['discountValue']),
        endDate: j['endDate'] as String?, // LocalDate "YYYY-MM-DD", may be null
        minOrderAmount: j['minOrderAmount'] == null ? null : _d(j['minOrderAmount']),
      );
}

/// Referral dashboard from `/web/me/referral-stats`.
class ReferralStats {
  final String code;
  final bool enabled;
  final int invitedCount;
  final double pointsEarned;
  const ReferralStats({
    required this.code,
    required this.enabled,
    required this.invitedCount,
    required this.pointsEarned,
  });
  factory ReferralStats.fromJson(Map<String, dynamic> j) => ReferralStats(
        code: (j['code'] ?? '') as String,
        enabled: j['enabled'] != false,
        invitedCount: _i(j['invitedCount']),
        pointsEarned: _d(j['pointsEarned']),
      );
}

// ── Order status presentation (UI mapping, not feed data) ───────────────────
class OrderStatusMeta {
  final String label;
  final Color color;
  final Color bg;
  const OrderStatusMeta({required this.label, required this.color, required this.bg});
}

const orderStatus = <String, OrderStatusMeta>{
  'NEW': OrderStatusMeta(label: 'Янги', color: Color(0xFFE8730C), bg: Color.fromRGBO(232, 115, 12, 0.12)),
  'CONFIRMED': OrderStatusMeta(label: 'Тасдиқланган', color: Color(0xFF1D6FE0), bg: Color.fromRGBO(29, 111, 224, 0.10)),
  'DELIVERING': OrderStatusMeta(label: 'Етказилмоқда', color: Color(0xFFB07E0A), bg: Color.fromRGBO(176, 126, 10, 0.12)),
  'COMPLETED': OrderStatusMeta(label: 'Бажарилган', color: Color(0xFF1E8A4C), bg: Color.fromRGBO(30, 138, 76, 0.12)),
  'CANCELLED': OrderStatusMeta(label: 'Бекор қилинган', color: Color(0xFFD63B2F), bg: Color.fromRGBO(214, 59, 47, 0.10)),
};

// ── Payment method presentation (UI mapping, labels run through tr()) ───────
class PaymentMethodMeta {
  final String label; // short name on summaries / order cards
  final String hint; // checkout option subtitle
  const PaymentMethodMeta({required this.label, required this.hint});
}

const paymentMethods = <String, PaymentMethodMeta>{
  'CASH': PaymentMethodMeta(label: 'Нақд пул', hint: 'Етказиб берилганда нақд тўлайсиз'),
  'CARD': PaymentMethodMeta(label: 'Карта орқали', hint: 'Етказиб берилганда карта орқали тўлайсиз'),
};

/// Online payment state of an order, from `/web/orders/{n}/payment`.
class OrderPayment {
  final String status; // PENDING | PAID | FAILED | CANCELLED | NONE
  final String provider; // PAYME | CLICK | UZUM | ''
  final String paymentUrl; // provider checkout page (empty when n/a)
  final double amount;
  const OrderPayment({
    required this.status,
    required this.provider,
    required this.paymentUrl,
    required this.amount,
  });

  bool get isPaid => status == 'PAID';
  bool get isFailed => status == 'FAILED' || status == 'CANCELLED';

  factory OrderPayment.fromJson(Map<String, dynamic> j) => OrderPayment(
        status: ((j['status'] ?? '') as String).toUpperCase(),
        provider: ((j['provider'] ?? '') as String).toUpperCase(),
        paymentUrl: (j['paymentUrl'] ?? j['url'] ?? '') as String,
        amount: _d(j['amount']),
      );
}

/// Online payment providers offered on the payment screen. Brand names stay
/// untranslated; [color] tints the wordmark tile.
class PaymentProviderMeta {
  final String name;
  final Color color;
  const PaymentProviderMeta({required this.name, required this.color});
}

const paymentProviders = <String, PaymentProviderMeta>{
  'PAYME': PaymentProviderMeta(name: 'Payme', color: Color(0xFF00A6A6)),
  'CLICK': PaymentProviderMeta(name: 'Click', color: Color(0xFF0073EF)),
  'UZUM': PaymentProviderMeta(name: 'Uzum Bank', color: Color(0xFF7000FF)),
};

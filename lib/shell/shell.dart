import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/strings.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/components.dart';
import '../widgets/icons.dart';
import '../screens/catalog.dart';
import '../screens/cart.dart';
import '../screens/account.dart';
import '../screens/extras.dart';
import '../screens/wishlist.dart';

/// Root shell — renders the active tab's top screen with the prototype's slide
/// transitions, the bottom tab bar (hidden on pushed screens) and the toast.
class ShopShell extends StatelessWidget {
  const ShopShell({super.key});

  Widget _buildScreen(AppState app) {
    final s = app.screen;
    switch (s.name) {
      case 'catalog':
        return CatalogScreen(app: app);
      case 'product':
        return ProductDetailScreen(app: app, productId: s.productId!);
      case 'cart':
        return CartScreen(app: app);
      case 'checkout':
        return CheckoutScreen(app: app);
      case 'success':
        return OrderSuccessScreen(app: app, orderNumber: s.orderNumber!, total: s.total!);
      case 'profile':
        return ProfileScreen(app: app);
      case 'login':
        return LoginScreen(app: app);
      case 'status':
        return OrderStatusScreen(app: app, initialOrderNumber: s.orderNumber);
      case 'notifications':
        return NotificationsScreen(app: app);
      case 'wallet':
        return WalletScreen(app: app);
      case 'coupons':
        return CouponsScreen(app: app);
      case 'referrals':
        return ReferralsScreen(app: app);
      case 'wishlist':
        return WishlistScreen(app: app);
    }
    return CatalogScreen(app: app);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    gLang = app.lang; // keep the global in sync before children read tr()
    final screenKey = '${app.tab}-${app.stack.length}-${app.screen.name}';

    return Container(
      color: AppColors.bg,
      child: Stack(
        children: [
          Positioned.fill(
            child: _ScreenTransition(
              key: ValueKey(screenKey),
              motion: app.motion,
              child: _buildScreen(app),
            ),
          ),
          if (app.showTabBar)
            Positioned(left: 0, right: 0, bottom: 0, child: _TabBar(app: app)),
          Toast(message: app.toastMsg, show: app.toastShow),
        ],
      ),
    );
  }
}

// ── Per-screen entrance transition (incoming only, like the prototype) ──────
class _ScreenTransition extends StatefulWidget {
  final NavMotion motion;
  final Widget child;
  const _ScreenTransition({super.key, required this.motion, required this.child});

  @override
  State<_ScreenTransition> createState() => _ScreenTransitionState();
}

class _ScreenTransitionState extends State<_ScreenTransition> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  @override
  void initState() {
    super.initState();
    if (widget.motion == NavMotion.none) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.motion == NavMotion.none) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_c.value);
        double dx;
        double opacity;
        if (widget.motion == NavMotion.push) {
          dx = 1 - t; // 100% → 0
          opacity = 1;
        } else {
          dx = -0.3 * (1 - t); // -30% → 0
          opacity = 0.6 + 0.4 * t;
        }
        return FractionalTranslation(
          translation: Offset(dx, 0),
          child: Opacity(opacity: opacity, child: child),
        );
      },
    );
  }
}

// ── Tab bar ─────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final AppState app;
  const _TabBar({required this.app});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final tabs = <(String, String, Widget Function(Color))>[
      ('catalog', 'Каталог', (c) => Ic.grid(c, 25)),
      ('cart', 'Сават', (c) => Ic.cart(c, 25)),
      ('wallet', 'Ҳамён', (c) => Ic.qr(c, 25)),
      ('wishlist', 'Севимлилар', (c) => Ic.heart(c, 25)),
      ('profile', 'Профил', (c) => Ic.person(c, 25)),
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: blur18,
        child: Container(
          padding: EdgeInsets.only(top: 6, bottom: bottomInset > 0 ? bottomInset : 12),
          decoration: const BoxDecoration(
            color: Color.fromRGBO(255, 255, 255, 0.88),
            border: Border(top: BorderSide(color: AppColors.sep, width: 0.5)),
          ),
          child: Row(
            children: [
              for (final t in tabs)
                Expanded(
                  child: _TabButton(
                    active: app.tab == t.$1,
                    label: tr(t.$2),
                    iconBuilder: t.$3,
                    onTap: () => app.setTab(t.$1),
                    badge: t.$1 == 'cart'
                        ? (app.cartCount > 0 ? _Badge(count: app.cartCount, color: AppColors.red, bounceToken: app.bounceToken) : null)
                        : t.$1 == 'wishlist'
                            ? (app.wishAlertCount > 0 ? _Badge(count: app.wishAlertCount, color: AppColors.accent) : null)
                            : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final bool active;
  final String label;
  final Widget Function(Color) iconBuilder;
  final VoidCallback onTap;
  final Widget? badge;
  const _TabButton({
    required this.active,
    required this.label,
    required this.iconBuilder,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : const Color.fromRGBO(60, 60, 67, 0.55);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 25,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  iconBuilder(color),
                  if (badge != null) Positioned(top: -5, right: -10, child: badge!),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(label,
                style: ts(size: 10.5, weight: active ? FontWeight.w600 : FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatefulWidget {
  final int count;
  final Color color;
  final int? bounceToken;
  const _Badge({required this.count, required this.color, this.bounceToken});

  @override
  State<_Badge> createState() => _BadgeState();
}

class _BadgeState extends State<_Badge> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void didUpdateWidget(covariant _Badge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bounceToken != null && widget.bounceToken != oldWidget.bounceToken) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      constraints: const BoxConstraints(minWidth: 17),
      height: 17,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(100)),
      child: Text('${widget.count}',
          style: ts(size: 11, weight: FontWeight.w700, color: Colors.white)),
    );
    if (widget.bounceToken == null) return badge;
    final scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.45, end: 1.0), weight: 60),
    ]).animate(_c);
    return ScaleTransition(scale: scale, child: badge);
  }
}

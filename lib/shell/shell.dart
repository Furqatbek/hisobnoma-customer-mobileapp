import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/strings.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/components.dart';
import '../widgets/icons.dart';
import '../screens/catalog.dart';
import '../screens/cart.dart';
import '../screens/payment.dart';
import '../screens/account.dart';
import '../screens/extras.dart';
import '../screens/wishlist.dart';

/// Tab order for the persistent root IndexedStack.
const _tabOrder = ['catalog', 'cart', 'wallet', 'wishlist', 'profile'];

/// Root shell. The five tab root screens live in a lazy [IndexedStack] so each
/// keeps its state (catalog scroll/search/filter, loaded lists, …) while you
/// dive into a pushed screen and come back. Pushed screens (product, checkout,
/// payment, …) render in [_PushedOverlay] on top, with the prototype's slide
/// transitions. The tab bar shows only at a tab's root; the toast sits above all.
class ShopShell extends StatefulWidget {
  const ShopShell({super.key});

  @override
  State<ShopShell> createState() => _ShopShellState();
}

class _ShopShellState extends State<ShopShell> {
  // Tabs are built only once visited (so we don't fire every tab's initial
  // fetch at launch); once built they stay alive in the IndexedStack.
  final Set<String> _visited = {};

  Widget _rootScreen(AppState app, String tab) {
    switch (tab) {
      case 'cart':
        return CartScreen(app: app);
      case 'wallet':
        return WalletScreen(app: app);
      case 'wishlist':
        return WishlistScreen(app: app);
      case 'profile':
        return ProfileScreen(app: app);
      case 'catalog':
      default:
        return CatalogScreen(app: app);
    }
  }

  Widget _pushedScreen(AppState app, ScreenSpec s) {
    switch (s.name) {
      case 'product':
        return ProductDetailScreen(app: app, productId: s.productId!);
      case 'checkout':
        return CheckoutScreen(app: app);
      case 'payment':
        return PaymentScreen(app: app, orderNumber: s.orderNumber!, total: s.total!);
      case 'success':
        return OrderSuccessScreen(
            app: app,
            orderNumber: s.orderNumber!,
            total: s.total!,
            payMethod: s.payMethod,
            paid: s.paid ?? false);
      case 'login':
        return LoginScreen(app: app);
      case 'status':
        return OrderStatusScreen(app: app, initialOrderNumber: s.orderNumber);
      case 'notifications':
        return NotificationsScreen(app: app);
      case 'coupons':
        return CouponsScreen(app: app);
      case 'referrals':
        return ReferralsScreen(app: app);
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    _visited.add(app.tab);
    final tabIndex = _tabOrder.indexOf(app.tab);
    final pushed = app.stack.length > 1;

    return Container(
      color: AppColors.bg,
      child: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: tabIndex < 0 ? 0 : tabIndex,
              sizing: StackFit.expand,
              children: [
                for (final t in _tabOrder)
                  _visited.contains(t) ? _rootScreen(app, t) : const SizedBox.shrink(),
              ],
            ),
          ),
          // Tab bar sits beneath the overlay so a popping screen slides over it
          // and reveals it; at a root the overlay is empty and lets it through.
          if (app.showTabBar)
            Positioned(left: 0, right: 0, bottom: 0, child: _TabBar(app: app)),
          Positioned.fill(
            child: _PushedOverlay(
              motion: app.motion,
              childKey: '${app.tab}-${app.stack.length}-${app.screen.name}',
              child: pushed ? _pushedScreen(app, app.screen) : null,
            ),
          ),
          Toast(message: app.toastMsg, show: app.toastShow),
        ],
      ),
    );
  }
}

enum _OverlayMode { enterPush, enterPop, leaving }

/// Renders the current pushed screen (or nothing at a tab root) over the
/// persistent roots, animating it in on push and out on pop — so returning to
/// a root reveals the still-alive root beneath rather than rebuilding it.
class _PushedOverlay extends StatefulWidget {
  final Widget? child;
  final String childKey;
  final NavMotion motion;
  const _PushedOverlay({required this.child, required this.childKey, required this.motion});

  @override
  State<_PushedOverlay> createState() => _PushedOverlayState();
}

class _PushedOverlayState extends State<_PushedOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  Widget? _child;
  late String _key;
  _OverlayMode _mode = _OverlayMode.enterPush;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    // Created here (not as a lazy `late` field) so dispose() never initializes
    // it on a deactivated element when build short-circuits at a root.
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 320), value: 1);
    _child = widget.child;
    _key = widget.childKey;
  }

  @override
  void didUpdateWidget(covariant _PushedOverlay old) {
    super.didUpdateWidget(old);
    if (widget.childKey == _key) {
      // Same screen identity — just refresh its content (e.g. a state change).
      if (widget.child != null) _child = widget.child;
      return;
    }
    _key = widget.childKey;
    final token = ++_token;
    if (widget.child != null) {
      // Show a pushed screen.
      setState(() {
        _child = widget.child;
        _mode = widget.motion == NavMotion.pop ? _OverlayMode.enterPop : _OverlayMode.enterPush;
      });
      if (widget.motion == NavMotion.none) {
        _c.value = 1;
      } else {
        _c.forward(from: 0);
      }
    } else if (widget.motion == NavMotion.none) {
      setState(() => _child = null);
    } else {
      // Pop to a root: slide the pushed screen out, revealing the live root.
      _mode = _OverlayMode.leaving;
      _c.reverse(from: 1).whenComplete(() {
        if (mounted && token == _token) setState(() => _child = null);
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = _child;
    if (child == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _c,
      child: child,
      builder: (context, ch) {
        final t = Curves.easeOutCubic.transform(_c.value);
        double dx;
        double opacity = 1;
        switch (_mode) {
          case _OverlayMode.enterPush:
          case _OverlayMode.leaving:
            dx = 1 - t; // push: 100%→0 (forward); pop-to-root: 0→100% (reverse)
          case _OverlayMode.enterPop:
            dx = -0.3 * (1 - t); // revealed deeper screen: -30%→0
            opacity = 0.6 + 0.4 * t;
        }
        return FractionalTranslation(
          translation: Offset(dx, 0),
          child: Opacity(opacity: opacity, child: ch),
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
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
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

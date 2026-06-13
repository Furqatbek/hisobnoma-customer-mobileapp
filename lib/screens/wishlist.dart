import 'package:flutter/material.dart';

import '../data/format.dart';
import '../data/models.dart';
import '../data/strings.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/components.dart';
import '../widgets/icons.dart';
import 'cart.dart' show SwipeRow;
import 'extras.dart' show loginPromptColumn;

class WishlistScreen extends StatefulWidget {
  final AppState app;
  const WishlistScreen({super.key, required this.app});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _loading = false;
  String? _error;

  AppState get app => widget.app;

  @override
  void initState() {
    super.initState();
    if (app.isLoggedIn) _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = app.wishlistItems.isEmpty;
      _error = null;
    });
    try {
      final page = await app.wishlistApi.list(size: 50);
      app.wishlistItems = page.content;
      app.wishlistIds = page.content.map((w) => w.catalogItemId).toSet();
      app.notify();
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
        _loading = false;
        if (app.wishlistItems.isEmpty) _error = tr2('Юклаб бўлмади', 'Не удалось загрузить');
      });
      }
      app.notify();
    }
  }

  Product _asProduct(WishlistItem w) => Product(
        id: w.catalogItemId,
        name: w.name,
        shortDescription: '',
        description: '',
        basePrice: w.basePrice,
        salePrice: w.salePrice,
        categoryId: 0,
        categoryName: '',
        unitName: '',
        inStock: w.inStock,
        imageUrls: w.imageUrls,
      );

  @override
  Widget build(BuildContext context) {
    final top = topInset(context);
    final title = Padding(
      padding: EdgeInsets.only(top: top + 12, left: 16, right: 16, bottom: 6),
      child: Align(alignment: Alignment.centerLeft, child: LargeTitle(tr('Севимлилар'))),
    );

    if (!app.isLoggedIn) {
      return Container(
        color: AppColors.bg,
        child: Column(
          children: [
            title,
            loginPromptColumn(app,
                icon: Ic.heart(AppColors.accent, 40),
                title: tr('Севимлилар'),
                body: tr2('Маҳсулотларни севимлиларга қўшиш учун тизимга киринг.',
                    'Войдите, чтобы добавлять товары в избранное.')),
          ],
        ),
      );
    }

    final items = app.wishlistItems;

    if (_loading) {
      return Container(color: AppColors.bg, child: Column(children: [title, const Expanded(child: CenterLoader())]));
    }
    if (_error != null && items.isEmpty) {
      return Container(
        color: AppColors.bg,
        child: Column(children: [title, Expanded(child: ErrorView(message: _error, onRetry: _refresh))]),
      );
    }

    if (items.isEmpty) {
      return Container(
        color: AppColors.bg,
        child: Column(
          children: [
            title,
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 140, left: 32, right: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Ic.heart(AppColors.ter, 52),
                    const SizedBox(height: 18),
                    Text(tr('Севимлилар бўш'), style: ts(size: 17, color: AppColors.sec, letterSpacing: -0.2)),
                    const SizedBox(height: 18),
                    BigButton(
                      ghost: true,
                      width: null,
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      onTap: () => app.setTab('catalog'),
                      child: Text(tr('Каталогга қайтиш')),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppColors.bg,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.only(bottom: tabBarHeight(context) + 24),
          children: [
            title,
            for (var i = 0; i < items.length; i++) _row(items[i], i, items.length),
            Padding(
              padding: const EdgeInsets.only(top: 14, left: 16, right: 16),
              child: Text(tr('Ўчириш учун чапга суринг'),
                  textAlign: TextAlign.center, style: ts(size: 13, color: AppColors.ter)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(WishlistItem w, int i, int count) {
    final id = w.catalogItemId;
    final inCart = (app.cart[id] ?? 0) > 0;
    final canBuy = w.inStock && w.available;
    final discounted = w.priceDrop && w.oldPrice != null;
    final pct = w.oldPrice != null ? ((1 - w.price / w.oldPrice!) * 100).round() : 0;

    return SwipeRow(
      onDelete: () => app.toggleWish(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: i < count - 1 ? const Border(bottom: BorderSide(color: AppColors.sep, width: 0.5)) : null,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => app.push(ScreenSpec('product', productId: id)),
              child: ProductImage(imageUrl: w.imageUrl, label: null, semanticLabel: w.name, radius: 10, width: 56, height: 56),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => app.push(ScreenSpec('product', productId: id)),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ts(size: 15.5, weight: FontWeight.w500, color: AppColors.text, letterSpacing: -0.2, height: 1.3)),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(formatSum(w.price), style: ts(size: 15, weight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.2)),
                        if (w.oldPrice != null) ...[
                          const SizedBox(width: 7),
                          Text(formatSum(w.oldPrice), style: ts(size: 13, color: AppColors.ter, decoration: TextDecoration.lineThrough)),
                        ],
                      ],
                    ),
                    if (discounted || !w.inStock) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (discounted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(color: const Color.fromRGBO(232, 115, 12, 0.12), borderRadius: BorderRadius.circular(100)),
                              child: Text('−$pct% ${tr('чегирма')}', style: ts(size: 12, weight: FontWeight.w600, color: AppColors.orange)),
                            ),
                          if (!w.inStock) const StockBadge(inStock: false, small: true),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                if (!canBuy) return;
                if (!inCart) {
                  app.addToCart(_asProduct(w));
                  app.toast(tr('Саватга қўшилди'));
                } else {
                  app.setTab('cart');
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: !canBuy ? const Color.fromRGBO(120, 120, 128, 0.12) : (inCart ? AppColors.accentDim : AppColors.accent),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: inCart
                      ? Ic.check(AppColors.accent, 17)
                      : Ic.cart(!canBuy ? const Color.fromRGBO(60, 60, 67, 0.30) : Colors.white, 19),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

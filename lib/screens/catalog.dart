import 'dart:async';
import 'package:flutter/material.dart';

import '../data/api/api_client.dart';
import '../data/api/api_config.dart';
import '../data/format.dart';
import '../data/models.dart';
import '../data/strings.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/components.dart';
import '../widgets/icons.dart';

// ── Shimmer skeleton ────────────────────────────────────────────────────────
class _ShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;
  final double radius;
  final double? aspectRatio;
  const _ShimmerBox({this.width, this.height, this.radius = 6, this.aspectRatio});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget box = AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 - 2 * (1 - t), 0),
              end: Alignment(1 - 2 * (1 - t), 0),
              colors: const [
                Color.fromRGBO(120, 120, 128, 0.10),
                Color.fromRGBO(120, 120, 128, 0.05),
                Color.fromRGBO(120, 120, 128, 0.10),
              ],
              stops: const [0.3, 0.5, 0.7],
            ),
          ),
        );
      },
    );
    if (widget.aspectRatio != null) box = AspectRatio(aspectRatio: widget.aspectRatio!, child: box);
    if (widget.width != null || widget.height != null) {
      box = SizedBox(width: widget.width, height: widget.height, child: box);
    }
    return box;
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _ShimmerBox(aspectRatio: 1, radius: 12),
        SizedBox(height: 8),
        _ShimmerBox(height: 14, radius: 6, width: double.infinity),
        SizedBox(height: 8),
        _ShimmerBox(height: 16, radius: 6, width: 70),
      ],
    );
  }
}

// ── Product card ────────────────────────────────────────────────────────────
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final bool wished;
  final VoidCallback onToggleWish;
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.wished,
    required this.onToggleWish,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ProductImage(imageUrl: product.imageUrl, label: product.name, semanticLabel: product.name, aspectRatio: 1),
              if (!product.inStock)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(214, 59, 47, 0.85),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(tr('Тугаган'),
                        style: ts(size: 11.5, weight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: Semantics(
                  button: true,
                  toggled: wished,
                  label: tr2('Севимлилар', 'Избранное'),
                  child: GestureDetector(
                    onTap: onToggleWish,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 255, 255, 0.85),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.08), blurRadius: 4, offset: Offset(0, 1))],
                      ),
                      child: Center(
                        child: wished
                            ? Ic.heartFill(AppColors.red, 17)
                            : Ic.heart(const Color.fromRGBO(60, 60, 67, 0.55), 17),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ts(size: 14.5, weight: FontWeight.w500, color: AppColors.text, letterSpacing: -0.15, height: 1.3),
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(formatSum(product.price),
                  style: ts(size: 16, weight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.2)),
              if (product.oldPrice != null) ...[
                const SizedBox(width: 6),
                // Two six-digit sums don't always fit a narrow grid card —
                // fade the struck-through old price instead of overflowing.
                Flexible(
                  child: Text(formatSum(product.oldPrice),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: ts(size: 12.5, color: AppColors.ter, decoration: TextDecoration.lineThrough)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Catalog screen ──────────────────────────────────────────────────────────
class CatalogScreen extends StatefulWidget {
  final AppState app;
  const CatalogScreen({super.key, required this.app});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;

  List<Category> _categories = [];
  final List<Product> _products = [];
  int? _catId;
  String _search = '';

  bool _loading = true; // initial / refilter
  bool _loadingMore = false;
  bool _collapsed = false;
  String? _error;
  int _page = 0;
  int _totalPages = 1;

  AppState get app => widget.app;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _bootstrap();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      _categories = await app.catalog.categories();
    } catch (_) {/* non-fatal */}
    await _fetch(reset: true);
  }

  Future<void> _fetch({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 0;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final page = await app.catalog.products(
        search: _search.trim(),
        categoryId: _catId,
        page: reset ? 0 : _page,
        size: 20,
      );
      if (!mounted) return;
      setState(() {
        if (reset) _products.clear();
        _products.addAll(page.content);
        _totalPages = page.totalPages;
        _page = page.number + 1;
        _loading = false;
        _loadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        if (reset) _error = e.message;
      });
    }
  }

  bool get _hasMore => _page < _totalPages;

  void _onScroll() {
    final c = _scrollCtrl.offset > 44;
    if (c != _collapsed) setState(() => _collapsed = c);
    if (_hasMore && !_loadingMore && !_loading &&
        _scrollCtrl.position.pixels > _scrollCtrl.position.maxScrollExtent - 400) {
      _fetch(reset: false);
    }
  }

  void _onSearch(String v) {
    _search = v;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _fetch(reset: true));
  }

  void _selectCategory(int? id) {
    setState(() => _catId = id);
    _fetch(reset: true);
  }

  void _toggleWish(Product p) {
    if (!app.toggleWish(p.id)) app.push(const ScreenSpec('login'));
  }

  @override
  Widget build(BuildContext context) {
    final top = topInset(context);
    final cardW = (MediaQuery.of(context).size.width - 44) / 2;
    final gridAspect = cardW / (cardW + 74);

    return Container(
      color: AppColors.bg,
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => _fetch(reset: true),
            child: ListView(
              controller: _scrollCtrl,
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: top + 12, left: 16, right: 16),
                  child: LargeTitle(
                    'Каталог',
                    trailing: Semantics(
                      button: true,
                      label: tr('Билдиришномалар'),
                      child: GestureDetector(
                      onTap: () => app.push(const ScreenSpec('notifications')),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: AppColors.fill, borderRadius: BorderRadius.circular(100)),
                        child: Stack(
                          children: [
                            Center(child: Ic.bell(AppColors.text, 21)),
                            if (app.unreadCount > 0)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.red,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  child: Center(
                                    child: Text(
                                      app.unreadCount > 9 ? '9+' : '${app.unreadCount}',
                                      style: ts(size: 10, weight: FontWeight.w700, color: Colors.white, height: 1),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: AppColors.fill, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Ic.search(),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: _onSearch,
                            cursorColor: AppColors.accent,
                            style: ts(size: 16.5, color: AppColors.text, letterSpacing: -0.2),
                            decoration: InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              hintText: tr('Қидириш...'),
                              hintStyle: ts(size: 16.5, color: const Color.fromRGBO(60, 60, 67, 0.45), letterSpacing: -0.2),
                            ),
                          ),
                        ),
                        if (_search.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              _onSearch('');
                            },
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(color: AppColors.fill2, borderRadius: BorderRadius.circular(100)),
                              child: const Center(child: Icon(Icons.close, size: 13, color: AppColors.sec)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_categories.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          ShopChip(label: tr('Барчаси'), selected: _catId == null, onTap: () => _selectCategory(null)),
                          for (final c in _categories) ...[
                            const SizedBox(width: 8),
                            ShopChip(label: c.name, selected: _catId == c.id, onTap: () => _selectCategory(c.id)),
                          ],
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                  child: _buildBody(gridAspect),
                ),
              ],
            ),
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _collapsed ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: ClipRect(
                child: BackdropFilter(
                  filter: blur16,
                  child: Container(
                    height: top + 40,
                    alignment: Alignment.bottomCenter,
                    padding: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.82),
                      border: const Border(bottom: BorderSide(color: AppColors.sep, width: 0.5)),
                    ),
                    child: Text('Каталог', style: ts(size: 17, weight: FontWeight.w600, color: AppColors.text)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(double gridAspect) {
    if (_loading) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 18,
        crossAxisSpacing: 12,
        childAspectRatio: gridAspect,
        children: List.generate(6, (i) => const _SkeletonCard()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: ErrorView(message: _error, onRetry: () => _fetch(reset: true)),
      );
    }
    if (_products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 20),
        child: Column(
          children: [
            Ic.box(),
            const SizedBox(height: 14),
            Text(tr('Ҳеч нарса топилмади'),
                style: ts(size: 16.5, color: AppColors.sec, letterSpacing: -0.2)),
          ],
        ),
      );
    }
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 18,
          crossAxisSpacing: 12,
          childAspectRatio: gridAspect,
          children: [
            for (final p in _products)
              ProductCard(
                product: p,
                wished: app.isWished(p.id),
                onToggleWish: () => _toggleWish(p),
                onTap: () => app.push(ScreenSpec('product', productId: p.id)),
              ),
          ],
        ),
        if (_loadingMore)
          const Padding(padding: EdgeInsets.only(top: 18), child: Spinner()),
      ],
    );
  }
}

// ── Product detail ──────────────────────────────────────────────────────────
class ProductDetailScreen extends StatefulWidget {
  final AppState app;
  final int productId;
  const ProductDetailScreen({super.key, required this.app, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _page = 0;
  final _pageCtrl = PageController();
  Product? _product;
  String? _error;
  bool _loading = true;

  AppState get app => widget.app;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = app.productCache[widget.productId] ?? await app.catalog.product(widget.productId);
      app.cacheProduct(p);
      if (!mounted) return;
      setState(() {
        _product = p;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = topInset(context);
    if (_loading || _error != null) {
      return Container(
        color: AppColors.bg,
        child: Column(
          children: [
            NavHeader(title: '', onBack: app.pop),
            Expanded(
              child: _error != null
                  ? ErrorView(message: _error, onRetry: _load)
                  : const CenterLoader(),
            ),
          ],
        ),
      );
    }

    final product = _product!;
    final qty = app.cart[product.id] ?? 0;
    final images = product.imageUrls;
    final imageCount = images.isEmpty ? 1 : images.length;

    return Container(
      color: AppColors.bg,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 170),
            children: [
              SizedBox(
                height: 350,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageCtrl,
                      itemCount: imageCount,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (context, i) => ProductImage(
                        imageUrl: images.isEmpty ? null : images[i],
                        label: product.name,
                        semanticLabel: product.name,
                        radius: 0,
                        fontSize: 13,
                        width: double.infinity,
                        height: 350,
                      ),
                    ),
                    if (imageCount > 1)
                      Positioned(
                        bottom: 26,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < imageCount; i++)
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: i == _page ? AppColors.text : const Color.fromRGBO(0, 0, 0, 0.2),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                          ],
                        ),
                      ),
                    Positioned(
                      top: top,
                      left: 12,
                      child: Semantics(
                        button: true,
                        label: tr2('Орқага', 'Назад'),
                        child: _circleBtn(child: Ic.chevronL(AppColors.text, 18), onTap: app.pop),
                      ),
                    ),
                    Positioned(
                      top: top,
                      right: 12,
                      child: Semantics(
                        button: true,
                        toggled: app.isWished(product.id),
                        label: tr2('Севимлилар', 'Избранное'),
                        child: _circleBtn(
                          child: app.isWished(product.id)
                              ? Ic.heartFill(AppColors.red, 20)
                              : Ic.heart(const Color.fromRGBO(60, 60, 67, 0.65), 20),
                          onTap: () {
                            if (!app.toggleWish(product.id)) app.push(const ScreenSpec('login'));
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -18),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name,
                          style: ts(size: 23, weight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.3, height: 1.25)),
                      const SizedBox(height: 10),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.end,
                        spacing: 6,
                        children: [
                          Text(formatSum(product.price),
                              style: ts(size: 26, weight: FontWeight.w700, color: AppColors.accent, letterSpacing: -0.4)),
                          if (product.oldPrice != null)
                            Text(formatSum(product.oldPrice),
                                style: ts(size: 16, color: AppColors.ter, decoration: TextDecoration.lineThrough)),
                          if (product.unitName.isNotEmpty)
                            Text('/ ${product.unitName}', style: ts(size: 16, color: AppColors.sec)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          StockBadge(inStock: product.inStock),
                          Text(
                            '${product.categoryName}${product.brandName != null ? ' · ${product.brandName}' : ''}',
                            style: ts(size: 14, color: AppColors.sec),
                          ),
                        ],
                      ),
                      if (product.description.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 18),
                          padding: const EdgeInsets.only(top: 16),
                          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.sep, width: 0.5))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader(tr('Тавсиф')),
                              const SizedBox(height: 8),
                              Text(product.description,
                                  style: ts(size: 16, color: AppColors.text, letterSpacing: -0.2, height: 1.5)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: blur16,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 38),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 255, 255, 0.88),
                    border: const Border(top: BorderSide(color: AppColors.sep, width: 0.5)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShopTextButton(
                            fontSize: 14.5,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            onTap: () => app.toast('${tr2('Қўнғироқ', 'Звонок')}: ${ApiConfig.shopPhone}'),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Ic.phone(),
                              const SizedBox(width: 6),
                              Text(tr('Қўнғироқ қилиш')),
                            ]),
                          ),
                          ShopTextButton(
                            fontSize: 14.5,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            onTap: () => app.toast('Telegram: ${ApiConfig.shopTelegram}'),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Ic.send(),
                              const SizedBox(width: 6),
                              Text(tr('Telegram орқали')),
                            ]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (qty == 0)
                        BigButton(
                          disabled: !product.inStock,
                          onTap: () => app.addToCart(product),
                          child: Text(product.inStock ? tr('Саватга қўшиш') : tr('Тугаган')),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(color: AppColors.accentDim, borderRadius: BorderRadius.circular(AppRadii.btn)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Ic.check(AppColors.accent, 16),
                                    const SizedBox(width: 8),
                                    Text(tr('Саватда'),
                                        style: ts(size: 16.5, weight: FontWeight.w600, color: AppColors.accent)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ShopStepper(qty: qty, step: product.cartStep, onChange: (n) => app.setQty(product.id, n)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: blur12,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.75),
              shape: BoxShape.circle,
              border: Border.all(color: const Color.fromRGBO(0, 0, 0, 0.06), width: 0.5),
              boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.08), blurRadius: 4, offset: Offset(0, 1))],
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

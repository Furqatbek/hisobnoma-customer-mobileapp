import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/api/api_client.dart';
import '../data/api/api_config.dart';
import '../data/format.dart';
import '../data/models.dart';
import '../data/strings.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/components.dart';
import '../widgets/icons.dart';

// ── Swipe-to-delete row ─────────────────────────────────────────────────────
class SwipeRow extends StatefulWidget {
  final VoidCallback onDelete;
  final Widget child;
  const SwipeRow({super.key, required this.onDelete, required this.child});

  @override
  State<SwipeRow> createState() => _SwipeRowState();
}

class _SwipeRowState extends State<SwipeRow> {
  static const double _w = 84;
  double _x = 0;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        children: [
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: _w,
            child: GestureDetector(
              onTap: widget.onDelete,
              child: AnimatedOpacity(
                opacity: _x < -10 ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  color: AppColors.red,
                  alignment: Alignment.center,
                  child: Text(tr('Ўчириш'),
                      style: ts(size: 14.5, weight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ),
          ),
          GestureDetector(
            onHorizontalDragStart: (_) => setState(() => _dragging = true),
            onHorizontalDragUpdate: (d) {
              setState(() => _x = (_x + d.delta.dx).clamp(-_w - 16, 0.0));
            },
            onHorizontalDragEnd: (_) {
              setState(() {
                _dragging = false;
                _x = _x < -_w / 2 ? -_w : 0;
              });
            },
            child: AnimatedContainer(
              duration: _dragging ? Duration.zero : const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(_x, 0, 0),
              color: AppColors.bg,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cart screen ─────────────────────────────────────────────────────────────
class CartScreen extends StatefulWidget {
  final AppState app;
  const CartScreen({super.key, required this.app});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _loading = false;

  AppState get app => widget.app;

  @override
  void initState() {
    super.initState();
    final missing = app.cart.keys.any((id) => !app.productCache.containsKey(id));
    if (missing) {
      _loading = true;
      app.ensureCartProducts().whenComplete(() {
        if (mounted) setState(() => _loading = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ids = app.cart.keys.toList();
    final top = topInset(context);

    if (_loading) {
      return Container(
        color: AppColors.bg,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: top + 12, left: 16, right: 16),
              child: Align(alignment: Alignment.centerLeft, child: LargeTitle(tr('Сават'))),
            ),
            const Expanded(child: CenterLoader()),
          ],
        ),
      );
    }

    if (ids.isEmpty) {
      return Container(
        color: AppColors.bg,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: top + 12, left: 16, right: 16),
              child: Align(alignment: Alignment.centerLeft, child: LargeTitle(tr('Сават'))),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 140, left: 32, right: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Ic.bag(),
                    const SizedBox(height: 18),
                    Text(tr('Сават бўш'), style: ts(size: 17, color: AppColors.sec, letterSpacing: -0.2)),
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

    final subtotal = ids.fold<double>(0, (s, id) => s + (app.productCache[id]?.price ?? 0) * app.cart[id]!);

    return Container(
      color: AppColors.bg,
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(bottom: tabBarHeight(context) + 150),
            children: [
              Padding(
                padding: EdgeInsets.only(top: top + 12, left: 16, right: 16, bottom: 6),
                child: Align(alignment: Alignment.centerLeft, child: LargeTitle(tr('Сават'))),
              ),
              for (var i = 0; i < ids.length; i++) _cartRow(ids[i], i, ids.length),
              Padding(
                padding: const EdgeInsets.only(top: 14, left: 16, right: 16),
                child: Text(tr('Ўчириш учун чапга суринг'),
                    textAlign: TextAlign.center, style: ts(size: 13, color: AppColors.ter)),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: tabBarHeight(context),
            child: ClipRect(
              child: BackdropFilter(
                filter: blur16,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 255, 255, 0.92),
                    border: const Border(top: BorderSide(color: AppColors.sep, width: 0.5)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tr('Жами'), style: ts(size: 16, color: AppColors.sec)),
                          Text(formatSum(subtotal),
                              style: ts(size: 20, weight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.3)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      BigButton(
                        onTap: () => app.push(const ScreenSpec('checkout')),
                        child: Text(tr('Буюртма бериш')),
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

  Widget _cartRow(int id, int i, int count) {
    final p = app.productCache[id];
    final qty = app.cart[id]!;
    if (p == null) return const SizedBox.shrink();
    return SwipeRow(
      onDelete: () => app.setQty(id, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: i < count - 1 ? const Border(bottom: BorderSide(color: AppColors.sep, width: 0.5)) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(imageUrl: p.imageUrl, label: null, radius: 10, width: 56, height: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ts(size: 15.5, weight: FontWeight.w500, color: AppColors.text, letterSpacing: -0.2, height: 1.3)),
                  const SizedBox(height: 3),
                  Text('${formatSum(p.price)}${p.unitName.isNotEmpty ? ' / ${p.unitName}' : ''}',
                      style: ts(size: 13.5, color: AppColors.sec)),
                  const SizedBox(height: 7),
                  ShopStepper(compact: true, qty: qty, onChange: (n) => app.setQty(id, n)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(formatSum(p.price * qty),
                  style: ts(size: 16, weight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.2)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Checkout ────────────────────────────────────────────────────────────────
class CheckoutScreen extends StatefulWidget {
  final AppState app;
  const CheckoutScreen({super.key, required this.app});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _noteCtrl;
  String _phone = '';
  int? _regionId;
  int? _villageId;
  String _payMethod = 'CASH';
  String? _nameErr;
  bool _phoneErr = false;
  bool _submitting = false;
  String? _submitError;

  List<Region> _regions = [];
  List<Village> _villages = [];
  bool _regionsLoading = true;

  AppState get app => widget.app;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: app.user?.name ?? '');
    _noteCtrl = TextEditingController();
    _phone = app.user?.phone ?? '';
    _payMethod = app.payMethod;
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    setState(() => _regionsLoading = true);
    try {
      _regions = await app.delivery.regions();
    } catch (_) {}
    if (mounted) setState(() => _regionsLoading = false);
  }

  Future<void> _loadVillages(int regionId) async {
    setState(() {
      _villages = [];
      _villageId = null;
    });
    try {
      final v = await app.delivery.villages(regionId: regionId);
      if (mounted) setState(() => _villages = v);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _nameErr = _nameCtrl.text.trim().isEmpty ? tr('Исмингизни киритинг') : null;
      _phoneErr = _phone.replaceAll(RegExp(r'\D'), '').length != 9;
      _submitError = null;
    });
    if (_nameErr != null || _phoneErr) return;
    setState(() => _submitting = true);
    try {
      final order = await app.placeOrder(
        name: _nameCtrl.text.trim(),
        local9: _phone.replaceAll(RegExp(r'\D'), ''),
        regionId: _regionId,
        villageId: _villageId,
        note: _noteCtrl.text.trim(),
        paymentMethod: _payMethod,
      );
      if (_payMethod == 'CARD' && ApiConfig.onlinePaymentEnabled) {
        // Online card orders go through the payment step first.
        app.replace(
            ScreenSpec('payment', orderNumber: order.orderNumber, total: order.totalAmount));
      } else {
        // Cash, or card-on-delivery when online payment isn't enabled.
        app.replace(ScreenSpec('success',
            orderNumber: order.orderNumber,
            total: order.totalAmount,
            payMethod: order.paymentMethod.isNotEmpty ? order.paymentMethod : _payMethod));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ids = app.cart.keys.toList();
    final subtotal = ids.fold<double>(0, (s, id) => s + (app.productCache[id]?.price ?? 0) * app.cart[id]!);
    final region = _regions.where((r) => r.id == _regionId).cast<Region?>().firstWhere((_) => true, orElse: () => null);
    final fee = region?.deliveryFee ?? 0;

    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          NavHeader(title: tr('Буюртма'), onBack: app.pop),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                SectionHeader(tr('Контакт')),
                const SizedBox(height: 12),
                Field(error: _nameErr, child: ShopTextField(controller: _nameCtrl, hint: tr('Исмингиз'), error: _nameErr != null)),
                const SizedBox(height: 12),
                Field(
                  error: _phoneErr ? tr('Телефон рақам нотўғри') : null,
                  child: PhoneField(initialRaw: _phone, error: _phoneErr, onChanged: (v) => _phone = v),
                ),
                const SizedBox(height: 24),
                SectionHeader(tr('Етказиб бериш')),
                const SizedBox(height: 12),
                if (_regionsLoading)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Spinner())
                else
                  _dropdown<int>(
                    value: _regionId,
                    hint: tr('Туман'),
                    items: [for (final r in _regions) DropdownMenuItem(value: r.id, child: Text(r.name))],
                    onChanged: (v) {
                      setState(() => _regionId = v);
                      if (v != null) _loadVillages(v);
                    },
                  ),
                if (_regionId != null && _villages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _dropdown<int>(
                    value: _villageId,
                    hint: tr('Қишлоқ / маҳалла'),
                    items: [for (final v in _villages) DropdownMenuItem(value: v.id, child: Text(v.name))],
                    onChanged: (v) => setState(() => _villageId = v),
                  ),
                ],
                const SizedBox(height: 24),
                SectionHeader(tr('Тўлов усули')),
                const SizedBox(height: 12),
                for (final (i, e) in paymentMethods.entries.indexed) ...[
                  if (i > 0) const SizedBox(height: 10),
                  OptionCard(
                    icon: e.key == 'CARD'
                        ? Ic.card(AppColors.accent, 20)
                        : Ic.cash(AppColors.accent, 20),
                    title: tr(e.value.label),
                    subtitle: e.key == 'CARD' && ApiConfig.onlinePaymentEnabled
                        ? tr('Онлайн тўлов: Payme, Click, Uzum')
                        : tr(e.value.hint),
                    selected: _payMethod == e.key,
                    onTap: () => setState(() => _payMethod = e.key),
                  ),
                ],
                const SizedBox(height: 24),
                SectionHeader(tr('Қўшимча')),
                const SizedBox(height: 12),
                ShopTextField(controller: _noteCtrl, hint: tr('Изоҳ (ихтиёрий)'), maxLines: 3, height: null),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(120, 120, 128, 0.07),
                    borderRadius: BorderRadius.circular(AppRadii.card),
                  ),
                  child: Column(
                    children: [
                      _summaryRow(tr2('${ids.length} та маҳсулот', 'Товаров: ${ids.length}'), formatSum(subtotal)),
                      if (fee > 0) ...[
                        const SizedBox(height: 9),
                        _summaryRow(tr('Етказиб бериш'), formatSum(fee)),
                      ],
                      const SizedBox(height: 9),
                      _summaryRow(tr('Тўлов'), tr(paymentMethods[_payMethod]?.label ?? '')),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 9),
                        child: Divider(height: 0.5, thickness: 0.5, color: AppColors.sep),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tr('Жами тўлов'), style: ts(size: 16, weight: FontWeight.w600, color: AppColors.text)),
                          Text(formatSum(subtotal + fee),
                              style: ts(size: 20, weight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.3)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_submitError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(_submitError!,
                        textAlign: TextAlign.center, style: ts(size: 14.5, color: AppColors.red, height: 1.4)),
                  ),
                const SizedBox(height: 24),
                BigButton(loading: _submitting, onTap: _submit, child: Text(tr('Буюртмани юбориш'))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String left, String right) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(left, style: ts(size: 15, color: AppColors.sec)),
        Text(right, style: ts(size: 15, color: AppColors.text)),
      ],
    );
  }

  Widget _dropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: AppColors.fill, borderRadius: BorderRadius.circular(AppRadii.input)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: SizedBox(width: 12, height: 8, child: CustomPaint(painter: _ChevronDownPainter())),
          hint: Text(hint, style: ts(size: 17, color: const Color.fromRGBO(60, 60, 67, 0.45), letterSpacing: -0.2)),
          style: ts(size: 17, color: AppColors.text, letterSpacing: -0.2),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ChevronDownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromRGBO(60, 60, 67, 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(1, 1.5)
      ..lineTo(6, 6.5)
      ..lineTo(11, 1.5);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Order success ───────────────────────────────────────────────────────────
class OrderSuccessScreen extends StatelessWidget {
  final AppState app;
  final String orderNumber;
  final double total;
  final String? payMethod;
  final bool paid;
  const OrderSuccessScreen(
      {super.key,
      required this.app,
      required this.orderNumber,
      required this.total,
      this.payMethod,
      this.paid = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(color: Color.fromRGBO(30, 138, 76, 0.10), shape: BoxShape.circle),
              child: Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                  child: Center(child: Ic.check(Colors.white, 30)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeUp(
            child: Column(
              children: [
                Text(tr('Буюртмангиз қабул қилинди!'),
                    textAlign: TextAlign.center,
                    style: ts(size: 22, weight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.3)),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: orderNumber));
                    app.toast(tr('Нусха олинди'));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.fill, borderRadius: BorderRadius.circular(100)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(orderNumber,
                            style: TextStyle(fontFamily: kMonoFamily, fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.text, letterSpacing: 0.5)),
                        const SizedBox(width: 8),
                        Ic.copy(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(formatSum(total), style: ts(size: 17, weight: FontWeight.w600, color: AppColors.text)),
                if (paymentMethods[payMethod] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      payMethod == 'CARD' ? Ic.card(AppColors.sec, 16) : Ic.cash(AppColors.sec, 16),
                      const SizedBox(width: 6),
                      Text('${tr('Тўлов')}: ${tr(paymentMethods[payMethod]!.label)}',
                          style: ts(size: 14.5, color: AppColors.sec)),
                    ],
                  ),
                ],
                if (paid) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(30, 138, 76, 0.10),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Ic.check(AppColors.green, 14),
                        const SizedBox(width: 5),
                        Text(tr('Тўланган'),
                            style: ts(size: 13.5, weight: FontWeight.w600, color: AppColors.green)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(tr('Тез орада сиз билан боғланамиз...'),
                    textAlign: TextAlign.center, style: ts(size: 14.5, color: AppColors.sec)),
                const SizedBox(height: 36),
                // Card order placed but not paid online yet — offer to pay now.
                if (payMethod == 'CARD' && !paid && ApiConfig.onlinePaymentEnabled) ...[
                  BigButton(
                    ghost: true,
                    onTap: () => app.push(
                        ScreenSpec('payment', orderNumber: orderNumber, total: total)),
                    child: Text(tr('Тўлаш')),
                  ),
                  const SizedBox(height: 10),
                ],
                BigButton(
                  onTap: () {
                    app.resetCartStack();
                    app.setTab('catalog');
                  },
                  child: Text(tr('Каталогга қайтиш')),
                ),
                const SizedBox(height: 6),
                ShopTextButton(
                  onTap: () => app.push(ScreenSpec('status', orderNumber: orderNumber)),
                  child: Text(tr('Буюртма ҳолатини текшириш')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

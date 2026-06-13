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

// ── Order card (shared by profile history + status result) ──────────────────
class OrderCard extends StatelessWidget {
  final Order order;
  final bool expanded;

  /// Shown as a "Тўлаш" button on unpaid card orders (null hides it).
  final VoidCallback? onPay;
  const OrderCard({super.key, required this.order, this.expanded = true, this.onPay});

  // Aggregate discount to show as a single line, preferring the server's
  // discountTotal and falling back to a bare coupon discount.
  double _orderDiscount(Order order) =>
      order.discountTotal > 0 ? order.discountTotal : order.couponDiscount;

  Widget _feeRow(String label, String value, {Color valueColor = AppColors.sec}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ts(size: 14.5, color: AppColors.sec)),
          Text(value, style: ts(size: 14.5, color: valueColor)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.sep),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(order.orderNumber,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: kMonoFamily, fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text, letterSpacing: 0.3)),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: order.status),
            ],
          ),
          if (expanded) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 0.5, thickness: 0.5, color: AppColors.sep),
            ),
            for (final l in order.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: ts(size: 14.5, color: AppColors.text, letterSpacing: -0.15),
                          children: [
                            TextSpan(text: l.productName),
                            TextSpan(text: ' × ${formatQty(l.quantity)}', style: ts(size: 14.5, color: AppColors.sec)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(formatSum(l.lineTotal), style: ts(size: 14.5, color: AppColors.text)),
                  ],
                ),
              ),
            if (order.deliveryFee > 0)
              _feeRow(tr('Етказиб бериш'), formatSum(order.deliveryFee)),
            // One discount line: discountTotal is the aggregate (it already
            // includes any coupon), so we don't also subtract couponDiscount
            // and double-count. The coupon code is shown as info only.
            if (_orderDiscount(order) > 0)
              _feeRow(tr('Чегирма'), '−${formatSum(_orderDiscount(order))}',
                  valueColor: AppColors.green),
            if ((order.couponCode ?? '').isNotEmpty)
              _feeRow(tr('Купон'), order.couponCode!),
            if (order.pointsSpent > 0)
              _feeRow(tr('Кешбек ишлатилди'), '−${formatSum(order.pointsSpent)}',
                  valueColor: AppColors.green),
            if (paymentMethods[order.paymentMethod] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tr('Тўлов'), style: ts(size: 14.5, color: AppColors.sec)),
                    Row(
                      children: [
                        Text(tr(paymentMethods[order.paymentMethod]!.label),
                            style: ts(size: 14.5, color: AppColors.sec)),
                        if (paymentStatusMeta[order.paymentStatus] case final m?) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration:
                                BoxDecoration(color: m.bg, borderRadius: BorderRadius.circular(100)),
                            child: Text(tr(m.label),
                                style: ts(size: 12, weight: FontWeight.w600, color: m.color)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Divider(height: 0.5, thickness: 0.5, color: AppColors.sep),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tr('Жами'), style: ts(size: 14.5, color: AppColors.sec)),
                Text(formatSum(order.totalAmount),
                    style: ts(size: 17, weight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.2)),
              ],
            ),
            if (order.awaitingPayment && onPay != null) ...[
              const SizedBox(height: 12),
              BigButton(height: 42, onTap: onPay, child: Text(tr('Тўлаш'))),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Profile ─────────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  final AppState app;
  const ProfileScreen({super.key, required this.app});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Order> _orders = [];
  bool _ordersLoading = false;
  String? _ordersError;
  String? _loadedFor;

  AppState get app => widget.app;

  void _maybeLoadOrders() {
    final phone = app.user?.phone;
    if (phone == null || _loadedFor == phone) return;
    _loadedFor = phone;
    _ordersLoading = true;
    _ordersError = null;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final page = await app.orders.myOrders(size: 20);
        if (mounted) {
          setState(() {
          _orders = page.content;
          _ordersLoading = false;
        });
        }
      } on ApiException catch (e) {
        if (mounted) {
          setState(() {
          _ordersError = e.message;
          _ordersLoading = false;
        });
        }
      }
    });
  }

  Future<void> _refreshOrders() async {
    final phone = app.user?.phone;
    if (phone == null) return;
    try {
      final page = await app.orders.myOrders(size: 20);
      if (mounted) {
        setState(() {
        _orders = page.content;
        _ordersError = null;
        _ordersLoading = false;
        _loadedFor = phone;
      });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _ordersError = e.message);
    }
  }

  Widget _menuCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.sep),
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            MenuRow(icon: Ic.ticket(AppColors.accent, 18), label: tr('Купонлар'), onTap: () => app.push(const ScreenSpec('coupons'))),
            MenuRow(icon: Ic.gift(AppColors.accent, 18), label: tr('Дўстларни таклиф қилиш'), onTap: () => app.push(const ScreenSpec('referrals'))),
            MenuRow(icon: Ic.bell(AppColors.accent, 18), label: tr('Билдиришномалар'), onTap: () => app.push(const ScreenSpec('notifications'))),
            MenuRow(icon: Ic.box(AppColors.accent, 18), label: tr('Буюртма ҳолатини текшириш'), onTap: () => app.push(const ScreenSpec('status'))),
            Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: AppColors.accentDim, borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Ic.globe(AppColors.accent, 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(tr2('Тил', 'Язык'), style: ts(size: 16.5, color: AppColors.text, letterSpacing: -0.2))),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: AppColors.fill, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final e in const [['uz', 'Ўзбекча'], ['ru', 'Русский']])
                          GestureDetector(
                            onTap: () => app.setLang(e[0]),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              height: 30,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: app.lang == e[0] ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: app.lang == e[0]
                                    ? const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.10), blurRadius: 3, offset: Offset(0, 1))]
                                    : null,
                              ),
                              child: Text(e[1],
                                  style: ts(
                                      size: 13,
                                      weight: app.lang == e[0] ? FontWeight.w600 : FontWeight.w500,
                                      color: app.lang == e[0] ? AppColors.text : AppColors.sec,
                                      letterSpacing: -0.1)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = topInset(context);

    if (app.user == null) {
      _loadedFor = null;
      return Container(
        color: AppColors.bg,
        child: ListView(
          padding: EdgeInsets.only(bottom: tabBarHeight(context) + 24),
          children: [
            Padding(
              padding: EdgeInsets.only(top: top + 12, left: 16, right: 16),
              child: Align(alignment: Alignment.centerLeft, child: LargeTitle(tr('Профил'))),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 28, 32, 26),
              child: Column(
                children: [
                  Ic.personBig(AppColors.ter, 64),
                  const SizedBox(height: 12),
                  Text(tr('Буюртмалар тарихини кўриш учун тизимга киринг'),
                      textAlign: TextAlign.center, style: ts(size: 15, color: AppColors.sec, letterSpacing: -0.2)),
                  const SizedBox(height: 18),
                  BigButton(
                    width: null,
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    onTap: () => app.push(const ScreenSpec('login')),
                    child: Text(tr('Кириш')),
                  ),
                ],
              ),
            ),
            _menuCard(),
          ],
        ),
      );
    }

    _maybeLoadOrders();

    return Container(
      color: AppColors.bg,
      child: RefreshIndicator(
        onRefresh: _refreshOrders,
        child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: tabBarHeight(context) + 24),
        children: [
          Padding(
            padding: EdgeInsets.only(top: top + 12, left: 16, right: 16),
            child: Align(alignment: Alignment.centerLeft, child: LargeTitle(tr('Профил'))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(color: AppColors.accentDim, shape: BoxShape.circle),
                  child: Center(child: Ic.person(AppColors.accent, 26)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (app.user!.name.isNotEmpty)
                        Text(app.user!.name,
                            style: ts(size: 18, weight: FontWeight.w600, color: AppColors.text, letterSpacing: -0.25)),
                      Text(formatPhone(app.user!.phone),
                          style: ts(size: 14.5, color: AppColors.sec).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _menuCard(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(tr('Буюртмалар')),
                const SizedBox(height: 12),
                if (_ordersLoading)
                  const CenterLoader(padding: EdgeInsets.symmetric(vertical: 24))
                else if (_ordersError != null)
                  ErrorView(message: _ordersError, onRetry: () {
                    _loadedFor = null;
                    setState(_maybeLoadOrders);
                  })
                else if (_orders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text(tr('Ҳозирча буюртмалар йўқ'), style: ts(size: 15, color: AppColors.sec))),
                  )
                else
                  for (final o in _orders)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OrderCard(
                        order: o,
                        onPay: ApiConfig.onlinePaymentEnabled
                            ? () => app.push(ScreenSpec('payment',
                                orderNumber: o.orderNumber, total: o.totalAmount))
                            : null,
                      ),
                    ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: Center(
              child: ShopTextButton(color: AppColors.red, onTap: () => app.logout(), child: Text(tr('Чиқиш'))),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ── Login (SMS OTP, 2 stages) ───────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  final AppState app;
  const LoginScreen({super.key, required this.app});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _stage = 1;
  String _phone = '';
  final _codeCtrl = TextEditingController();
  final _codeFocus = FocusNode();
  final _nameCtrl = TextEditingController();
  String _error = '';
  bool _sending = false;
  Timer? _cooldownTimer;

  AppState get app => widget.app;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeCtrl.dispose();
    _codeFocus.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Ticks the displayed countdown once a second; the deadline itself lives in
  /// AppState, so this is purely for the label.
  void _tickCooldown() {
    _cooldownTimer?.cancel();
    if (app.otpCooldownRemaining <= 0) return;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || app.otpCooldownRemaining <= 0) {
        t.cancel();
        if (mounted) setState(() {});
        return;
      }
      setState(() {});
    });
  }

  Future<void> _sendCode() async {
    if (_phone.replaceAll(RegExp(r'\D'), '').length != 9) {
      setState(() => _error = tr('Телефон рақам нотўғри'));
      return;
    }
    // A code was already sent within the cooldown — go straight to entry
    // instead of re-requesting (and re-triggering an SMS).
    if (app.otpCooldownRemaining > 0) {
      setState(() {
        _error = '';
        _stage = 2;
      });
      _tickCooldown();
      Future.delayed(const Duration(milliseconds: 60), () => _codeFocus.requestFocus());
      return;
    }
    setState(() {
      _error = '';
      _sending = true;
    });
    try {
      await app.requestOtp(_phone.replaceAll(RegExp(r'\D'), ''));
      if (!mounted) return;
      setState(() {
        _sending = false;
        _stage = 2;
      });
      _tickCooldown();
      Future.delayed(const Duration(milliseconds: 60), () => _codeFocus.requestFocus());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message;
      });
    }
  }

  Future<void> _verify() async {
    if (_codeCtrl.text.length != 6) {
      setState(() => _error = tr('Код нотўғри ёки муддати ўтган'));
      return;
    }
    setState(() {
      _error = '';
      _sending = true;
    });
    try {
      await app.verifyOtp(_phone.replaceAll(RegExp(r'\D'), ''), _codeCtrl.text, name: _nameCtrl.text.trim());
      if (mounted) app.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message;
      });
    }
  }

  Future<void> _resend() async {
    if (app.otpCooldownRemaining > 0) return; // throttled
    try {
      await app.requestOtp(_phone.replaceAll(RegExp(r'\D'), ''));
      _tickCooldown();
      app.toast(tr('Код қайта юборилди'));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          NavHeader(title: tr2('Кириш', 'Вход'), onBack: app.pop),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 40),
              children: [_stage == 1 ? _stage1() : _stage2()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stage1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr('Телефон рақамингизга SMS код юборамиз'),
            style: ts(size: 16, color: AppColors.sec, letterSpacing: -0.2, height: 1.45)),
        const SizedBox(height: 18),
        Field(
          error: _error.isEmpty ? null : _error,
          child: PhoneField(initialRaw: _phone, autofocus: true, error: _error.isNotEmpty, fontSize: 19, height: 52, onChanged: (v) => _phone = v),
        ),
        const SizedBox(height: 18),
        BigButton(loading: _sending, onTap: _sendCode, child: Text(tr('Код юбориш'))),
      ],
    );
  }

  Widget _stage2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            Text(formatPhone(_phone),
                style: ts(size: 17, weight: FontWeight.w600, color: AppColors.text).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
            ShopTextButton(
              fontSize: 14,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              onTap: () => setState(() {
                _stage = 1;
                _codeCtrl.clear();
                _error = '';
              }),
              child: Text(tr('Рақамни ўзгартириш')),
            ),
          ],
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: () => _codeFocus.requestFocus(),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 6; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 44,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.fill,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: i == _codeCtrl.text.length ? AppColors.accent : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        i < _codeCtrl.text.length ? _codeCtrl.text[i] : '',
                        style: ts(size: 24, weight: FontWeight.w600, color: AppColors.text)
                            .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                    ),
                ],
              ),
              Opacity(
                opacity: 0,
                child: SizedBox(
                  width: 6 * 52,
                  child: TextField(
                    controller: _codeCtrl,
                    focusNode: _codeFocus,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    // iOS surfaces the SMS code above the keyboard; Android
                    // wires the autofill framework. Auto-submits on full code.
                    autofillHints: const [AutofillHints.oneTimeCode],
                    onChanged: (v) {
                      final digits = v.replaceAll(RegExp(r'\D'), '');
                      if (digits != v) _codeCtrl.text = digits;
                      setState(() {});
                      if (digits.length == 6 && !_sending) _verify();
                    },
                    decoration: const InputDecoration(counterText: '', border: InputBorder.none),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(_error, textAlign: TextAlign.center, style: ts(size: 13.5, color: AppColors.red)),
        ],
        const SizedBox(height: 18),
        Field(child: ShopTextField(controller: _nameCtrl, hint: tr('Исмингиз (ихтиёрий)'))),
        const SizedBox(height: 18),
        BigButton(loading: _sending, disabled: _codeCtrl.text.length != 6, onTap: _verify, child: Text(tr('Тасдиқлаш'))),
        const SizedBox(height: 8),
        Center(
          child: app.otpCooldownRemaining > 0
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text('${tr('Қайта юбориш')} — ${app.otpCooldownRemaining} ${tr2('сония', 'сек')}',
                      style: ts(size: 14.5, color: AppColors.ter)),
                )
              : ShopTextButton(fontSize: 14.5, onTap: _resend, child: Text(tr('Қайта юбориш'))),
        ),
      ],
    );
  }
}

// ── Order status lookup ─────────────────────────────────────────────────────
class OrderStatusScreen extends StatefulWidget {
  final AppState app;
  final String? initialOrderNumber;
  const OrderStatusScreen({super.key, required this.app, this.initialOrderNumber});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  late final TextEditingController _numCtrl;
  late String _phone;
  // Bumped only when a recent-order chip fills the phone, so PhoneField
  // rebuilds with the new value without disrupting manual typing.
  int _phoneEpoch = 0;
  Order? _result;
  bool _notFound = false;
  bool _searching = false;

  AppState get app => widget.app;

  @override
  void initState() {
    super.initState();
    _numCtrl = TextEditingController(text: widget.initialOrderNumber ?? '');
    _phone = app.lastOrderPhone.isNotEmpty ? app.lastOrderPhone : (app.user?.phone ?? '');
    // Opened with a prefilled order (success screen / after pay-again) —
    // look it up right away instead of making the user tap "Излаш".
    if (_numCtrl.text.trim().isNotEmpty && _phone.replaceAll(RegExp(r'\D'), '').length == 9) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _lookup();
      });
    }
  }

  @override
  void dispose() {
    _numCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    setState(() {
      _searching = true;
      _result = null;
      _notFound = false;
    });
    try {
      final order = await app.orders.lookup(_numCtrl.text.trim(), phoneToE164(_phone));
      // Remember the phone that authorised this order — the payment screen
      // uses it for the pay-again flow.
      app.lastOrderPhone = _phone.replaceAll(RegExp(r'\D'), '');
      if (mounted) {
        setState(() {
        _result = order;
        _searching = false;
      });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _notFound = e.status == 404;
        if (e.status != 404) app.toast(e.message);
      });
    }
  }

  Widget _recentRow(LocalOrderRef o) {
    final pm = paymentStatusMeta[o.paid ? 'PAID' : ''];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _numCtrl.text = o.orderNumber;
        setState(() {
          _phone = o.phone;
          _phoneEpoch++; // refresh the phone field display
        });
        _lookup();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.sep, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.orderNumber,
                      style: TextStyle(
                          fontFamily: kMonoFamily, fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.text, letterSpacing: 0.3)),
                  const SizedBox(height: 2),
                  Text('${formatDate(o.createdAt)} · ${formatSum(o.total)}',
                      style: ts(size: 13, color: AppColors.ter)),
                ],
              ),
            ),
            if (pm != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(color: pm.bg, borderRadius: BorderRadius.circular(100)),
                child: Text(tr(pm.label), style: ts(size: 12, weight: FontWeight.w600, color: pm.color)),
              ),
              const SizedBox(width: 8),
            ],
            Ic.chevronR(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSearch = _numCtrl.text.trim().isNotEmpty && _phone.replaceAll(RegExp(r'\D'), '').length == 9;
    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          NavHeader(title: tr('Буюртма ҳолати'), onBack: app.pop),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
              children: [
                Field(
                  child: ShopTextField(
                    controller: _numCtrl,
                    hint: tr2('Буюртма рақами (WEB-...)', 'Номер заказа (WEB-...)'),
                    mono: true,
                    fontSize: 15.5,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 12),
                Field(
                  child: PhoneField(
                    key: ValueKey(_phoneEpoch),
                    initialRaw: _phone,
                    onChanged: (v) => setState(() => _phone = v),
                  ),
                ),
                const SizedBox(height: 12),
                BigButton(loading: _searching, disabled: !canSearch, onTap: _lookup, child: Text(tr('Излаш'))),
                if (_notFound)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(tr('Буюртма топилмади. Рақам ва телефонни текширинг.'),
                        textAlign: TextAlign.center, style: ts(size: 14.5, color: AppColors.red, height: 1.45)),
                  ),
                if (_result != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: OrderCard(
                      order: _result!,
                      onPay: ApiConfig.onlinePaymentEnabled
                          ? () => app.push(ScreenSpec('payment',
                              orderNumber: _result!.orderNumber, total: _result!.totalAmount))
                          : null,
                    ),
                  ),
                if (_result == null && !_searching && app.recentOrders.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  SectionHeader(tr('Сўнгги буюртмалар')),
                  const SizedBox(height: 6),
                  for (final o in app.recentOrders.take(5)) _recentRow(o),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

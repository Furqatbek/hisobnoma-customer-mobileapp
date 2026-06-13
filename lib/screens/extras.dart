import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/api/api_client.dart';
import '../data/api/api_config.dart';
import '../data/format.dart';
import '../data/models.dart';
import '../data/strings.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/components.dart';
import '../widgets/icons.dart';

// Shared login-required prompt for /me screens.
Widget loginPromptColumn(AppState app, {required Widget icon, required String title, required String body}) {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.only(left: 36, right: 36, bottom: 140),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(color: AppColors.accentDim, shape: BoxShape.circle),
            child: Center(child: icon),
          ),
          const SizedBox(height: 16),
          Text(title, style: ts(size: 17, weight: FontWeight.w600, color: AppColors.text, letterSpacing: -0.25)),
          const SizedBox(height: 6),
          Text(body, textAlign: TextAlign.center, style: ts(size: 15, color: AppColors.sec, letterSpacing: -0.2, height: 1.45)),
          BigButton(
            margin: const EdgeInsets.only(top: 22),
            width: null,
            padding: const EdgeInsets.symmetric(horizontal: 48),
            onTap: () => app.push(const ScreenSpec('login')),
            child: Text(tr('Кириш')),
          ),
        ],
      ),
    ),
  );
}

// ── Notifications (/web/me/notifications) ───────────────────────────────────
class NotificationsScreen extends StatefulWidget {
  final AppState app;
  const NotificationsScreen({super.key, required this.app});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<ShopNotification> _items = [];
  bool _loading = true;
  String? _error;

  AppState get app => widget.app;

  @override
  void initState() {
    super.initState();
    if (app.isLoggedIn) {
      _load();
    } else {
      _loading = false;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await app.notificationsApi.list(size: 30);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.content);
        _loading = false;
      });
      app.refreshUnread();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _markAllRead() async {
    setState(() {
      for (var i = 0; i < _items.length; i++) {
        final n = _items[i];
        if (!n.read) {
          _items[i] = ShopNotification(
              id: n.id, type: n.type, title: n.title, body: n.body, read: true, createdAt: n.createdAt);
        }
      }
    });
    await app.markAllNotificationsRead();
  }

  void _open(int i) {
    final n = _items[i];
    if (n.read) return;
    setState(() => _items[i] = ShopNotification(
        id: n.id, type: n.type, title: n.title, body: n.body, read: true, createdAt: n.createdAt));
    app.noteRead();
    app.notificationsApi.markRead(n.id).catchError((_) {});
  }

  Widget _typeIcon(String type) {
    final t = type.toUpperCase();
    if (t.contains('ORDER')) return Ic.box(AppColors.accent, 20);
    if (t.contains('LOYAL') || t.contains('CASH') || t.contains('POINT')) return Ic.qr(AppColors.accent, 20);
    if (t.contains('CAMP') || t.contains('PROMO') || t.contains('COUPON')) return Ic.ticket(AppColors.accent, 20);
    return Ic.bell(AppColors.accent, 20);
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _items.any((n) => !n.read);
    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          NavHeader(
            title: tr('Билдиришномалар'),
            onBack: app.pop,
            right: hasUnread
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _markAllRead,
                    child: Tooltip(
                      message: tr2('Ҳаммасини ўқилган деб белгилаш', 'Отметить все прочитанными'),
                      child: SizedBox(width: 44, height: 44, child: Center(child: Ic.check(AppColors.accent, 22))),
                    ),
                  )
                : null,
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (!app.isLoggedIn) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          children: [
            loginPromptColumn(app,
                icon: Ic.bell(AppColors.accent, 40),
                title: tr('Билдиришномалар'),
                body: tr2('Билдиришномаларни кўриш учун тизимга киринг.', 'Войдите, чтобы видеть уведомления.')),
          ],
        ),
      );
    }
    if (_loading) return const CenterLoader();
    if (_error != null) return ErrorView(message: _error, onRetry: _load);
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Ic.bell(AppColors.ter, 48),
              const SizedBox(height: 14),
              Text(tr2('Билдиришномалар йўқ', 'Нет уведомлений'), style: ts(size: 16, color: AppColors.sec)),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final n = _items[i];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _open(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: n.read ? Colors.transparent : const Color.fromRGBO(13, 148, 136, 0.04),
                border: i < _items.length - 1
                    ? const Border(bottom: BorderSide(color: AppColors.sep, width: 0.5))
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(color: AppColors.accentDim, shape: BoxShape.circle),
                    child: Center(child: _typeIcon(n.type)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(n.title,
                                  style: ts(size: 15.5, weight: FontWeight.w600, color: AppColors.text, letterSpacing: -0.2)),
                            ),
                            if (!n.read)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 6, top: 4),
                                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                              ),
                          ],
                        ),
                        if (n.body.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(n.body, style: ts(size: 14.5, color: AppColors.sec, letterSpacing: -0.15, height: 1.4)),
                        ],
                        const SizedBox(height: 5),
                        Text(formatDate(n.createdAt), style: ts(size: 12.5, color: AppColors.ter)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Wallet (loyalty / cashback) — root tab ──────────────────────────────────
class WalletScreen extends StatefulWidget {
  final AppState app;
  const WalletScreen({super.key, required this.app});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  LoyaltyData? _data;
  bool _loading = false;
  String? _error;
  String? _loadedFor;

  AppState get app => widget.app;

  void _maybeLoad() {
    final phone = app.user?.phone;
    if (phone == null || _loadedFor == phone) return;
    _loadedFor = phone;
    _loading = true;
    _error = null;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final d = await app.loyalty.loyalty();
        if (mounted) {
          setState(() {
          _data = d;
          _loading = false;
        });
        }
      } on ApiException catch (e) {
        if (mounted) {
          setState(() {
          _error = e.message;
          _loading = false;
        });
        }
      }
    });
  }

  Future<void> _refresh() async {
    if (!app.isLoggedIn) return;
    try {
      final d = await app.loyalty.loyalty();
      if (mounted) {
        setState(() {
        _data = d;
        _error = null;
      });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  /// A scannable wallet QR is only possible once the API exposes a customer
  /// code and a tenant slug. Until then we say so honestly rather than render
  /// a decorative pattern that a cashier cannot scan.
  bool get _hasWalletQr {
    final code = app.user?.customerCode ?? '';
    final slug = (app.user?.tenantSlug.isNotEmpty ?? false) ? app.user!.tenantSlug : ApiConfig.tenantSlug;
    return code.isNotEmpty && slug.isNotEmpty && ApiConfig.walletQrBase.isNotEmpty;
  }

  /// Real scannable QR encoding the loyalty deep link `$base/$slug/$code`.
  Widget _walletQr() {
    final slug = app.user!.tenantSlug.isNotEmpty ? app.user!.tenantSlug : ApiConfig.tenantSlug;
    return QrImageView(
      data: '${ApiConfig.walletQrBase}/$slug/${app.user!.customerCode}',
      version: QrVersions.auto,
      size: 196,
      backgroundColor: Colors.white,
      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0B0B0C)),
      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF0B0B0C)),
    );
  }

  /// Honest placeholder shown when no scannable code is available yet.
  Widget _qrUnavailable() {
    return Container(
      width: 196,
      height: 196,
      decoration: BoxDecoration(color: AppColors.fill, borderRadius: BorderRadius.circular(AppRadii.card)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Ic.qr(AppColors.ter, 44),
            const SizedBox(height: 10),
            Text(tr('QR код тайёрланмоқда'), style: ts(size: 14, color: AppColors.sec, letterSpacing: -0.2)),
          ],
        ),
      ),
    );
  }

  /// "Scan at checkout" help sheet — explains the cashier flow.
  void _showScanHelp(BuildContext context) {
    final steps = [
      tr2('Кассирга ушбу QR кодни кўрсатинг', 'Покажите этот QR кассиру'),
      tr2('Кассир кодни сканерлайди', 'Кассир сканирует код'),
      tr2('Кешбек ҳамёнингизга қўшилади ёки тўловда ишлатилади',
          'Кешбэк начислится на кошелёк или спишется при оплате'),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(60, 60, 67, 0.25),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(color: AppColors.accentDim, shape: BoxShape.circle),
                child: Center(child: Ic.qr(AppColors.accent, 28)),
              ),
              const SizedBox(height: 14),
              Text(tr2('Кассада тўлаш', 'Оплата на кассе'),
                  textAlign: TextAlign.center,
                  style: ts(size: 19, weight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.3)),
              const SizedBox(height: 18),
              for (var i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(color: AppColors.accentDim, shape: BoxShape.circle),
                        child: Center(
                          child: Text('${i + 1}', style: ts(size: 14, weight: FontWeight.w700, color: AppColors.accent)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(steps[i], style: ts(size: 15.5, color: AppColors.text, letterSpacing: -0.2, height: 1.4)),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              BigButton(
                onTap: () => Navigator.of(sheetCtx).pop(),
                child: Text(tr2('Тушунарли', 'Понятно')),
              ),
            ],
          ),
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
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: top + 12, left: 16, right: 16),
              child: Align(alignment: Alignment.centerLeft, child: LargeTitle(tr('Ҳамён'))),
            ),
            loginPromptColumn(app,
                icon: Ic.qr(AppColors.accent, 40),
                title: tr('Кешбек ҳамёни'),
                body: tr2('Кешбек йиғиш ва QR ҳамёнингизни кўриш учун тизимга киринг.',
                    'Войдите, чтобы копить кешбэк и видеть ваш QR-кошелёк.')),
          ],
        ),
      );
    }

    _maybeLoad();
    final title = Padding(
      padding: EdgeInsets.only(top: top + 12, left: 16, right: 16),
      child: Align(alignment: Alignment.centerLeft, child: LargeTitle(tr('Ҳамён'))),
    );

    if (_loading) {
      return Container(color: AppColors.bg, child: Column(children: [title, const Expanded(child: CenterLoader())]));
    }
    if (_error != null) {
      return Container(
        color: AppColors.bg,
        child: Column(children: [title, Expanded(child: ErrorView(message: _error, onRetry: () {
          _loadedFor = null;
          setState(_maybeLoad);
        }))]),
      );
    }

    final data = _data;
    return Container(
      color: AppColors.bg,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: tabBarHeight(context) + 24),
        children: [
          title,
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(color: AppColors.accentDim, borderRadius: BorderRadius.circular(AppRadii.card)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('Кешбек баланс').toUpperCase(),
                      style: ts(size: 13.5, weight: FontWeight.w600, color: AppColors.accent, letterSpacing: 0.4)),
                  const SizedBox(height: 4),
                  Text(formatSum(data?.balance ?? 0),
                      style: ts(size: 30, weight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.5)),
                  if (data != null && data.enabled && data.minRedeem > 0) ...[
                    const SizedBox(height: 4),
                    Text(tr2('Минимал ечиш: ${formatSum(data.minRedeem)}', 'Мин. к списанию: ${formatSum(data.minRedeem)}'),
                        style: ts(size: 13.5, color: AppColors.sec)),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.sep),
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: _hasWalletQr
                  ? Column(
                      children: [
                        _walletQr(),
                        const SizedBox(height: 12),
                        Text(app.user!.customerCode,
                            style: TextStyle(fontFamily: kMonoFamily, fontSize: 13.5, color: AppColors.sec, letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: Text(tr('Кассада QR кодни кўрсатинг — кешбек ҳамёнингизга ўтказилади'),
                              textAlign: TextAlign.center, style: ts(size: 14, color: AppColors.sec, letterSpacing: -0.15, height: 1.45)),
                        ),
                        const SizedBox(height: 6),
                        ShopTextButton(
                          fontSize: 14,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          onTap: () => _showScanHelp(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.help_outline_rounded, size: 16, color: AppColors.accent),
                              const SizedBox(width: 6),
                              Text(tr2('Қандай ишлайди?', 'Как это работает?')),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _qrUnavailable(),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: Text(tr('Кешбек баланси ҳисобингизда сақланади. QR код тез орада фаоллашади.'),
                              textAlign: TextAlign.center, style: ts(size: 14, color: AppColors.sec, letterSpacing: -0.15, height: 1.45)),
                        ),
                      ],
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(tr('Ҳаракатлар')),
                const SizedBox(height: 10),
                if (data == null || data.entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Center(child: Text(tr2('Ҳаракатлар йўқ', 'Нет операций'), style: ts(size: 15, color: AppColors.sec))),
                  )
                else
                  for (var i = 0; i < data.entries.length; i++) _txRow(data.entries[i], i, data.entries.length),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _txRow(LoyaltyEntry tx, int i, int count) {
    final label = tx.orderNumber ?? tx.note ?? tx.type;
    final positive = tx.amount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
      decoration: i < count - 1
          ? const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.sep, width: 0.5)))
          : null,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: ts(size: 15, color: AppColors.text, letterSpacing: -0.2)),
                const SizedBox(height: 2),
                Text(formatDate(tx.createdAt), style: ts(size: 13, color: AppColors.ter)),
              ],
            ),
          ),
          Text(
            '${positive ? '+' : '−'}${formatSum(tx.amount.abs())}',
            style: ts(size: 15.5, weight: FontWeight.w600, color: positive ? AppColors.green : AppColors.text)
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}

// ── Coupons (/web/me/coupons) ───────────────────────────────────────────────
class CouponsScreen extends StatefulWidget {
  final AppState app;
  const CouponsScreen({super.key, required this.app});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  List<Coupon> _items = [];
  bool _loading = true;
  String? _error;

  AppState get app => widget.app;

  @override
  void initState() {
    super.initState();
    if (app.isLoggedIn) {
      _load();
    } else {
      _loading = false;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await app.couponsApi.list();
      if (!mounted) return;
      setState(() {
        _items = list;
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

  String _valueLabel(Coupon c) {
    final v = c.discountValue;
    if (c.isPercent && v != null) return '−${v.toStringAsFixed(0)}%';
    if (c.isFixed && v != null) return formatSum(v);
    // Exotic types (BUY_X_GET_Y, BUNDLE, …) or missing value → generic chip.
    return tr2('Промо', 'Промо');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          NavHeader(title: tr('Купонлар'), onBack: app.pop),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (!app.isLoggedIn) {
      return loginPromptColumn(app,
          icon: Ic.ticket(AppColors.accent, 40),
          title: tr('Купонлар'),
          body: tr2('Купонларингизни кўриш учун тизимга киринг.', 'Войдите, чтобы видеть ваши купоны.'));
    }
    if (_loading) return const CenterLoader();
    if (_error != null) return ErrorView(message: _error, onRetry: _load);
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Ic.ticket(AppColors.ter, 48),
              const SizedBox(height: 14),
              Text(tr('Ҳозирча купонлар йўқ'), style: ts(size: 15.5, color: AppColors.sec)),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        itemCount: _items.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _couponCard(_items[i]),
        ),
      ),
    );
  }

  Widget _couponCard(Coupon c) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.sep),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                Container(
                  width: 92,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
                  alignment: Alignment.center,
                  color: AppColors.accentDim,
                  child: Text(_valueLabel(c),
                      textAlign: TextAlign.center,
                      style: ts(size: 16, weight: FontWeight.w700, color: AppColors.accent, letterSpacing: -0.3, height: 1.2)),
                ),
                const Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: DashedVLine(color: Color.fromRGBO(13, 148, 136, 0.35)),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (c.title.isNotEmpty)
                      Text(c.title, style: ts(size: 15, weight: FontWeight.w600, color: AppColors.text, letterSpacing: -0.2)),
                    if (c.minOrderAmount != null && c.minOrderAmount! > 0) ...[
                      const SizedBox(height: 2),
                      Text('${tr2('Мин. буюртма', 'Мин. заказ')}: ${formatSum(c.minOrderAmount)}',
                          style: ts(size: 13, color: AppColors.sec)),
                    ],
                    if (c.endDate != null) ...[
                      const SizedBox(height: 2),
                      Text('${tr2('амал қилади', 'действует до')} ${formatDate(c.endDate!)}',
                          style: ts(size: 13, color: AppColors.sec)),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.fill, borderRadius: BorderRadius.circular(6)),
                          child: Text(c.code,
                              style: TextStyle(
                                  fontFamily: kMonoFamily, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text, letterSpacing: 0.5)),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: c.code));
                            app.toast('${tr('Код нусха олинди')}: ${c.code}');
                          },
                          child: Padding(padding: const EdgeInsets.all(4), child: Ic.copy()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Referrals (real code + pending stats) ───────────────────────────────────
class ReferralsScreen extends StatefulWidget {
  final AppState app;
  const ReferralsScreen({super.key, required this.app});

  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen> {
  ReferralStats? _stats;
  bool _loading = false;
  String? _error;

  AppState get app => widget.app;

  @override
  void initState() {
    super.initState();
    if (app.isLoggedIn) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await app.referral.stats();
      if (mounted) {
        setState(() {
          _stats = s;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
        _error = e.message;
        _loading = false;
      });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!app.isLoggedIn) {
      return Container(
        color: AppColors.bg,
        child: Column(
          children: [
            NavHeader(title: tr('Дўстларни таклиф қилиш'), onBack: app.pop),
            loginPromptColumn(app,
                icon: Ic.gift(AppColors.accent, 40),
                title: tr('Дўстларни таклиф қилиш'),
                body: tr2('Таклиф кодингизни олиш учун тизимга киринг.', 'Войдите, чтобы получить реферальный код.')),
          ],
        ),
      );
    }

    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          NavHeader(title: tr('Дўстларни таклиф қилиш'), onBack: app.pop),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
              children: [
                Column(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(color: AppColors.accentDim, shape: BoxShape.circle),
                      child: Center(child: Ic.gift(AppColors.accent, 36)),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Text(
                        tr2('Дўстингиз сизнинг кодингиз билан биринчи буюртма берса — иккалангиз ҳам кешбек оласиз.',
                            'Если друг сделает первый заказ с вашим кодом — вы оба получите кешбэк.'),
                        textAlign: TextAlign.center,
                        style: ts(size: 15.5, color: AppColors.text, letterSpacing: -0.2, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_loading)
                      const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Spinner())
                    else if (_error != null)
                      ErrorView(message: _error, onRetry: _load)
                    else
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _stats?.code ?? ''));
                          app.toast(tr('Код нусха олинди'));
                        },
                        child: DashedRRect(
                          radius: 12,
                          fill: AppColors.fill,
                          borderColor: const Color.fromRGBO(60, 60, 67, 0.30),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_stats?.code ?? '—',
                                  style: TextStyle(fontFamily: kMonoFamily, fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: 1.5)),
                              const SizedBox(width: 10),
                              Ic.copy(AppColors.sec, 18),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),
                    BigButton(onTap: () => app.toast(tr('Telegram орқали улашиш')), child: Text(tr('Telegram орқали улашиш'))),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _statCard('${_stats?.invitedCount ?? 0}', tr('Таклиф қилинган'), AppColors.text)),
                        const SizedBox(width: 12),
                        Expanded(child: _statCard('+${formatSum(_stats?.pointsEarned ?? 0)}', tr('Олинган бонус'), AppColors.green)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Align(alignment: Alignment.centerLeft, child: SectionHeader(tr('Қандай ишлайди'))),
                    const SizedBox(height: 12),
                    for (var i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(color: AppColors.accentDim, shape: BoxShape.circle),
                              child: Center(
                                child: Text('${i + 1}', style: ts(size: 13.5, weight: FontWeight.w700, color: AppColors.accent)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tr(const [
                                  'Кодингизни дўстингизга юборинг',
                                  'Дўстингиз буюртма беришда кодни киритади',
                                  'Иккалангиз ҳам кешбек оласиз',
                                ][i]),
                                style: ts(size: 15, color: AppColors.text, letterSpacing: -0.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.sep),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: ts(size: 24, weight: FontWeight.w700, color: valueColor, letterSpacing: -0.4)),
          const SizedBox(height: 3),
          Text(label, style: ts(size: 13.5, color: AppColors.sec, letterSpacing: -0.1)),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/api/api_client.dart';
import '../data/api/api_config.dart';
import '../data/format.dart';
import '../data/models.dart';
import '../data/strings.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/components.dart';
import '../widgets/icons.dart';

/// Online payment for a just-placed CARD order: pick a provider, open its
/// checkout page, then poll `/web/orders/{n}/payment` until it's paid.
/// "Pay later" (and the back arrow) fall through to the regular success
/// screen — the courier can still take the payment on delivery.
class PaymentScreen extends StatefulWidget {
  final AppState app;
  final String orderNumber;
  final double total;
  const PaymentScreen(
      {super.key, required this.app, required this.orderNumber, required this.total});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with WidgetsBindingObserver {
  /// Auto-polling stops after this many rounds (~3 min); the manual check
  /// button and the on-resume check keep working.
  static const _maxPolls = 36;

  String? _activeProvider; // provider whose checkout link is being created
  String? _paymentId; // opaque id returned by create, used to poll status
  bool _waiting = false; // checkout page opened, awaiting confirmation
  bool _checking = false; // manual status check (drives the button spinner)
  bool _checkBusy = false; // any status check in flight (poll + manual guard)
  String? _error;
  Timer? _poll;
  int _polls = 0;

  AppState get app => widget.app;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the provider's app/browser — check the status right away.
    if (state == AppLifecycleState.resumed && _waiting) _check(silent: true);
  }

  String get _phoneE164 {
    final local = app.lastOrderPhone.isNotEmpty ? app.lastOrderPhone : (app.user?.phone ?? '');
    return phoneToE164(local);
  }

  /// Checkout replaces straight onto this screen (previous entry is the cart
  /// root) and the success screen's "Тўлаш" pushes it; both should land on
  /// the success screen. The pay-again flow (history / status lookup) pops
  /// back instead.
  bool get _fromCheckout {
    final st = app.stack;
    if (st.length < 2) return false;
    final prev = st[st.length - 2].name;
    return prev == 'cart' || prev == 'success';
  }

  void _finish({required bool paid}) {
    _poll?.cancel();
    if (_fromCheckout) {
      app.replace(ScreenSpec('success',
          orderNumber: widget.orderNumber,
          total: widget.total,
          payMethod: 'CARD',
          paid: paid));
    } else {
      app.pop(); // back to the order list / status lookup
    }
  }

  Future<void> _pay(String provider) async {
    if (_activeProvider != null) return;
    // Never move money over cleartext in a release build.
    if (kReleaseMode && !ApiConfig.apiIsSecure) {
      setState(() => _error = tr('Хавфсиз уланиш йўқ. Тўлов вақтинча мавжуд эмас.'));
      return;
    }
    setState(() {
      _activeProvider = provider;
      _error = null;
    });
    try {
      final p =
          await app.payments.create(widget.orderNumber, phoneE164: _phoneE164, provider: provider);
      if (p.paymentUrl.isEmpty) throw ApiException(tr('Тўлов ҳаволасини олиб бўлмади'));
      // Only hand a validated HTTPS provider URL to the OS.
      if (!ApiConfig.isAllowedPaymentUrl(p.paymentUrl)) {
        throw ApiException(tr('Тўлов ҳаволаси хавфсиз эмас'));
      }
      final ok = await launchUrl(Uri.parse(p.paymentUrl), mode: LaunchMode.externalApplication);
      if (!ok) throw ApiException(tr('Тўлов ҳаволасини очиб бўлмади'));
      if (!mounted) return;
      _paymentId = p.id;
      setState(() => _waiting = true);
      _poll?.cancel();
      _polls = 0;
      _poll = Timer.periodic(const Duration(seconds: 5), (t) {
        if (++_polls > _maxPolls) {
          t.cancel();
          return;
        }
        _check(silent: true);
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = tr('Тўлов ҳаволасини очиб бўлмади'));
    } finally {
      if (mounted) setState(() => _activeProvider = null);
    }
  }

  Future<void> _check({bool silent = false}) async {
    final id = _paymentId;
    if (id == null || _checkBusy) return;
    _checkBusy = true;
    if (!silent) setState(() => _checking = true);
    try {
      final p = await app.payments.status(id);
      if (!mounted) return;
      if (p.isPaid) {
        app.markLocalOrderPaid(widget.orderNumber);
        app.toast(tr('Тўлов қабул қилинди!'));
        _finish(paid: true);
        return;
      }
      if (p.isFailed) {
        _poll?.cancel();
        setState(() {
          _waiting = false;
          _error = tr('Тўлов амалга ошмади. Қайта уриниб кўринг.');
        });
        return;
      }
      if (!silent) app.toast(tr('Тўлов ҳали тасдиқланмади'));
    } on ApiException catch (e) {
      if (!silent && mounted) app.toast(e.message);
    } finally {
      _checkBusy = false;
      if (!silent && mounted) setState(() => _checking = false);
    }
  }

  void _payLater() => _finish(paid: false);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          NavHeader(title: tr('Тўлов'), onBack: _payLater),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                      color: AppColors.accentDim,
                      borderRadius: BorderRadius.circular(AppRadii.card)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('Тўлов суммаси').toUpperCase(),
                          style: ts(
                              size: 13.5,
                              weight: FontWeight.w600,
                              color: AppColors.accent,
                              letterSpacing: 0.4)),
                      const SizedBox(height: 4),
                      Text(formatSum(widget.total),
                          style: ts(
                              size: 30,
                              weight: FontWeight.w700,
                              color: AppColors.text,
                              letterSpacing: -0.5)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: widget.orderNumber));
                          app.toast(tr('Нусха олинди'));
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(widget.orderNumber,
                                style: TextStyle(
                                    fontFamily: kMonoFamily,
                                    fontSize: 13.5,
                                    color: AppColors.sec,
                                    letterSpacing: 0.5)),
                            const SizedBox(width: 6),
                            Ic.copy(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (!_waiting) ...[
                  SectionHeader(tr('Тўлов усулини танланг')),
                  const SizedBox(height: 12),
                  for (final (i, e) in paymentProviders.entries.indexed) ...[
                    if (i > 0) const SizedBox(height: 10),
                    OptionCard(
                      icon: Text(e.value.name.substring(0, 1),
                          style: ts(size: 16, weight: FontWeight.w700, color: e.value.color)),
                      tileColor: e.value.color.withValues(alpha: 0.10),
                      title: e.value.name,
                      trailing: _activeProvider == e.key ? const Spinner(size: 18) : Ic.chevronR(),
                      onTap: () => _pay(e.key),
                    ),
                  ],
                ] else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.sep),
                      borderRadius: BorderRadius.circular(AppRadii.card),
                    ),
                    child: Column(
                      children: [
                        const Spinner(size: 26),
                        const SizedBox(height: 14),
                        Text(tr('Тўлов кутилмоқда'),
                            style: ts(
                                size: 17,
                                weight: FontWeight.w600,
                                color: AppColors.text,
                                letterSpacing: -0.25)),
                        const SizedBox(height: 5),
                        Text(tr('Тўловни якунлаб, иловага қайтинг'),
                            textAlign: TextAlign.center,
                            style: ts(
                                size: 14.5,
                                color: AppColors.sec,
                                letterSpacing: -0.15,
                                height: 1.45)),
                        const SizedBox(height: 18),
                        BigButton(
                            loading: _checking,
                            onTap: () => _check(),
                            child: Text(tr('Тўловни текшириш'))),
                        const SizedBox(height: 4),
                        ShopTextButton(
                          onTap: () {
                            _poll?.cancel();
                            setState(() => _waiting = false);
                          },
                          child: Text(tr('Бошқа усул билан тўлаш')),
                        ),
                      ],
                    ),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: ts(size: 14.5, color: AppColors.red, height: 1.4)),
                  ),
                const SizedBox(height: 22),
                Center(child: ShopTextButton(onTap: _payLater, child: Text(tr('Кейинроқ тўлайман')))),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(tr('Курьерга нақд ёки карта орқали тўлашингиз мумкин'),
                      textAlign: TextAlign.center,
                      style: ts(size: 13, color: AppColors.ter, height: 1.45)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


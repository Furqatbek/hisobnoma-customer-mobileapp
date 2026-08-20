import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisobnoma_shop/data/api/api_client.dart';
import 'package:hisobnoma_shop/data/api/token_store.dart';
import 'package:hisobnoma_shop/data/repositories.dart';

import 'support/fake_adapter.dart';

ApiClient _client(FutureOr<ResponseBody> Function(RequestOptions) onFetch) =>
    ApiClient(TokenStore(), adapter: FakeAdapter(onFetch));

void main() {
  group('ApiClient friendly errors (#16)', () {
    test('5xx with no body → friendly server message, not a raw code', () async {
      final c = _client((_) => jsonBody({}, 500));
      try {
        await c.getData('/web/x');
        fail('should have thrown');
      } on ApiException catch (e) {
        expect(e.status, 500);
        expect(e.message, contains('Серверда'));
        expect(e.message, isNot(contains('500')));
      }
    });

    test('4xx with a server message passes it through', () async {
      final c = _client((_) => jsonBody({'message': 'Bu kupon eskirgan'}, 400));
      try {
        await c.getData('/web/x');
        fail('should have thrown');
      } on ApiException catch (e) {
        expect(e.message, 'Bu kupon eskirgan');
      }
    });

    test('documented error body: message nested inside `error`', () async {
      // MOBILE_SHOP_API.md: {success:false, error:{code, message}}
      final c = _client((_) => jsonBody({
            'success': false,
            'error': {'code': 'VALIDATION_ERROR', 'message': 'Coupon is invalid or expired'}
          }, 400));
      try {
        await c.getData('/web/x');
        fail('should have thrown');
      } on ApiException catch (e) {
        expect(e.message, 'Coupon is invalid or expired');
        expect(e.code, 'VALIDATION_ERROR');
      }
    });
  });

  group('PageResponse shape (MOBILE_SHOP_API.md)', () {
    test('unwraps {success, data:{content, page}} and derives `last`', () async {
      final c = _client((_) => jsonBody({
            'success': true,
            'data': {
              'content': [
                {'id': 1, 'name': 'Cola 1L'}
              ],
              // Documented page block has size/totalElements but no `last`.
              'page': {'number': 2, 'size': 20, 'totalElements': 42, 'totalPages': 3}
            }
          }, 200));
      final page = await c.getPage('/web/catalog/products', (j) => j['name'] as String);
      expect(page.content, ['Cola 1L']);
      expect(page.number, 2);
      expect(page.totalPages, 3);
      expect(page.last, true); // 2 == totalPages-1 → derived last
    });

    test('bare {content, page} without the envelope still parses', () async {
      final c = _client((_) => jsonBody({
            'content': [
              {'id': 1, 'name': 'x'}
            ],
            'page': {'number': 0, 'totalPages': 3}
          }, 200));
      final page = await c.getPage('/web/catalog/products', (j) => j['name'] as String);
      expect(page.content.length, 1);
      expect(page.last, false);
    });
  });

  group('PaymentRepository contract (#11/#24)', () {
    test('create posts phone in the body, never the query string', () async {
      RequestOptions? captured;
      final repo = PaymentRepository(_client((o) {
        captured = o;
        return jsonBody({
          'data': {'id': 'pay_1', 'paymentUrl': 'https://checkout.paycom.uz/x', 'status': 'PENDING'}
        }, 200);
      }));

      final p = await repo.create('WO-000042', phoneE164: '+998901234567', provider: 'PAYME');
      expect(p.id, 'pay_1');
      expect(p.paymentUrl, 'https://checkout.paycom.uz/x');
      expect(p.status, 'PENDING');

      expect(captured!.method, 'POST');
      expect(captured!.uri.query, isEmpty, reason: 'no PII in the URL');
      expect((captured!.data as Map)['phone'], '+998901234567');
      expect((captured!.data as Map)['provider'], 'PAYME');
    });

    test('status is fetched by opaque id with no phone in the URL', () async {
      RequestOptions? captured;
      final repo = PaymentRepository(_client((o) {
        captured = o;
        return jsonBody({
          'data': {'id': 'pay_1', 'status': 'PAID'}
        }, 200);
      }));

      final p = await repo.status('pay_1');
      expect(p.isPaid, true);
      expect(captured!.uri.path, contains('/web/payments/pay_1'));
      expect(captured!.uri.query, isEmpty);
    });

    test('deleteMe issues DELETE /web/me with no query', () async {
      RequestOptions? captured;
      final repo = AuthRepository(_client((o) {
        captured = o;
        return jsonBody({'success': true, 'message': 'Account deleted'}, 200);
      }));
      await repo.deleteMe();
      expect(captured!.method, 'DELETE');
      expect(captured!.uri.path, endsWith('/web/me'));
      expect(captured!.uri.query, isEmpty); // account comes from the token
    });

    test('409 ACCOUNT_HAS_ACTIVE_ORDERS surfaces code + message', () async {
      final repo = AuthRepository(_client((_) => jsonBody({
            'success': false,
            'error': {
              'code': 'ACCOUNT_HAS_ACTIVE_ORDERS',
              'message': 'Фаол буюртмангиз бор. Етказиб берилгач қайта уриниб кўринг.'
            }
          }, 409)));
      try {
        await repo.deleteMe();
        fail('should have thrown');
      } on ApiException catch (e) {
        expect(e.status, 409);
        expect(e.code, 'ACCOUNT_HAS_ACTIVE_ORDERS');
        expect(e.message, contains('Фаол буюртмангиз'));
      }
    });

    test('503 PAYMENT_NOT_CONFIGURED surfaces as a coded ApiException', () async {
      final repo = PaymentRepository(_client((_) => jsonBody({
            'success': false,
            'error': {'code': 'PAYMENT_NOT_CONFIGURED'}
          }, 503)));
      try {
        await repo.create('WO-1', phoneE164: '+998900000000', provider: 'PAYME');
        fail('should have thrown');
      } on ApiException catch (e) {
        expect(e.status, 503);
        expect(e.code, 'PAYMENT_NOT_CONFIGURED');
      }
    });
  });
}

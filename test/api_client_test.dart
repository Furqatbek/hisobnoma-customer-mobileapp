import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisobnoma_shop/data/api/api_client.dart';
import 'package:hisobnoma_shop/data/api/token_store.dart';
import 'package:hisobnoma_shop/data/repositories.dart';

/// A Dio transport stub so we can exercise ApiClient / repositories through the
/// real request path without a network — the injection seam added for #24.
class _FakeAdapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions options) onFetch;
  _FakeAdapter(this.onFetch);
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
          RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      await onFetch(options);
}

ResponseBody _json(Map<String, dynamic> body, int status) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json; charset=utf-8'],
      },
    );

ApiClient _client(FutureOr<ResponseBody> Function(RequestOptions) onFetch) =>
    ApiClient(TokenStore(), adapter: _FakeAdapter(onFetch));

void main() {
  group('ApiClient friendly errors (#16)', () {
    test('5xx with no body → friendly server message, not a raw code', () async {
      final c = _client((_) => _json({}, 500));
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
      final c = _client((_) => _json({'message': 'Bu kupon eskirgan'}, 400));
      try {
        await c.getData('/web/x');
        fail('should have thrown');
      } on ApiException catch (e) {
        expect(e.message, 'Bu kupon eskirgan');
      }
    });
  });

  group('PaymentRepository contract (#11/#24)', () {
    test('create posts phone in the body, never the query string', () async {
      RequestOptions? captured;
      final repo = PaymentRepository(_client((o) {
        captured = o;
        return _json({
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
        return _json({
          'data': {'id': 'pay_1', 'status': 'PAID'}
        }, 200);
      }));

      final p = await repo.status('pay_1');
      expect(p.isPaid, true);
      expect(captured!.uri.path, contains('/web/payments/pay_1'));
      expect(captured!.uri.query, isEmpty);
    });
  });
}

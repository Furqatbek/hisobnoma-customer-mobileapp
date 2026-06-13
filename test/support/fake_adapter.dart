import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A Dio transport stub so tests can drive ApiClient / repositories / screens
/// through the real request path without a network (uses the adapter seam
/// added for #24).
class FakeAdapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions options) onFetch;
  FakeAdapter(this.onFetch);
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
          RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      await onFetch(options);
}

ResponseBody jsonBody(Map<String, dynamic> body, int status) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json; charset=utf-8'],
      },
    );

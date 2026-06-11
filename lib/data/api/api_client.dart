import 'package:dio/dio.dart';

import 'api_config.dart';
import 'token_store.dart';

/// Error surfaced to the UI for any failed call.
class ApiException implements Exception {
  final String message;
  final String? code;
  final int? status;
  ApiException(this.message, {this.code, this.status});

  bool get isUnauthorized => status == 401;
  @override
  String toString() => message;
}

/// A page of results from a `{ content, page }` endpoint.
class Page<T> {
  final List<T> content;
  final int number;
  final int totalPages;
  final bool last;
  const Page({required this.content, required this.number, required this.totalPages, required this.last});
}

/// Thin wrapper over Dio that injects tenant + bearer headers and unwraps the
/// `{ success, data }` envelope (and `{ content, page }` paging).
class ApiClient {
  ApiClient(this._tokens) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'X-Tenant-ID': ApiConfig.tenantId},
      // We validate status ourselves so we can read the error envelope.
      validateStatus: (_) => true,
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final t = _tokens.current;
        if (t != null) options.headers['Authorization'] = 'Bearer $t';
        handler.next(options);
      },
    ));
  }

  late final Dio _dio;
  final TokenStore _tokens;

  /// Called when any /me call returns 401 so the app can drop the session.
  void Function()? onUnauthorized;

  ApiException _mapError(Object e) {
    if (e is ApiException) return e;
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return ApiException('Тармоққа уланиб бўлмади', code: 'NETWORK');
      }
    }
    return ApiException('Кутилмаган хатолик', code: 'UNKNOWN');
  }

  /// Reads the HTTP response, throwing [ApiException] on error envelopes/status.
  dynamic _check(Response res) {
    final status = res.statusCode ?? 0;
    final body = res.data;
    if (status == 401) {
      onUnauthorized?.call();
      throw ApiException('Сессия тугади', code: 'UNAUTHORIZED', status: 401);
    }
    if (status >= 200 && status < 300) return body;
    String msg = 'Хатолик ($status)';
    String? code;
    if (body is Map) {
      if (body['message'] is String) msg = body['message'];
      final err = body['error'];
      if (err is Map && err['code'] is String) code = err['code'];
    }
    throw ApiException(msg, code: code, status: status);
  }

  /// Unwraps `{ success, data }` and returns `data`.
  dynamic _data(dynamic body) {
    if (body is Map && body.containsKey('data')) return body['data'];
    return body;
  }

  Future<dynamic> getData(String path, {Map<String, dynamic>? query}) async {
    try {
      return _data(_check(await _dio.get(path, queryParameters: query)));
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<dynamic> postData(String path, {Object? body}) async {
    try {
      return _data(_check(await _dio.post(path, data: body)));
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> put(String path) async {
    try {
      _check(await _dio.put(path));
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> delete(String path, {Map<String, dynamic>? query}) async {
    try {
      _check(await _dio.delete(path, queryParameters: query));
    } catch (e) {
      throw _mapError(e);
    }
  }

  /// Fetches a `{ content, page }` page and maps each element via [parse].
  Future<Page<T>> getPage<T>(
    String path,
    T Function(Map<String, dynamic>) parse, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final body = _check(await _dio.get(path, queryParameters: query));
      final content = (body['content'] as List? ?? [])
          .map((e) => parse(e as Map<String, dynamic>))
          .toList();
      final pg = (body['page'] as Map?) ?? const {};
      return Page<T>(
        content: content,
        number: (pg['number'] as num?)?.toInt() ?? 0,
        totalPages: (pg['totalPages'] as num?)?.toInt() ?? 1,
        last: pg['last'] == true,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }
}

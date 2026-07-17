import 'dart:convert';
import 'dart:async';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:panenin/core/config/app_config.dart';
import 'package:panenin/core/network/api_exception.dart';
import 'package:panenin/features/auth/data/models/authenticated_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ApiTransport {
  Future<Object?> get(String path);
  Future<Object?> post(String path, {Object? body});
  Future<Object?> put(String path, {Object? body});
  Future<Object?> patch(String path, {Object? body});
}

class ApiClient implements ApiTransport {
  ApiClient(
    this._supabase, {
    http.Client? httpClient,
    String baseUrl = AppConfig.apiBaseUrl,
  }) : _httpClient = httpClient ?? http.Client(),
       _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), '');

  final SupabaseClient _supabase;
  final http.Client _httpClient;
  final String _baseUrl;
  static const _timeout = Duration(seconds: 15);

  @override
  Future<Object?> get(String path) => _request('GET', path);

  @override
  Future<Object?> post(String path, {Object? body}) =>
      _request('POST', path, body: body);

  @override
  Future<Object?> put(String path, {Object? body}) =>
      _request('PUT', path, body: body);

  @override
  Future<Object?> patch(String path, {Object? body}) =>
      _request('PATCH', path, body: body);

  Future<AuthenticatedUser> getCurrentUser() async {
    final data = await get('/api/v1/auth/me');
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Respons profil dari backend tidak valid.');
    }
    return AuthenticatedUser.fromJson(data);
  }

  Future<Object?> _request(String method, String path, {Object? body}) async {
    try {
      var response = await _send(
        method,
        path,
        body: body,
        accessToken: _supabase.auth.currentSession?.accessToken,
      );
      if (response.statusCode == 401) {
        final refreshed = await _supabase.auth.refreshSession();
        response = await _send(
          method,
          path,
          body: body,
          accessToken: refreshed.session?.accessToken,
        );
      }
      return _decodeEnvelope(response);
    } on TimeoutException {
      throw const ApiException(
        'Backend tidak merespons. Silakan coba lagi.',
        code: 'REQUEST_TIMEOUT',
      );
    } on http.ClientException {
      throw const ApiException(
        'Backend tidak dapat dijangkau.',
        code: 'NETWORK_ERROR',
      );
    }
  }

  Future<http.Response> _send(
    String method,
    String path, {
    required String? accessToken,
    Object? body,
  }) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException('Sesi Supabase tidak ditemukan.');
    }
    final uri = Uri.parse('$_baseUrl${path.startsWith('/') ? path : '/$path'}');
    final request = http.Request(method, uri)
      ..headers.addAll({
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Request-ID': _newRequestId(),
      });
    if (body != null) request.body = jsonEncode(body);
    final streamed = await _httpClient.send(request).timeout(_timeout);
    return http.Response.fromStream(streamed).timeout(_timeout);
  }

  Object? _decodeEnvelope(http.Response response) {
    final payload = _decodeObject(response.body);
    final requestId =
        payload['requestId'] as String? ?? response.headers['x-request-id'];
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = payload['error'];
      final errorMap = error is Map<String, dynamic> ? error : null;
      throw ApiException(
        errorMap?['message'] as String? ?? 'Permintaan ke backend gagal.',
        statusCode: response.statusCode,
        code: errorMap?['code'] as String?,
        requestId: requestId,
      );
    }
    return payload['data'];
  }

  Map<String, dynamic> _decodeObject(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // The user-facing error below is clearer than a JSON parser error.
    }
    throw const ApiException('Respons backend tidak valid.');
  }

  String _newRequestId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40;
    values[8] = (values[8] & 0x3f) | 0x80;
    final hex = values
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

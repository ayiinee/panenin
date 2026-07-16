import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:panenin/core/config/app_config.dart';
import 'package:panenin/core/network/api_exception.dart';
import 'package:panenin/features/auth/data/models/authenticated_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiClient {
  ApiClient(
    this._supabase, {
    http.Client? httpClient,
    String baseUrl = AppConfig.apiBaseUrl,
  }) : _httpClient = httpClient ?? http.Client(),
       _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), '');

  final SupabaseClient _supabase;
  final http.Client _httpClient;
  final String _baseUrl;

  Future<AuthenticatedUser> getCurrentUser() async {
    var response = await _getMe(_supabase.auth.currentSession?.accessToken);
    if (response.statusCode == 401) {
      final refreshed = await _supabase.auth.refreshSession();
      response = await _getMe(refreshed.session?.accessToken);
    }

    final payload = _decodeObject(response.body);
    if (response.statusCode != 200) {
      final error = payload['error'];
      final message = error is Map<String, dynamic>
          ? error['message'] as String?
          : null;
      throw ApiException(
        message ?? 'Backend gagal memvalidasi sesi.',
        statusCode: response.statusCode,
      );
    }

    final data = payload['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Respons profil dari backend tidak valid.');
    }
    return AuthenticatedUser.fromJson(data);
  }

  Future<http.Response> _getMe(String? accessToken) {
    if (accessToken == null) {
      throw const ApiException('Sesi Supabase tidak ditemukan.');
    }
    return _httpClient.get(
      Uri.parse('$_baseUrl/api/v1/auth/me'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
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
}

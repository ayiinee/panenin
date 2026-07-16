import 'dart:async';

import 'package:panenin/core/network/api_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String authErrorMessage(
  Object error, {
  required String fallback,
  String? timeout,
}) {
  if (error is TimeoutException) return timeout ?? fallback;
  if (error is ApiException) return error.message;
  if (error is! AuthException) return fallback;

  final message = error.message;
  final normalized = message.toLowerCase();
  if (normalized.contains('invalid login credentials')) {
    return 'Email atau kata sandi salah.';
  }
  if (normalized.contains('email not confirmed')) {
    return 'Email belum diverifikasi. Periksa kotak masukmu.';
  }
  if (normalized.contains('user already registered')) {
    return 'Email tersebut sudah terdaftar.';
  }
  if (normalized.contains('password should be at least')) {
    return 'Kata sandi belum memenuhi panjang minimum.';
  }
  if (normalized.contains('rate limit') ||
      normalized.contains('only request this after')) {
    return 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
  }
  return '$fallback: $message';
}

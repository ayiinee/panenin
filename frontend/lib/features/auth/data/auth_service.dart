import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:panenin/core/config/app_config.dart';
import 'package:panenin/core/network/api_client.dart';
import 'package:panenin/features/auth/data/models/authenticated_user.dart';
import 'package:panenin/features/auth/data/models/email_sign_up_result.dart';
import 'package:panenin/features/auth/domain/user_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef GoogleSignIn = Future<AuthenticatedUser> Function();
typedef EmailSignIn =
    Future<AuthenticatedUser> Function(String email, String password);
typedef EmailSignUp =
    Future<EmailSignUpResult> Function(
      String name,
      String email,
      String password,
    );
typedef SendPasswordReset = Future<void> Function(String email);
typedef ResendEmailVerification = Future<void> Function(String email);
typedef UpdatePassword = Future<void> Function(String password);

class AuthService {
  AuthService(this._supabase, this._apiClient);

  factory AuthService.create() {
    final supabase = Supabase.instance.client;
    return AuthService(supabase, ApiClient(supabase));
  }

  final SupabaseClient _supabase;
  final ApiClient _apiClient;

  Future<EmailSignUpResult> signUpWithEmail(
    String name,
    String email,
    String password,
  ) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: kIsWeb ? null : AppConfig.authRedirectUrl,
      data: {'name': name},
    );
    if (response.user == null) {
      throw const AuthException('Akun tidak berhasil dibuat.');
    }
    if (response.session == null) {
      return const EmailSignUpResult(requiresEmailVerification: true);
    }
    return EmailSignUpResult(
      requiresEmailVerification: false,
      user: await _apiClient.getCurrentUser(),
    );
  }

  Future<AuthenticatedUser> signInWithEmail(
    String email,
    String password,
  ) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
    return _apiClient.getCurrentUser();
  }

  Future<void> sendPasswordReset(String email) {
    return _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb ? null : AppConfig.passwordResetRedirectUrl,
    );
  }

  Future<void> resendEmailVerification(String email) async {
    await _supabase.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: kIsWeb ? null : AppConfig.authRedirectUrl,
    );
  }

  Future<void> updatePassword(String password) async {
    await _supabase.auth.updateUser(UserAttributes(password: password));
    await _supabase.auth.signOut();
  }

  Future<void> saveRole(UserRole role) async {
    await _supabase.auth.updateUser(
      UserAttributes(data: {'role': role.apiValue}),
    );
  }

  Future<void> signOut() => _supabase.auth.signOut();

  Future<AuthenticatedUser> signInWithGoogle() async {
    final signedIn = Completer<void>();
    final subscription = _supabase.auth.onAuthStateChange.listen(
      (event) {
        if (event.event == AuthChangeEvent.signedIn &&
            event.session != null &&
            !signedIn.isCompleted) {
          signedIn.complete();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!signedIn.isCompleted) {
          signedIn.completeError(error, stackTrace);
        }
      },
    );

    try {
      final launched = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : AppConfig.authRedirectUrl,
      );
      if (!launched) {
        throw const AuthException('Google login tidak dapat dibuka.');
      }

      await signedIn.future.timeout(const Duration(minutes: 2));
      return _apiClient.getCurrentUser();
    } finally {
      await subscription.cancel();
    }
  }
}

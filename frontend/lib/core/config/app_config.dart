abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const authRedirectUrl = String.fromEnvironment(
    'AUTH_REDIRECT_URL',
    defaultValue: 'com.panenin.app://login-callback/',
  );
  static const passwordResetRedirectUrl = String.fromEnvironment(
    'PASSWORD_RESET_REDIRECT_URL',
    defaultValue: 'com.panenin.app://reset-password/',
  );
  static const whatsappPhoneNumber = String.fromEnvironment(
    'WHATSAPP_PHONE_NUMBER',
  );

  static void ensureConfigured() {
    final missing = <String>[
      if (apiBaseUrl.isEmpty) 'API_BASE_URL',
      if (supabaseUrl.isEmpty) 'SUPABASE_URL',
      if (supabaseAnonKey.isEmpty) 'SUPABASE_ANON_KEY',
    ];
    if (missing.isNotEmpty) {
      throw StateError(
        'Build configuration belum lengkap: ${missing.join(', ')}. '
        'Gunakan --dart-define untuk mengisinya.',
      );
    }
  }
}

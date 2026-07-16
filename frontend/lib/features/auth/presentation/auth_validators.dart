abstract final class AuthValidators {
  static String? name(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return 'Nama pengguna wajib diisi.';
    if (normalized.length < 2) return 'Nama pengguna terlalu pendek.';
    return null;
  }

  static String? email(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return 'Alamat email wajib diisi.';
    final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized);
    if (!valid) return 'Format alamat email belum benar.';
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) return 'Kata sandi wajib diisi.';
    if (value.length < 8) return 'Kata sandi minimal 8 karakter.';
    return null;
  }

  static String? passwordConfirmation(String password, String confirmation) {
    final passwordError = AuthValidators.password(confirmation);
    if (passwordError != null) return passwordError;
    if (password != confirmation) return 'Konfirmasi kata sandi tidak sama.';
    return null;
  }
}

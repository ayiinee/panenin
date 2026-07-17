abstract final class InputValidators {
  static String? requiredText(
    String? value, {
    required String label,
    int minLength = 1,
    int maxLength = 120,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return '$label wajib diisi.';
    if (normalized.length < minLength) {
      return '$label minimal $minLength karakter.';
    }
    if (normalized.length > maxLength) {
      return '$label maksimal $maxLength karakter.';
    }
    return null;
  }

  static String? email(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return 'Alamat email wajib diisi.';
    if (normalized.length > 254) return 'Alamat email terlalu panjang.';
    final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized);
    if (!valid) return 'Format alamat email belum benar.';
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Kata sandi wajib diisi.';
    if (password.length < 8) return 'Kata sandi minimal 8 karakter.';
    if (password.length > 72) return 'Kata sandi maksimal 72 karakter.';
    return null;
  }

  static String? passwordConfirmation(String password, String? confirmation) {
    final passwordError = InputValidators.password(confirmation);
    if (passwordError != null) return passwordError;
    if (password != confirmation) return 'Konfirmasi kata sandi tidak sama.';
    return null;
  }

  static String? positiveInteger(
    String? value, {
    required String label,
    int maxValue = 999999999,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return '$label wajib diisi.';
    final number = int.tryParse(normalized);
    if (number == null) return '$label harus berupa angka bulat.';
    if (number <= 0) return '$label harus lebih dari 0.';
    if (number > maxValue) {
      return '$label maksimal ${_formatNumber(maxValue)}.';
    }
    return null;
  }

  static String? search(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Masukkan komoditas yang ingin dicari.';
    }
    if (normalized.length < 2) return 'Kata pencarian minimal 2 karakter.';
    if (normalized.length > 80) return 'Kata pencarian maksimal 80 karakter.';
    return null;
  }

  static String? chatMessage(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return 'Masukkan pesan sebelum mengirim.';
    if (normalized.length > 500) return 'Pesan maksimal 500 karakter.';
    return null;
  }

  static String _formatNumber(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
}

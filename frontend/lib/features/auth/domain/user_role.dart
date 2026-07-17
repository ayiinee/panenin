enum UserRole {
  farmer('FARMER', 'Petani'),
  buyer('BUYER', 'UMKM');

  const UserRole(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static UserRole? fromApiValue(String? value) {
    final normalized = value?.trim().toUpperCase();
    for (final role in values) {
      if (role.apiValue == normalized) return role;
    }
    return null;
  }
}

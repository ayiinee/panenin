enum UserRole {
  farmer(authValue: 'FARMER', organizationType: 'FARM', label: 'Petani'),
  buyer(authValue: 'BUYER', organizationType: 'UMKM', label: 'UMKM');

  const UserRole({
    required this.authValue,
    required this.organizationType,
    required this.label,
  });

  final String authValue;
  final String organizationType;
  final String label;

  static UserRole? fromApiValue(String? value) {
    final normalized = value?.trim().toUpperCase();
    for (final role in values) {
      if (role.authValue == normalized) return role;
    }
    return null;
  }
}

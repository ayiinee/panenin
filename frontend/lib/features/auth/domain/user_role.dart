enum UserRole {
  farmer('FARMER', 'Petani'),
  buyer('BUYER', 'UMKM');

  const UserRole(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

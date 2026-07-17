enum UserRole {
  farmer('FARM', 'Petani'),
  buyer('UMKM', 'UMKM');

  const UserRole(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

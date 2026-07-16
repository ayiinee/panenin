class AuthenticatedUser {
  const AuthenticatedUser({
    required this.id,
    this.email,
    this.name,
    this.provider,
  });

  factory AuthenticatedUser.fromJson(Map<String, dynamic> json) {
    return AuthenticatedUser(
      id: json['id'] as String,
      email: json['email'] as String?,
      name: json['name'] as String?,
      provider: json['provider'] as String?,
    );
  }

  final String id;
  final String? email;
  final String? name;
  final String? provider;
}

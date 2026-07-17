import 'package:panenin/features/auth/domain/user_role.dart';

class AuthenticatedUser {
  const AuthenticatedUser({
    required this.id,
    this.email,
    this.name,
    this.provider,
    this.role,
  });

  factory AuthenticatedUser.fromJson(Map<String, dynamic> json) {
    return AuthenticatedUser(
      id: json['id'] as String,
      email: json['email'] as String?,
      name: json['name'] as String?,
      provider: json['provider'] as String?,
      role: UserRole.fromApiValue(json['role'] as String?),
    );
  }

  final String id;
  final String? email;
  final String? name;
  final String? provider;
  final UserRole? role;
}

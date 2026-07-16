import 'package:panenin/features/auth/data/models/authenticated_user.dart';

class EmailSignUpResult {
  const EmailSignUpResult({required this.requiresEmailVerification, this.user});

  final bool requiresEmailVerification;
  final AuthenticatedUser? user;
}

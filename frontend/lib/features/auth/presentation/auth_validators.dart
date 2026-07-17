import 'package:panenin/core/validation/input_validators.dart';

abstract final class AuthValidators {
  static String? name(String value) => InputValidators.requiredText(
    value,
    label: 'Nama pengguna',
    minLength: 2,
    maxLength: 80,
  );

  static String? email(String value) => InputValidators.email(value);

  static String? password(String value) => InputValidators.password(value);

  static String? passwordConfirmation(String password, String confirmation) =>
      InputValidators.passwordConfirmation(password, confirmation);
}

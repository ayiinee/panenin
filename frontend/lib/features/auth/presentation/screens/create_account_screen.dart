import 'package:flutter/material.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_switch_link.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:panenin/features/auth/presentation/widgets/google_auth_button.dart';
import 'package:panenin/features/auth/domain/user_role.dart';
import 'package:panenin/shared/widgets/auth_shell.dart';

class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({super.key});

  void _register(BuildContext context, UserRole? selectedRole) {
    if (selectedRole != null) {
      Navigator.pushReplacementNamed(
        context,
        RouteNames.profile,
        arguments: selectedRole,
      );
      return;
    }

    _showMessage(context, 'Formulir pendaftaran siap diproses.');
  }

  void _showMessage(BuildContext context, String message) {
    FocusManager.instance.primaryFocus?.unfocus();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final selectedRole = switch (ModalRoute.of(context)?.settings.arguments) {
      UserRole role => role,
      _ => null,
    };
    final subtitle = selectedRole == null
        ? 'Kami hadir untuk membantu usahamu'
        : 'Daftar sebagai ${selectedRole.label}';

    return AuthShell(
      child: Column(
        children: [
          AuthBrandHeader(title: 'Buat Akun Anda', subtitle: subtitle),
          if (selectedRole != null)
            TextButton.icon(
              key: const ValueKey('change-role-button'),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Ubah peran'),
            ),
          const SizedBox(height: 39),
          const AuthTextField(
            label: 'Nama Pengguna',
            hint: 'Masukkan Nama Pengguna',
            obscureText: true,
          ),
          const SizedBox(height: 11),
          const AuthTextField(
            label: 'Alamat Email',
            hint: 'Masukkan Alamat Email',
            obscureText: true,
          ),
          const SizedBox(height: 11),
          const AuthTextField(
            label: 'Kata Sandi',
            hint: 'Masukkan sandi',
            obscureText: true,
          ),
          const SizedBox(height: 27),
          AuthPrimaryButton(
            label: 'Daftarkan Akun',
            onPressed: () => _register(context, selectedRole),
          ),
          const SizedBox(height: 39),
          GoogleAuthButton(
            action: 'Daftar',
            onPressed: () =>
                _showMessage(context, 'Pendaftaran dengan Google dipilih.'),
          ),
          const SizedBox(height: 12),
          AuthSwitchLink(
            question: 'Sudah punya akun?',
            action: 'Masuk',
            onPressed: () =>
                Navigator.pushReplacementNamed(context, RouteNames.login),
          ),
        ],
      ),
    );
  }
}

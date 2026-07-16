import 'package:flutter/material.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_switch_link.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:panenin/features/auth/presentation/widgets/google_auth_button.dart';
import 'package:panenin/shared/widgets/auth_shell.dart';

class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({super.key});

  void _showMessage(BuildContext context, String message) {
    FocusManager.instance.primaryFocus?.unfocus();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Column(
        children: [
          const AuthBrandHeader(
            title: 'Buat Akun Anda',
            subtitle: 'Kami hadir untuk membantu usahamu',
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
            onPressed: () =>
                _showMessage(context, 'Formulir pendaftaran siap diproses.'),
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

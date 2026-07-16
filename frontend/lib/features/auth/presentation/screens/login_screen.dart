import 'package:flutter/material.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_switch_link.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:panenin/features/auth/presentation/widgets/google_auth_button.dart';
import 'package:panenin/shared/widgets/auth_shell.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
            title: 'Selamat Datang Kembali',
            subtitle: 'Masuk untuk melanjutkan usahamu',
          ),
          const SizedBox(height: 39),
          const AuthTextField(
            label: 'Email',
            hint: 'Masukkan email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 11),
          const AuthTextField(
            label: 'Kata Sandi',
            hint: 'Masukkan sandi',
            obscureText: true,
            textInputAction: TextInputAction.done,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showMessage(
                context,
                'Tautan pemulihan kata sandi akan segera tersedia.',
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2F6B3F),
                padding: const EdgeInsets.only(top: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Lupa kata sandi?',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 18),
          AuthPrimaryButton(
            label: 'Masuk',
            onPressed: () =>
                _showMessage(context, 'Formulir login siap diproses.'),
          ),
          const SizedBox(height: 39),
          GoogleAuthButton(
            action: 'Masuk',
            onPressed: () =>
                _showMessage(context, 'Login dengan Google dipilih.'),
          ),
          const SizedBox(height: 12),
          AuthSwitchLink(
            question: 'Belum punya akun?',
            action: 'Daftar',
            onPressed: () =>
                Navigator.pushReplacementNamed(context, RouteNames.register),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/features/auth/data/auth_service.dart';
import 'package:panenin/features/auth/presentation/auth_feedback.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:panenin/shared/widgets/auth_shell.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    required this.email,
    this.authService,
    this.resendEmailVerification,
    super.key,
  });

  final String email;
  final AuthService? authService;
  final ResendEmailVerification? resendEmailVerification;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  AuthService? _authService;
  bool _isLoading = false;

  Future<void> _resend() async {
    setState(() => _isLoading = true);
    try {
      final resend = widget.resendEmailVerification ?? _resendWithService;
      await resend(widget.email);
      if (!mounted) return;
      _showMessage('Email verifikasi berhasil dikirim ulang.');
    } on Object catch (error) {
      if (!mounted) return;
      _showMessage(
        authErrorMessage(
          error,
          fallback: 'Email verifikasi gagal dikirim ulang',
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendWithService(String email) {
    _authService ??= widget.authService ?? AuthService.create();
    return _authService!.resendEmailVerification(email);
  }

  void _showMessage(String message) {
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
            title: 'Periksa Email Anda',
            subtitle: 'Selesaikan verifikasi untuk mengaktifkan akun',
          ),
          const SizedBox(height: 39),
          Text(
            'Kami telah mengirim tautan verifikasi ke:',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            widget.email,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const Text(
            'Buka tautan tersebut dari perangkat ini. Setelah diverifikasi, '
            'kembali ke aplikasi dan masuk dengan akunmu.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          AuthPrimaryButton(
            label: 'Kirim Ulang Email',
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _resend,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isLoading
                ? null
                : () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    RouteNames.login,
                    (_) => false,
                  ),
            child: const Text('Kembali ke halaman masuk'),
          ),
        ],
      ),
    );
  }
}

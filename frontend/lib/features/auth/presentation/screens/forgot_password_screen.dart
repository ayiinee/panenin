import 'package:flutter/material.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/features/auth/data/auth_service.dart';
import 'package:panenin/features/auth/presentation/auth_feedback.dart';
import 'package:panenin/features/auth/presentation/auth_validators.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:panenin/shared/widgets/auth_shell.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    this.authService,
    this.sendPasswordReset,
    super.key,
  });

  final AuthService? authService;
  final SendPasswordReset? sendPasswordReset;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  AuthService? _authService;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = _emailController.text.trim().toLowerCase();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      final send = widget.sendPasswordReset ?? _sendWithService;
      await send(email);
      if (!mounted) return;
      _showMessage(
        'Jika email terdaftar, tautan pemulihan akan segera dikirim.',
      );
    } on Object catch (error) {
      if (!mounted) return;
      _showMessage(
        authErrorMessage(error, fallback: 'Tautan pemulihan gagal dikirim'),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendWithService(String email) {
    _authService ??= widget.authService ?? AuthService.create();
    return _authService!.sendPasswordReset(email);
  }

  void _showMessage(String message) {
    FocusManager.instance.primaryFocus?.unfocus();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            children: [
              const AuthBrandHeader(
                title: 'Lupa Kata Sandi?',
                subtitle: 'Kami akan mengirim tautan pemulihan ke emailmu',
              ),
              const SizedBox(height: 39),
              AuthTextField(
                label: 'Alamat Email',
                hint: 'Masukkan alamat email',
                controller: _emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                validator: (value) => AuthValidators.email(value ?? ''),
                onSubmitted: (_) => _sendReset(),
              ),
              const SizedBox(height: 27),
              AuthPrimaryButton(
                label: 'Kirim Tautan Pemulihan',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _sendReset,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.pushReplacementNamed(
                        context,
                        RouteNames.login,
                      ),
                child: const Text('Kembali ke halaman masuk'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

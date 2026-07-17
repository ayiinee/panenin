import 'package:flutter/material.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/features/auth/data/auth_service.dart';
import 'package:panenin/features/auth/presentation/auth_feedback.dart';
import 'package:panenin/features/auth/presentation/auth_validators.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:panenin/shared/widgets/auth_shell.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({this.authService, this.updatePassword, super.key});

  final AuthService? authService;
  final UpdatePassword? updatePassword;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  AuthService? _authService;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      final update = widget.updatePassword ?? _updateWithService;
      await update(password);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.login,
        (_) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi berhasil diperbarui. Silakan masuk.'),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      _showMessage(
        authErrorMessage(error, fallback: 'Kata sandi gagal diperbarui'),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateWithService(String password) {
    _authService ??= widget.authService ?? AuthService.create();
    return _authService!.updatePassword(password);
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
                title: 'Buat Kata Sandi Baru',
                subtitle: 'Gunakan minimal 8 karakter',
              ),
              const SizedBox(height: 39),
              AuthTextField(
                label: 'Kata Sandi Baru',
                hint: 'Minimal 8 karakter',
                controller: _passwordController,
                enabled: !_isLoading,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) => AuthValidators.password(value ?? ''),
              ),
              const SizedBox(height: 11),
              AuthTextField(
                label: 'Konfirmasi Kata Sandi',
                hint: 'Ulangi kata sandi baru',
                controller: _confirmationController,
                enabled: !_isLoading,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) => AuthValidators.passwordConfirmation(
                  _passwordController.text,
                  value ?? '',
                ),
                onSubmitted: (_) => _updatePassword(),
              ),
              const SizedBox(height: 27),
              AuthPrimaryButton(
                label: 'Simpan Kata Sandi',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _updatePassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

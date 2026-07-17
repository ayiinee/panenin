import 'package:flutter/material.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_switch_link.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:panenin/features/auth/presentation/widgets/google_auth_button.dart';
import 'package:panenin/shared/widgets/auth_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.onLogin,
    this.onForgotPassword,
    this.onGoogleLogin,
  });
  final Future<void> Function(String email, String password)? onLogin;
  final Future<void> Function(String email)? onForgotPassword;
  final Future<void> Function()? onGoogleLogin;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false, _showPassword = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label wajib diisi.' : null;
  String? _emailValidator(String? value) {
    final required = _required(value, 'Email');
    if (required != null) return required;
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value!.trim())
        ? null
        : 'Masukkan email yang valid.';
  }

  String? _passwordValidator(String? value) {
    final required = _required(value, 'Kata sandi');
    if (required != null) return required;
    return value!.length >= 8 ? null : 'Kata sandi minimal 8 karakter.';
  }

  void _message(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate() || _busy) return;
    setState(() => _busy = true);
    try {
      await (widget.onLogin?.call(_email.text.trim(), _password.text) ??
          Future<void>.value());
      _message('Login berhasil diproses.');
    } catch (_) {
      _message('Login gagal. Periksa data dan koneksi internet.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgot() async {
    if (_emailValidator(_email.text) != null) {
      _message('Masukkan email yang valid terlebih dahulu.');
      return;
    }
    try {
      await (widget.onForgotPassword?.call(_email.text.trim()) ??
          Future<void>.value());
      _message('Tautan pemulihan telah diproses.');
    } catch (_) {
      _message('Pemulihan kata sandi gagal.');
    }
  }

  @override
  Widget build(BuildContext context) => AuthShell(
    child: Form(
      key: _formKey,
      child: Column(
        children: [
          const AuthBrandHeader(
            title: 'Selamat Datang Kembali',
            subtitle: 'Masuk untuk melanjutkan usahamu',
          ),
          const SizedBox(height: 39),
          AuthTextField(
            label: 'Email',
            hint: 'Masukkan email',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            validator: _emailValidator,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
          ),
          const SizedBox(height: 11),
          AuthTextField(
            label: 'Kata Sandi',
            hint: 'Masukkan sandi',
            controller: _password,
            obscureText: !_showPassword,
            validator: _passwordValidator,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _submit(),
            suffixIcon: IconButton(
              tooltip: _showPassword
                  ? 'Sembunyikan kata sandi'
                  : 'Tampilkan kata sandi',
              onPressed: () => setState(() => _showPassword = !_showPassword),
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy ? null : _forgot,
              child: const Text('Lupa kata sandi?'),
            ),
          ),
          const SizedBox(height: 18),
          AuthPrimaryButton(
            label: 'Masuk',
            onPressed: _busy ? () {} : _submit,
            loading: _busy,
          ),
          const SizedBox(height: 39),
          GoogleAuthButton(
            action: 'Masuk',
            onPressed: _busy
                ? () {}
                : () async {
                    try {
                      await (widget.onGoogleLogin?.call() ??
                          Future<void>.value());
                      _message('Login dengan Google berhasil diproses.');
                    } catch (_) {
                      _message('Login dengan Google gagal.');
                    }
                  },
          ),
          const SizedBox(height: 12),
          AuthSwitchLink(
            question: 'Belum punya akun?',
            action: 'Daftar',
            onPressed: _busy
                ? () {}
                : () => Navigator.pushReplacementNamed(
                    context,
                    RouteNames.register,
                  ),
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/features/auth/domain/user_role.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_switch_link.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:panenin/features/auth/presentation/widgets/google_auth_button.dart';
import 'package:panenin/shared/widgets/auth_shell.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({
    super.key,
    this.onRegister,
    this.onGoogleRegister,
  });
  final Future<void> Function(
    String username,
    String email,
    String password,
    UserRole? role,
  )?
  onRegister;
  final Future<void> Function()? onGoogleRegister;
  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController(),
      _email = TextEditingController(),
      _password = TextEditingController(),
      _confirm = TextEditingController();
  bool _busy = false,
      _terms = false,
      _showPassword = false,
      _showConfirm = false;
  UserRole? get _role => switch (ModalRoute.of(context)?.settings.arguments) {
    UserRole role => role,
    _ => null,
  };
  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _required(String? v, String label) =>
      v == null || v.trim().isEmpty ? '$label wajib diisi.' : null;
  String? _emailValidator(String? v) {
    final e = _required(v, 'Email');
    if (e != null) return e;
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v!.trim())
        ? null
        : 'Masukkan email yang valid.';
  }

  String? _passwordValidator(String? v) {
    final e = _required(v, 'Kata sandi');
    if (e != null) return e;
    return v!.length >= 8 ? null : 'Kata sandi minimal 8 karakter.';
  }

  void _message(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate() || !_terms || _busy) {
      if (!_terms) _message('Setujui Syarat & Ketentuan untuk melanjutkan.');
      return;
    }
    setState(() => _busy = true);
    try {
      await (widget.onRegister?.call(
            _username.text.trim(),
            _email.text.trim(),
            _password.text,
            _role,
          ) ??
          Future<void>.value());
      if (mounted) {
        if (_role != null) {
          Navigator.pushReplacementNamed(
            context,
            RouteNames.profile,
            arguments: _role,
          );
        } else {
          _message('Pendaftaran berhasil diproses.');
        }
      }
    } catch (_) {
      _message('Pendaftaran gagal. Periksa data dan koneksi internet.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = _role;
    return AuthShell(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AuthBrandHeader(
              title: 'Buat Akun Anda',
              subtitle: role == null
                  ? 'Kami hadir untuk membantu usahamu'
                  : 'Daftar sebagai ${role.label}',
            ),
            if (role != null)
              TextButton.icon(
                onPressed: _busy ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Ubah peran'),
              ),
            const SizedBox(height: 39),
            AuthTextField(
              label: 'Nama Pengguna',
              hint: 'Masukkan nama pengguna',
              controller: _username,
              validator: (v) {
                final e = _required(v, 'Nama pengguna');
                if (e != null) return e;
                return v!.trim().length >= 3
                    ? null
                    : 'Nama pengguna minimal 3 karakter.';
              },
              autofillHints: const [AutofillHints.username],
            ),
            const SizedBox(height: 11),
            AuthTextField(
              label: 'Alamat Email',
              hint: 'Masukkan alamat email',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: _emailValidator,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 11),
            AuthTextField(
              label: 'Kata Sandi',
              hint: 'Masukkan sandi',
              controller: _password,
              obscureText: !_showPassword,
              validator: _passwordValidator,
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
            const SizedBox(height: 11),
            AuthTextField(
              label: 'Konfirmasi Kata Sandi',
              hint: 'Ulangi kata sandi',
              controller: _confirm,
              obscureText: !_showConfirm,
              validator: (v) => v != _password.text
                  ? 'Kata sandi tidak sama.'
                  : _required(v, 'Konfirmasi kata sandi'),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              suffixIcon: IconButton(
                tooltip: _showConfirm
                    ? 'Sembunyikan kata sandi'
                    : 'Tampilkan kata sandi',
                onPressed: () => setState(() => _showConfirm = !_showConfirm),
                icon: Icon(
                  _showConfirm ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
            CheckboxListTile(
              value: _terms,
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _terms = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Saya menyetujui Syarat & Ketentuan dan Kebijakan Privasi.',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 10),
            AuthPrimaryButton(
              label: 'Daftarkan Akun',
              onPressed: _busy ? () {} : _submit,
              loading: _busy,
            ),
            const SizedBox(height: 39),
            GoogleAuthButton(
              action: 'Daftar',
              onPressed: _busy
                  ? () {}
                  : () async {
                      try {
                        await (widget.onGoogleRegister?.call() ??
                            Future<void>.value());
                        _message(
                          'Pendaftaran dengan Google berhasil diproses.',
                        );
                      } catch (_) {
                        _message('Pendaftaran dengan Google gagal.');
                      }
                    },
            ),
            const SizedBox(height: 12),
            AuthSwitchLink(
              question: 'Sudah punya akun?',
              action: 'Masuk',
              onPressed: _busy
                  ? () {}
                  : () => Navigator.pushReplacementNamed(
                      context,
                      RouteNames.login,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

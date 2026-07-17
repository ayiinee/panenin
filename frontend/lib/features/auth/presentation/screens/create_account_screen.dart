import 'package:flutter/material.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/features/auth/data/auth_service.dart';
import 'package:panenin/features/auth/data/models/authenticated_user.dart';
import 'package:panenin/features/auth/data/models/email_sign_up_result.dart';
import 'package:panenin/features/auth/presentation/auth_feedback.dart';
import 'package:panenin/features/auth/presentation/auth_validators.dart';
import 'package:panenin/features/auth/presentation/screens/select_role_screen.dart';
import 'package:panenin/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_switch_link.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:panenin/features/auth/presentation/widgets/google_auth_button.dart';
import 'package:panenin/shared/widgets/auth_shell.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({
    this.authService,
    this.googleSignIn,
    this.emailSignUp,
    super.key,
  });

  final AuthService? authService;
  final GoogleSignIn? googleSignIn;
  final EmailSignUp? emailSignUp;

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  AuthService? _authService;
  bool _acceptedTerms = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isGoogleLoading = false;
  bool _isEmailLoading = false;

  bool get _isBusy => _isGoogleLoading || _isEmailLoading;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    FocusManager.instance.primaryFocus?.unfocus();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _registerWithEmail() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptedTerms) {
      _showMessage('Setujui Syarat & Ketentuan untuk melanjutkan.');
      return;
    }

    setState(() => _isEmailLoading = true);
    try {
      final result = await (widget.emailSignUp ?? _emailSignUpWithService)(
        name,
        email,
        password,
      );
      if (!mounted) return;
      if (result.requiresEmailVerification) {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => VerifyEmailScreen(email: email),
          ),
        );
        return;
      }
      _openRoleSelection();
    } on Object catch (error) {
      if (!mounted) return;
      _showMessage(
        authErrorMessage(
          error,
          fallback: 'Pendaftaran email gagal. Silakan coba lagi',
        ),
      );
    } finally {
      if (mounted) setState(() => _isEmailLoading = false);
    }
  }

  Future<EmailSignUpResult> _emailSignUpWithService(
    String name,
    String email,
    String password,
  ) {
    _authService ??= widget.authService ?? AuthService.create();
    return _authService!.signUpWithEmail(name, email, password);
  }

  Future<void> _registerWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      await (widget.googleSignIn ?? _googleSignInWithService)();
      if (!mounted) return;
      _openRoleSelection();
    } on Object catch (error) {
      if (!mounted) return;
      _showMessage(
        authErrorMessage(
          error,
          fallback: 'Pendaftaran Google gagal. Silakan coba lagi',
          timeout: 'Pendaftaran Google dibatalkan atau kehabisan waktu.',
        ),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<AuthenticatedUser> _googleSignInWithService() {
    _authService ??= widget.authService ?? AuthService.create();
    return _authService!.signInWithGoogle();
  }

  void _openRoleSelection() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.selectRole,
      (_) => false,
      arguments: RoleSelectionFlow.onboarding,
    );
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
                title: 'Buat Akun Anda',
                subtitle: 'Kami hadir untuk membantu usahamu',
              ),
              const SizedBox(height: 39),
              AuthTextField(
                label: 'Nama Pengguna',
                hint: 'Masukkan nama pengguna',
                controller: _nameController,
                enabled: !_isBusy,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                validator: (value) => AuthValidators.name(value ?? ''),
              ),
              const SizedBox(height: 11),
              AuthTextField(
                label: 'Alamat Email',
                hint: 'Masukkan alamat email',
                controller: _emailController,
                enabled: !_isBusy,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: (value) => AuthValidators.email(value ?? ''),
              ),
              const SizedBox(height: 11),
              AuthTextField(
                label: 'Kata Sandi',
                hint: 'Minimal 8 karakter',
                controller: _passwordController,
                enabled: !_isBusy,
                obscureText: !_showPassword,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) => AuthValidators.password(value ?? ''),
                suffixIcon: IconButton(
                  tooltip: _showPassword
                      ? 'Sembunyikan kata sandi'
                      : 'Tampilkan kata sandi',
                  onPressed: _isBusy
                      ? null
                      : () => setState(() => _showPassword = !_showPassword),
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
              const SizedBox(height: 11),
              AuthTextField(
                label: 'Konfirmasi Kata Sandi',
                hint: 'Ulangi kata sandi',
                controller: _confirmPasswordController,
                enabled: !_isBusy,
                obscureText: !_showConfirmPassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) => AuthValidators.passwordConfirmation(
                  _passwordController.text,
                  value ?? '',
                ),
                onSubmitted: (_) => _registerWithEmail(),
                suffixIcon: IconButton(
                  tooltip: _showConfirmPassword
                      ? 'Sembunyikan kata sandi'
                      : 'Tampilkan kata sandi',
                  onPressed: _isBusy
                      ? null
                      : () => setState(
                          () => _showConfirmPassword = !_showConfirmPassword,
                        ),
                  icon: Icon(
                    _showConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: CheckboxListTile(
                  value: _acceptedTerms,
                  onChanged: _isBusy
                      ? null
                      : (value) =>
                            setState(() => _acceptedTerms = value ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'Saya menyetujui Syarat & Ketentuan dan Kebijakan Privasi.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              AuthPrimaryButton(
                label: 'Daftarkan Akun',
                isLoading: _isEmailLoading,
                onPressed: _isBusy ? null : _registerWithEmail,
              ),
              const SizedBox(height: 39),
              GoogleAuthButton(
                action: 'Daftar',
                isLoading: _isGoogleLoading,
                onPressed: _isBusy ? null : _registerWithGoogle,
              ),
              const SizedBox(height: 12),
              AuthSwitchLink(
                question: 'Sudah punya akun?',
                action: 'Masuk',
                onPressed: _isBusy
                    ? () {}
                    : () => Navigator.pushReplacementNamed(
                        context,
                        RouteNames.login,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/features/auth/data/auth_service.dart';
import 'package:panenin/features/auth/data/models/authenticated_user.dart';
import 'package:panenin/features/auth/data/models/email_sign_up_result.dart';
import 'package:panenin/features/auth/presentation/auth_feedback.dart';
import 'package:panenin/features/auth/presentation/auth_validators.dart';
import 'package:panenin/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_switch_link.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:panenin/features/auth/presentation/widgets/google_auth_button.dart';
import 'package:panenin/features/auth/domain/user_role.dart';
import 'package:panenin/shared/widgets/auth_shell.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({
    this.authService,
    this.googleSignIn,
    this.emailSignUp,
    this.role,
    super.key,
  });

  final AuthService? authService;
  final GoogleSignIn? googleSignIn;
  final EmailSignUp? emailSignUp;
  final UserRole? role;

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  AuthService? _authService;
  bool _isGoogleLoading = false;
  bool _isEmailLoading = false;

  bool get _isBusy => _isGoogleLoading || _isEmailLoading;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
    final validationError =
        AuthValidators.name(name) ??
        AuthValidators.email(email) ??
        AuthValidators.password(password);
    if (validationError != null) {
      _showMessage(validationError);
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
      if (_selectedRole == UserRole.farmer) {
        _openFarmerProfile();
        return;
      }
      final identity = result.user?.name ?? result.user?.email ?? 'pengguna';
      _showMessage('Akun berhasil dibuat sebagai $identity.');
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
      final user = await (widget.googleSignIn ?? _googleSignInWithService)();
      if (!mounted) return;
      if (_selectedRole == UserRole.farmer) {
        _openFarmerProfile();
        return;
      }
      final identity = user.name ?? user.email ?? 'pengguna';
      _showMessage('Pendaftaran berhasil sebagai $identity.');
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

  UserRole? get _selectedRole {
    if (widget.role case final role?) return role;
    return switch (ModalRoute.of(context)?.settings.arguments) {
      UserRole role => role,
      _ => null,
    };
  }

  void _openFarmerProfile() {
    Navigator.pushReplacementNamed(context, RouteNames.profile);
  }

  @override
  Widget build(BuildContext context) {
    final selectedRole = _selectedRole;
    final subtitle = selectedRole == null
        ? 'Kami hadir untuk membantu usahamu'
        : 'Daftar sebagai ${selectedRole.label}';

    return AuthShell(
      child: AutofillGroup(
        child: Column(
          children: [
            AuthBrandHeader(title: 'Buat Akun Anda', subtitle: subtitle),
            const SizedBox(height: 39),
            AuthTextField(
              label: 'Nama Pengguna',
              hint: 'Masukkan Nama Pengguna',
              controller: _nameController,
              enabled: !_isBusy,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
            ),
            const SizedBox(height: 11),
            AuthTextField(
              label: 'Alamat Email',
              hint: 'Masukkan Alamat Email',
              controller: _emailController,
              enabled: !_isBusy,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 11),
            AuthTextField(
              label: 'Kata Sandi',
              hint: 'Minimal 8 karakter',
              controller: _passwordController,
              enabled: !_isBusy,
              obscureText: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onSubmitted: (_) => _registerWithEmail(),
            ),
            const SizedBox(height: 27),
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
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, RouteNames.login),
            ),
          ],
        ),
      ),
    );
  }
}

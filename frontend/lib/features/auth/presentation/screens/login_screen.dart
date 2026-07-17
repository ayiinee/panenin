import 'package:flutter/material.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/features/auth/data/auth_service.dart';
import 'package:panenin/features/auth/data/models/authenticated_user.dart';
import 'package:panenin/features/auth/domain/user_role.dart';
import 'package:panenin/features/auth/presentation/auth_feedback.dart';
import 'package:panenin/features/auth/presentation/auth_validators.dart';
import 'package:panenin/features/auth/presentation/screens/select_role_screen.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_switch_link.dart';
import 'package:panenin/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:panenin/features/auth/presentation/widgets/google_auth_button.dart';
import 'package:panenin/shared/widgets/auth_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    this.authService,
    this.googleSignIn,
    this.emailSignIn,
    super.key,
  });

  final AuthService? authService;
  final GoogleSignIn? googleSignIn;
  final EmailSignIn? emailSignIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  AuthService? _authService;
  bool _isGoogleLoading = false;
  bool _isEmailLoading = false;

  bool get _isBusy => _isGoogleLoading || _isEmailLoading;

  @override
  void dispose() {
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

  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final validationError =
        AuthValidators.email(email) ?? AuthValidators.password(password);
    if (validationError != null) {
      _showMessage(validationError);
      return;
    }

    setState(() => _isEmailLoading = true);
    try {
      final user = await (widget.emailSignIn ?? _emailSignInWithService)(
        email,
        password,
      );
      if (!mounted) return;
      _openAuthenticatedDestination(user);
    } on Object catch (error) {
      if (!mounted) return;
      _showMessage(
        authErrorMessage(
          error,
          fallback: 'Login email gagal. Silakan coba lagi',
        ),
      );
    } finally {
      if (mounted) setState(() => _isEmailLoading = false);
    }
  }

  Future<AuthenticatedUser> _emailSignInWithService(
    String email,
    String password,
  ) {
    _authService ??= widget.authService ?? AuthService.create();
    return _authService!.signInWithEmail(email, password);
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final user = await (widget.googleSignIn ?? _googleSignInWithService)();
      if (!mounted) return;
      _openAuthenticatedDestination(user);
    } on Object catch (error) {
      if (!mounted) return;
      _showMessage(
        authErrorMessage(
          error,
          fallback: 'Login Google gagal. Silakan coba lagi',
          timeout: 'Login Google dibatalkan atau kehabisan waktu.',
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

  void _openAuthenticatedDestination(AuthenticatedUser user) {
    final destination = switch (user.role) {
      UserRole.farmer => RouteNames.homePetani,
      UserRole.buyer => RouteNames.buyerHome,
      null => null,
    };
    if (destination != null) {
      Navigator.pushNamedAndRemoveUntil(context, destination, (_) => false);
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.selectRole,
      (_) => false,
      arguments: RoleSelectionFlow.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: AutofillGroup(
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
              controller: _emailController,
              enabled: !_isBusy,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 11),
            AuthTextField(
              label: 'Kata Sandi',
              hint: 'Masukkan sandi',
              controller: _passwordController,
              enabled: !_isBusy,
              obscureText: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _signInWithEmail(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isBusy
                    ? null
                    : () => Navigator.pushNamed(
                        context,
                        RouteNames.forgotPassword,
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
              isLoading: _isEmailLoading,
              onPressed: _isBusy ? null : _signInWithEmail,
            ),
            const SizedBox(height: 39),
            GoogleAuthButton(
              action: 'Masuk',
              isLoading: _isGoogleLoading,
              onPressed: _isBusy ? null : _signInWithGoogle,
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
      ),
    );
  }
}

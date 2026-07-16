import 'dart:async';

import 'package:flutter/material.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/app/theme/app_theme.dart';
import 'package:panenin/features/auth/presentation/screens/create_account_screen.dart';
import 'package:panenin/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:panenin/features/auth/presentation/screens/login_screen.dart';
import 'package:panenin/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:panenin/features/home/presentation/screens/farmer_home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaneninApp extends StatefulWidget {
  const PaneninApp({this.authEvents, super.key});

  final Stream<AuthState>? authEvents;

  @override
  State<PaneninApp> createState() => _PaneninAppState();
}

class _PaneninAppState extends State<PaneninApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSubscription;
  bool _recoveryRouteOpen = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = widget.authEvents?.listen((state) {
      if (state.event != AuthChangeEvent.passwordRecovery ||
          _recoveryRouteOpen) {
        return;
      }
      _recoveryRouteOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          RouteNames.resetPassword,
          (_) => false,
        );
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Panenin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: RouteNames.register,
      routes: {
        RouteNames.register: (_) => const CreateAccountScreen(),
        RouteNames.login: (_) => const LoginScreen(),
        RouteNames.forgotPassword: (_) => const ForgotPasswordScreen(),
        RouteNames.resetPassword: (_) => const ResetPasswordScreen(),
        RouteNames.home: (_) => const FarmerHomeScreen(),
      },
    );
  }
}

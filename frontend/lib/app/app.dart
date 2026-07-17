import 'dart:async';

import 'package:flutter/material.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/app/shell/farmer_shell.dart';
import 'package:panenin/app/theme/app_theme.dart';
import 'package:panenin/features/auth/data/auth_service.dart';
import 'package:panenin/features/auth/domain/user_role.dart';
import 'package:panenin/features/auth/presentation/screens/create_account_screen.dart';
import 'package:panenin/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:panenin/features/auth/presentation/screens/login_screen.dart';
import 'package:panenin/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:panenin/features/auth/presentation/screens/select_role_screen.dart';
import 'package:panenin/features/home/presentation/screens/buyer_home_screen.dart';
import 'package:panenin/features/marketplace/presentation/screens/product_detail_screen.dart';
import 'package:panenin/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:panenin/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:panenin/features/quick_sell/presentation/screens/quick_sell_camera_screen.dart';
import 'package:panenin/features/stock/domain/stock_item.dart';
import 'package:panenin/features/stock/presentation/screens/stock_form_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, WidgetBuilder> buildAppRoutes() => {
  RouteNames.register: (_) => const CreateAccountScreen(),
  RouteNames.login: (_) => const LoginScreen(),
  RouteNames.forgotPassword: (_) => const ForgotPasswordScreen(),
  RouteNames.resetPassword: (_) => const ResetPasswordScreen(),
  RouteNames.selectRole: (context) => SelectRoleScreen(
    flow: switch (ModalRoute.settingsOf(context)?.arguments) {
      RoleSelectionFlow flow => flow,
      _ => RoleSelectionFlow.onboarding,
    },
    saveSelectedRole: (role) => AuthService.create().saveRole(role),
  ),
  RouteNames.profile: (context) => ProfileSetupScreen(
    role: switch (ModalRoute.of(context)?.settings.arguments) {
      UserRole role => role,
      _ => UserRole.farmer,
    },
    saveRole: (role) => AuthService.create().saveRole(role),
  ),
  RouteNames.buyerHome: (_) => const BuyerHomeScreen(),
  RouteNames.productDetail: ProductDetailScreen.fromRoute,
  RouteNames.homePetani: (_) => const FarmerShell(),
  RouteNames.farmerProfile: (_) => const FarmerShell(initialIndex: 3),
  RouteNames.kelolaPesanan: (_) => const FarmerShell(initialIndex: 2),
  RouteNames.detailPesanan: (context) => OrderDetailScreen(
    order: ModalRoute.settingsOf(context)!.arguments! as OrderDetailData,
  ),
  RouteNames.stokSaya: (context) => FarmerShell(
    initialIndex: 1,
    initialStockItem: ModalRoute.settingsOf(context)!.arguments as StockItem?,
  ),
  RouteNames.fotoJualCepat: (_) => const QuickSellCameraScreen(),
  RouteNames.formStok: (context) => StockFormScreen(
    capturedPhotoPath: ModalRoute.settingsOf(context)!.arguments as String?,
  ),
};

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
    _authSubscription = widget.authEvents?.listen(
      (state) {
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
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Supabase auth stream error: $error');
      },
    );
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
      routes: buildAppRoutes(),
    );
  }
}

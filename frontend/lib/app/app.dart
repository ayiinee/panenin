import 'dart:async';

import 'package:flutter/material.dart';
import 'package:panenin/app/app_repositories.dart';
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
import 'package:panenin/features/marketplace/presentation/screens/negotiation_chat_screen.dart';
import 'package:panenin/features/marketplace/presentation/screens/product_detail_screen.dart';
import 'package:panenin/features/marketplace/presentation/screens/recurring_supply_screen.dart';
import 'package:panenin/features/messages/presentation/screens/buyer_messages_screen.dart';
import 'package:panenin/features/orders/presentation/screens/buyer_orders_screen.dart';
import 'package:panenin/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:panenin/features/profile/presentation/screens/buyer_profile_screen.dart';
import 'package:panenin/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:panenin/features/quick_sell/presentation/screens/quick_sell_camera_screen.dart';
import 'package:panenin/features/stock/domain/stock_item.dart';
import 'package:panenin/features/stock/presentation/screens/stock_form_screen.dart';
import 'package:panenin/features/whatsapp/presentation/whatsapp_link_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, WidgetBuilder> buildAppRoutes({AppRepositories? repositories}) => {
  RouteNames.register: (_) => const CreateAccountScreen(),
  RouteNames.login: (_) => const LoginScreen(),
  RouteNames.forgotPassword: (_) => const ForgotPasswordScreen(),
  RouteNames.resetPassword: (_) => const ResetPasswordScreen(),
  RouteNames.selectRole: (context) => SelectRoleScreen(
    flow: switch (ModalRoute.settingsOf(context)?.arguments) {
      RoleSelectionFlow flow => flow,
      _ => RoleSelectionFlow.skipAuth,
    },
    saveSelectedRole: (role) => AuthService.create().saveRole(role),
  ),
  RouteNames.profile: (context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    return ProfileSetupScreen(
      repository: repositories?.profile,
      role: switch (arguments) {
        ProfileSetupRouteArguments arguments => arguments.role,
        UserRole role => role,
        _ => UserRole.farmer,
      },
      saveRole: arguments is ProfileSetupRouteArguments
          ? null
          : (role) => AuthService.create().saveRole(role),
    );
  },
  RouteNames.buyerHome: (_) =>
      BuyerHomeScreen(repository: repositories?.buyerHome),
  RouteNames.buyerMessages: (_) => const BuyerMessagesScreen(),
  RouteNames.buyerOrders: (_) => const BuyerOrdersScreen(),
  RouteNames.buyerProfile: (_) => const BuyerProfileScreen(),
  RouteNames.productDetail: ProductDetailScreen.fromRoute,
  RouteNames.negotiationChat: NegotiationChatScreen.fromRoute,
  RouteNames.recurringSupply: RecurringSupplyScreen.fromRoute,
  RouteNames.homePetani: (_) => FarmerShell(repositories: repositories),
  RouteNames.farmerProfile: (_) =>
      FarmerShell(initialIndex: 3, repositories: repositories),
  RouteNames.kelolaPesanan: (_) =>
      FarmerShell(initialIndex: 2, repositories: repositories),
  RouteNames.detailPesanan: (context) => OrderDetailScreen(
    order: ModalRoute.settingsOf(context)!.arguments! as OrderDetailData,
    enableLocalTransitions: repositories == null,
  ),
  RouteNames.whatsapp: (_) =>
      WhatsAppLinkScreen(repository: repositories?.whatsapp),
  RouteNames.stokSaya: (context) => FarmerShell(
    initialIndex: 1,
    initialStockItem: ModalRoute.settingsOf(context)!.arguments as StockItem?,
    repositories: repositories,
  ),
  RouteNames.fotoJualCepat: (_) => const QuickSellCameraScreen(),
  RouteNames.formStok: (context) => StockFormScreen(
    capturedPhotoPath: ModalRoute.settingsOf(context)!.arguments as String?,
  ),
};

class PaneninApp extends StatefulWidget {
  const PaneninApp({this.authEvents, this.repositories, super.key});

  final Stream<AuthState>? authEvents;
  final AppRepositories? repositories;

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
      initialRoute: RouteNames.selectRole,
      routes: buildAppRoutes(repositories: widget.repositories),
    );
  }
}

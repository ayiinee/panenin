import 'package:flutter/material.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/app/theme/app_theme.dart';
import 'package:panenin/features/auth/domain/user_role.dart';
import 'package:panenin/features/auth/presentation/screens/create_account_screen.dart';
import 'package:panenin/features/auth/presentation/screens/login_screen.dart';
import 'package:panenin/features/auth/presentation/screens/select_role_screen.dart';
import 'package:panenin/features/home/presentation/screens/buyer_home_screen.dart';
import 'package:panenin/features/marketplace/presentation/screens/product_detail_screen.dart';
import 'package:panenin/features/marketplace/presentation/screens/negotiation_chat_screen.dart';
import 'package:panenin/features/marketplace/presentation/screens/recurring_supply_screen.dart';
import 'package:panenin/features/orders/presentation/screens/buyer_orders_screen.dart';
import 'package:panenin/features/profile/presentation/screens/profile_setup_screen.dart';

class PaneninApp extends StatelessWidget {
  const PaneninApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Panenin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: RouteNames.selectRole,
      routes: {
        RouteNames.selectRole: (_) => const SelectRoleScreen(),
        RouteNames.register: (_) => const CreateAccountScreen(),
        RouteNames.login: (_) => const LoginScreen(),
        RouteNames.profile: (context) => ProfileSetupScreen(
          role: switch (ModalRoute.of(context)?.settings.arguments) {
            UserRole role => role,
            _ => UserRole.farmer,
          },
        ),
        RouteNames.buyerHome: (_) => const BuyerHomeScreen(),
        RouteNames.buyerOrders: (_) => const BuyerOrdersScreen(),
        RouteNames.productDetail: ProductDetailScreen.fromRoute,
        RouteNames.negotiationChat: NegotiationChatScreen.fromRoute,
        RouteNames.recurringSupply: RecurringSupplyScreen.fromRoute,
      },
    );
  }
}

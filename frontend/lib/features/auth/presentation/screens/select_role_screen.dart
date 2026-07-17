import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/core/constants/app_assets.dart';
import 'package:panenin/core/constants/app_colors.dart';
import 'package:panenin/features/auth/domain/user_role.dart';

/// Lets a new user choose whether they sell or buy produce.
class SelectRoleScreen extends StatelessWidget {
  const SelectRoleScreen({super.key});

  void _continueAs(BuildContext context, UserRole role) {
    // Keep this screen in the stack so a user can review or change their role.
    Navigator.pushNamed(context, RouteNames.register, arguments: role);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        systemNavigationBarColor: AppColors.pageBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          bottom: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(constraints.maxWidth, 428.0);
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: width),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: _RoleContent(
                      onFarmerPressed: () =>
                          _continueAs(context, UserRole.farmer),
                      onBuyerPressed: () =>
                          _continueAs(context, UserRole.buyer),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RoleContent extends StatelessWidget {
  const _RoleContent({
    required this.onFarmerPressed,
    required this.onBuyerPressed,
  });

  final VoidCallback onFarmerPressed;
  final VoidCallback onBuyerPressed;

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.sizeOf(context).width < 390 ? 16.0 : 19.0;
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 205,
          child: Image.asset(
            AppAssets.authBackground,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            excludeFromSemantics: true,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 106),
          padding: EdgeInsets.fromLTRB(horizontal, 34, horizontal, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(29)),
            boxShadow: const [
              BoxShadow(
                color: AppColors.surfaceShadow,
                offset: Offset(0, -3),
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PaneninBrand(),
              const SizedBox(height: 8),
              const Text.rich(
                TextSpan(
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                  children: [
                    TextSpan(
                      text: 'Halo!\n',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    TextSpan(text: 'Selamat Datang\ndi Panenin!'),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Silakan pilih peran yang paling menggambarkan dirimu.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              _RoleCard(
                key: const ValueKey('farmer-role-card'),
                title: 'Saya ingin menjual\nhasil panen',
                description:
                    'Tawarkan hasil panen dari kelompok tani kepada UMKM.',
                action: 'Jual Hasil Panen',
                image: AppAssets.roleFarmer,
                buttonColor: AppColors.primary,
                buttonForeground: Colors.white,
                buttonKey: const ValueKey('farmer-role-button'),
                semanticLabel:
                    'Pilih peran petani. Menjual hasil panen kepada UMKM.',
                onPressed: onFarmerPressed,
              ),
              const SizedBox(height: 18),
              _RoleCard(
                key: const ValueKey('buyer-role-card'),
                title: 'Saya ingin membeli\nhasil panen',
                description:
                    'Cari supplier terpercaya dan dapatkan pasokan bahan baku segar.',
                action: 'Beli Hasil Panen',
                image: AppAssets.roleBuyer,
                buttonColor: AppColors.accent,
                buttonForeground: AppColors.textPrimary,
                buttonKey: const ValueKey('buyer-role-button'),
                semanticLabel:
                    'Pilih peran UMKM. Membeli hasil panen dari supplier.',
                onPressed: onBuyerPressed,
              ),
            ],
          ),
        ),
        Positioned(
          top: 18,
          right: -110,
          child: ExcludeSemantics(
            child: Image.asset(
              AppAssets.roleHeroBasket,
              width: 270,
              height: 235,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaneninBrand extends StatelessWidget {
  const _PaneninBrand();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 112,
    height: 54,
    child: Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          width: 54,
          height: 54,
          child: ExcludeSemantics(child: Image.asset(AppAssets.logo)),
        ),
        const Positioned(
          left: 39,
          top: 28,
          child: Text(
            'anenin',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      ],
    ),
  );
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    super.key,
    required this.title,
    required this.description,
    required this.action,
    required this.image,
    required this.buttonColor,
    required this.buttonForeground,
    required this.buttonKey,
    required this.semanticLabel,
    required this.onPressed,
  });

  final String title, description, action, image, semanticLabel;
  final Color buttonColor, buttonForeground;
  final Key buttonKey;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final cardHeight = 205.0 + math.max(0, textScale - 1) * 150;
    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label: semanticLabel,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: cardHeight,
            child: Row(
              children: [
                Expanded(
                  flex: 52,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            description,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 44,
                          child: Material(
                            key: buttonKey,
                            color: buttonColor,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      action,
                                      style: TextStyle(
                                        color: buttonForeground,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 18,
                                    color: buttonForeground,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 48,
                  child: ExcludeSemantics(
                    child: Image.asset(
                      image,
                      fit: BoxFit.cover,
                      height: double.infinity,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

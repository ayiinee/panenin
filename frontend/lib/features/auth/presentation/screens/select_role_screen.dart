import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/core/constants/app_assets.dart';
import 'package:panenin/core/constants/app_colors.dart';
import 'package:panenin/features/auth/domain/user_role.dart';

enum RoleSelectionFlow { onboarding, login, skipAuth }

class ProfileSetupRouteArguments {
  const ProfileSetupRouteArguments({required this.role});

  final UserRole role;
}

typedef SaveSelectedRole = Future<void> Function(UserRole role);

/// Lets a user choose whether they sell or buy produce.
class SelectRoleScreen extends StatefulWidget {
  const SelectRoleScreen({
    this.flow = RoleSelectionFlow.onboarding,
    this.saveSelectedRole,
    super.key,
  });

  final RoleSelectionFlow flow;
  final SaveSelectedRole? saveSelectedRole;

  @override
  State<SelectRoleScreen> createState() => _SelectRoleScreenState();
}

class _SelectRoleScreenState extends State<SelectRoleScreen> {
  static const _designWidth = 428.0;
  static const _designHeight = 926.0;

  Future<void> _continueAs(BuildContext context, UserRole role) async {
    if (widget.flow == RoleSelectionFlow.login) {
      try {
        await widget.saveSelectedRole?.call(role);
      } on Object {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Peran gagal disimpan. Silakan coba lagi.'),
          ),
        );
        return;
      }
      if (!context.mounted) return;
      final destination = role == UserRole.farmer
          ? RouteNames.homePetani
          : RouteNames.buyerHome;
      Navigator.pushNamedAndRemoveUntil(context, destination, (_) => false);
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      RouteNames.profile,
      arguments: widget.flow == RoleSelectionFlow.skipAuth
          ? ProfileSetupRouteArguments(role: role)
          : role,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        systemNavigationBarColor: const Color(0xFFF5F7EE),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7EE),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final pageWidth = math.min(constraints.maxWidth, _designWidth);
            final horizontalPadding = pageWidth < 390 ? 16.0 : 19.0;
            final cardWidth = pageWidth - (horizontalPadding * 2);
            final compact = cardWidth < 360;
            final cardHeight = compact ? 250.0 : 205.0;
            final secondCardTop = 453.0 + cardHeight + 18.0;
            final pageHeight = math.max(
              _designHeight,
              secondCardTop + cardHeight + 85.0,
            );

            return SingleChildScrollView(
              child: SizedBox(
                width: constraints.maxWidth,
                height: math.max(constraints.maxHeight, pageHeight),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: pageWidth,
                    height: pageHeight,
                    child: _RoleSelectionCanvas(
                      pageWidth: pageWidth,
                      pageHeight: pageHeight,
                      horizontalPadding: horizontalPadding,
                      cardWidth: cardWidth,
                      cardHeight: cardHeight,
                      secondCardTop: secondCardTop,
                      compact: compact,
                      onFarmerPressed: () =>
                          _continueAs(context, UserRole.farmer),
                      onBuyerPressed: () =>
                          _continueAs(context, UserRole.buyer),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoleSelectionCanvas extends StatelessWidget {
  const _RoleSelectionCanvas({
    required this.pageWidth,
    required this.pageHeight,
    required this.horizontalPadding,
    required this.cardWidth,
    required this.cardHeight,
    required this.secondCardTop,
    required this.compact,
    required this.onFarmerPressed,
    required this.onBuyerPressed,
  });

  final double pageWidth;
  final double pageHeight;
  final double horizontalPadding;
  final double cardWidth;
  final double cardHeight;
  final double secondCardTop;
  final bool compact;
  final VoidCallback onFarmerPressed;
  final VoidCallback onBuyerPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          top: 42,
          child: Image.asset(
            AppAssets.authBackground,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        Positioned(
          top: 148,
          left: 0,
          right: 0,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(29),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  offset: Offset(0, -3),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SizedBox(height: pageHeight - 148),
          ),
        ),
        const Positioned(
          top: 209,
          right: -57,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xBFE3F0E4),
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(dimension: 212),
          ),
        ),
        const Positioned(
          top: 166,
          right: -137,
          width: 298,
          height: 258,
          child: _HeroBasket(),
        ),
        Positioned(
          top: 182,
          left: horizontalPadding,
          child: const _PaneninBrand(),
        ),
        Positioned(
          top: 244,
          left: horizontalPadding,
          right: horizontalPadding,
          child: const Text.rich(
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
        ),
        Positioned(
          top: 375,
          left: horizontalPadding,
          width: math.min(266, pageWidth - (horizontalPadding * 2)),
          child: const Text(
            'Silahkan Pilih Peran Berikut yang Paling '
            'Menggambarkan Dirimu',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ),
        Positioned(
          top: 453,
          left: horizontalPadding,
          child: _RoleCard(
            key: const ValueKey('farmer-role-card'),
            width: cardWidth,
            height: cardHeight,
            compact: compact,
            title: 'Saya ingin menjual\nhasil panen',
            description:
                'Tawarkan hasil panen dari\nkelompok tani Anda kepada\nUMKM.',
            action: 'Jual Hasil Panen',
            image: AppAssets.roleFarmer,
            buttonColor: AppColors.primary,
            buttonForeground: Colors.white,
            buttonKey: const ValueKey('farmer-role-button'),
            onPressed: onFarmerPressed,
          ),
        ),
        Positioned(
          top: secondCardTop,
          left: horizontalPadding,
          child: _RoleCard(
            key: const ValueKey('buyer-role-card'),
            width: cardWidth,
            height: cardHeight,
            compact: compact,
            title: 'Saya ingin membeli\nhasil panen',
            description:
                'Cari supplier terpercaya dan\ndapatkan pasokan bahan\nbaku segar dan rutin.',
            action: 'Beli Hasil Panen',
            image: AppAssets.roleBuyer,
            buttonColor: AppColors.accent,
            buttonForeground: AppColors.textPrimary,
            buttonKey: const ValueKey('buyer-role-button'),
            onPressed: onBuyerPressed,
          ),
        ),
      ],
    );
  }
}

class _HeroBasket extends StatelessWidget {
  const _HeroBasket();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.122,
      child: Image.asset(AppAssets.roleHeroBasket, fit: BoxFit.contain),
    );
  }
}

class _PaneninBrand extends StatelessWidget {
  const _PaneninBrand();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 54,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: 54,
            height: 54,
            child: Image.asset(AppAssets.logo),
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
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    super.key,
    required this.width,
    required this.height,
    required this.compact,
    required this.title,
    required this.description,
    required this.action,
    required this.image,
    required this.buttonColor,
    required this.buttonForeground,
    required this.buttonKey,
    required this.onPressed,
  });

  final double width;
  final double height;
  final bool compact;
  final String title;
  final String description;
  final String action;
  final String image;
  final Color buttonColor;
  final Color buttonForeground;
  final Key buttonKey;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: Colors.white,
        child: SizedBox(
          width: width,
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double imageWidth = compact
                  ? constraints.maxWidth * 0.47
                  : math.min(203.0, constraints.maxWidth * 0.52);
              final contentWidth = constraints.maxWidth - imageWidth;
              final contentPadding = compact ? 12.0 : 15.0;
              final double buttonWidth = math.min(
                155.0,
                contentWidth - (contentPadding * 2),
              );

              return Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    width: imageWidth,
                    height: constraints.maxHeight,
                    child: Image.asset(image, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: compact ? 18 : 20,
                    left: 0,
                    width: contentWidth,
                    bottom: 6,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: contentPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: compact ? 3 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                description,
                                maxLines: compact ? 5 : 4,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                  height: 20 / 14,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: buttonWidth,
                            height: 44,
                            child: Semantics(
                              button: true,
                              excludeSemantics: true,
                              label: action,
                              child: Material(
                                key: buttonKey,
                                color: buttonColor,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: onPressed,
                                  borderRadius: BorderRadius.circular(12),
                                  splashColor: buttonForeground.withValues(
                                    alpha: 0.18,
                                  ),
                                  highlightColor: buttonForeground.withValues(
                                    alpha: 0.10,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: compact ? 10 : 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: FittedBox(
                                            alignment: Alignment.centerLeft,
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              action,
                                              style: TextStyle(
                                                color: buttonForeground,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                height: 16 / 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
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
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

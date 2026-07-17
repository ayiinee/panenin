import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/core/constants/app_assets.dart';
import 'package:panenin/core/constants/app_colors.dart';
import 'package:panenin/features/auth/domain/user_role.dart';

enum RoleSelectionFlow { onboarding, login }

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
      arguments: role,
    );
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
        backgroundColor: const Color(0xFFF5F7EE),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final pageWidth = math.min(constraints.maxWidth, _designWidth);
            final horizontalPadding = pageWidth < 390 ? 16.0 : 19.0;
            final cardWidth = pageWidth - (horizontalPadding * 2);
            final referenceLayout = constraints.maxHeight >= 860;
            final shortViewport = constraints.maxHeight < 760;
            final narrowViewport = cardWidth < 360;
            final cardHeight = referenceLayout
                ? 185.0
                : shortViewport
                ? 148.0
                : 164.0;
            final firstCardTop = referenceLayout
                ? 453.0
                : math.min(
                    370.0,
                    math.max(276.0, constraints.maxHeight * 0.46),
                  );
            final cardGap = shortViewport ? 14.0 : 18.0;
            final secondCardTop = firstCardTop + cardHeight + cardGap;
            final contentBottom = secondCardTop + cardHeight;
            final pageHeight = math.max(
              constraints.maxHeight,
              contentBottom + 14.0,
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
                      firstCardTop: firstCardTop,
                      secondCardTop: secondCardTop,
                      referenceLayout: referenceLayout,
                      shortViewport: shortViewport,
                      narrowViewport: narrowViewport,
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
    required this.firstCardTop,
    required this.secondCardTop,
    required this.referenceLayout,
    required this.shortViewport,
    required this.narrowViewport,
    required this.onFarmerPressed,
    required this.onBuyerPressed,
  });

  final double pageWidth;
  final double pageHeight;
  final double horizontalPadding;
  final double cardWidth;
  final double cardHeight;
  final double firstCardTop;
  final double secondCardTop;
  final bool referenceLayout;
  final bool shortViewport;
  final bool narrowViewport;
  final VoidCallback onFarmerPressed;
  final VoidCallback onBuyerPressed;

  @override
  Widget build(BuildContext context) {
    final panelTop = referenceLayout
        ? 148.0
        : (firstCardTop - 225).clamp(64.0, 145.0);
    final titleTop = referenceLayout
        ? 244.0
        : firstCardTop - (shortViewport ? 145 : 160);
    final descriptionTop = referenceLayout
        ? 375.0
        : firstCardTop - (shortViewport ? 55 : 60);

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          top: referenceLayout ? 42 : 24,
          child: Image.asset(
            AppAssets.authBackground,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        Positioned(
          top: panelTop,
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
            child: SizedBox(height: pageHeight - panelTop),
          ),
        ),
        Positioned(
          top: referenceLayout ? 209 : panelTop + 20,
          right: referenceLayout ? -57 : -44,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xBFE3F0E4),
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: referenceLayout
                  ? 212
                  : shortViewport
                  ? 148
                  : 170,
            ),
          ),
        ),
        Positioned(
          top: referenceLayout ? 166 : panelTop + 4,
          right: referenceLayout
              ? -137
              : shortViewport
              ? -82
              : -92,
          width: referenceLayout
              ? 298
              : shortViewport
              ? 205
              : 224,
          height: referenceLayout
              ? 258
              : shortViewport
              ? 168
              : 184,
          child: const _HeroBasket(),
        ),
        Positioned(
          top: titleTop,
          left: horizontalPadding,
          right: horizontalPadding,
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                color: AppColors.primary,
                fontSize: referenceLayout
                    ? 32
                    : shortViewport
                    ? 24
                    : 27,
                fontWeight: FontWeight.w600,
                height: referenceLayout ? 1.25 : 1.15,
              ),
              children: const [
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
          top: descriptionTop,
          left: horizontalPadding,
          width: math.min(250, pageWidth - (horizontalPadding * 2)),
          child: const Text(
            'Silahkan Pilih Peran Berikut yang Paling '
            'Menggambarkan Dirimu',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
        Positioned(
          top: firstCardTop,
          left: horizontalPadding,
          child: _RoleCard(
            key: const ValueKey('farmer-role-card'),
            width: cardWidth,
            height: cardHeight,
            compact: narrowViewport,
            title: 'Saya ingin menjual\nhasil panen',
            description:
                'Tawarkan hasil panen dari\nkelompok tani Anda kepada\nUMKM.',
            action: 'Jual Hasil Panen',
            image: AppAssets.roleFarmer,
            imageKey: const ValueKey('farmer-role-image'),
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
            compact: narrowViewport,
            title: 'Saya ingin membeli\nhasil panen',
            description:
                'Cari supplier terpercaya dan\ndapatkan pasokan bahan\nbaku segar dan rutin.',
            action: 'Beli Hasil Panen',
            image: AppAssets.roleBuyer,
            imageKey: const ValueKey('buyer-role-image'),
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
    required this.imageKey,
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
  final Key imageKey;
  final Color buttonColor;
  final Color buttonForeground;
  final Key buttonKey;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final spacious = constraints.maxHeight >= 180;
          final contentWidth = constraints.maxWidth * (compact ? 0.57 : 0.49);
          final imageWidth = constraints.maxWidth * (compact ? 0.53 : 0.52);
          final contentPadding = spacious
              ? 15.0
              : compact
              ? 12.0
              : 14.0;
          final buttonWidth = math.min(
            155.0,
            contentWidth - (contentPadding * 2),
          );

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x10000000),
                        offset: Offset(0, 3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: spacious
                    ? -28
                    : compact
                    ? -18
                    : -22,
                right: 0,
                width: imageWidth,
                height: constraints.maxHeight + (spacious ? 28 : 22),
                child: Image.asset(
                  image,
                  key: imageKey,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomRight,
                ),
              ),
              Positioned(
                top: spacious
                    ? 30
                    : compact
                    ? 8
                    : 14,
                left: 0,
                width: contentWidth,
                bottom: spacious
                    ? 12
                    : compact
                    ? 8
                    : 10,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: contentPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: spacious ? 6 : 2),
                      Expanded(
                        child: Text(
                          description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                            height: 1.25,
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
                                  horizontal: compact ? 8 : 12,
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
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 17,
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
    );
  }
}

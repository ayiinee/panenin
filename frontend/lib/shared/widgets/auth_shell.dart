import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panenin/core/constants/app_assets.dart';
import 'package:panenin/core/constants/app_colors.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({required this.child, super.key});

  static const _designWidth = 428.0;
  static const _designBodyHeight = 884.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final pageWidth = math.min(constraints.maxWidth, _designWidth);
            final horizontalMargin = (constraints.maxWidth - pageWidth) / 2;
            final contentPadding = pageWidth < 390 ? 24.0 : 30.0;
            final pageHeight = math.max(
              constraints.maxHeight,
              _designBodyHeight,
            );

            return ColoredBox(
              color: Colors.white,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: pageHeight,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: horizontalMargin,
                        width: pageWidth,
                        child: Image.asset(
                          AppAssets.authBackground,
                          fit: BoxFit.cover,
                          alignment: Alignment.topLeft,
                        ),
                      ),
                      Positioned(
                        top: 106,
                        bottom: 0,
                        left: horizontalMargin,
                        width: pageWidth,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(29),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x40000000),
                                offset: Offset(0, -3),
                                blurRadius: 50,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 147,
                        left: horizontalMargin + contentPadding,
                        width: pageWidth - (contentPadding * 2),
                        child: child,
                      ),
                    ],
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

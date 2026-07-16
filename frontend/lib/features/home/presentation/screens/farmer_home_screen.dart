import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panenin/app/shell/panenin_bottom_navigation.dart';
import 'package:panenin/app/theme/app_colors.dart';
import 'package:panenin/features/home/presentation/widgets/active_orders_section.dart';
import 'package:panenin/features/home/presentation/widgets/demand_request_card.dart';
import 'package:panenin/features/home/presentation/widgets/farmer_home_header.dart';
import 'package:panenin/shared/widgets/app_notification_card.dart';

enum _DemandAction { accepted, rejected }

class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
  Timer? _notificationTimer;
  _DemandAction? _feedback;
  bool _hasDemand = true;
  bool _showNotification = false;

  void _completeDemand(_DemandAction action) {
    if (!_hasDemand) return;

    _notificationTimer?.cancel();
    setState(() {
      _hasDemand = false;
      _showNotification = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _feedback = action;
        _showNotification = true;
      });

      _notificationTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showNotification = false);
      });
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        extendBody: true,
        bottomNavigationBar: const PaneninBottomNavigation(),
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 92),
                child: Column(
                  children: [
                    const FarmerHomeHeader(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const _SectionHeading(),
                          if (_hasDemand)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 6,
                                bottom: 12,
                              ),
                              child: DemandRequestCard(
                                onAccept: () =>
                                    _completeDemand(_DemandAction.accepted),
                                onReject: () =>
                                    _completeDemand(_DemandAction.rejected),
                                onNegotiate: () {},
                              ),
                            ),
                          const ActiveOrdersSection(),
                          SizedBox(
                            height: MediaQuery.paddingOf(context).bottom + 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                minimum: const EdgeInsets.only(top: 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: constraints.maxWidth >= 768
                            ? Alignment.topRight
                            : Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 320),
                            reverseDuration: const Duration(milliseconds: 240),
                            transitionBuilder: (child, animation) {
                              final curved = CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                                reverseCurve: Curves.easeInCubic,
                              );
                              return FadeTransition(
                                opacity: curved,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, -1.2),
                                    end: Offset.zero,
                                  ).animate(curved),
                                  child: child,
                                ),
                              );
                            },
                            child: _showNotification && _feedback != null
                                ? _DemandNotification(
                                    key: ValueKey(_feedback),
                                    action: _feedback!,
                                  )
                                : const SizedBox(
                                    key: ValueKey('hidden-notification'),
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemandNotification extends StatelessWidget {
  const _DemandNotification({required this.action, super.key});

  final _DemandAction action;

  @override
  Widget build(BuildContext context) {
    return switch (action) {
      _DemandAction.accepted => const AppNotificationCard(
        title: 'Berhasil!',
        message: 'Pesanan berhasil diterima.',
        type: AppNotificationType.success,
      ),
      _DemandAction.rejected => const AppNotificationCard(
        title: 'Ditolak!',
        message: 'Pesanan berhasil ditolak.',
        type: AppNotificationType.error,
      ),
    };
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Permintaan Baru',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              height: 26 / 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            foregroundColor: AppColors.textPrimary,
            textStyle: const TextStyle(fontSize: 14),
          ),
          child: const Text('Lihat Semua'),
        ),
      ],
    );
  }
}

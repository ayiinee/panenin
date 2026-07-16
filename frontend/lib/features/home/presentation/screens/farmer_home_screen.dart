import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panenin/app/shell/panenin_bottom_navigation.dart';
import 'package:panenin/app/theme/app_colors.dart';
import 'package:panenin/features/home/presentation/widgets/active_orders_section.dart';
import 'package:panenin/features/home/presentation/widgets/demand_request_card.dart';
import 'package:panenin/features/home/presentation/widgets/farmer_home_header.dart';
import 'package:panenin/features/orders/presentation/screens/manage_orders_screen.dart';
import 'package:panenin/features/stock/presentation/screens/stock_screen.dart';
import 'package:panenin/shared/widgets/app_notification_card.dart';

enum _DemandAction { accepted, rejected }

class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
  static const _demands = [
    (
      id: 'rina',
      buyerName: 'Mbak Rina',
      businessName: 'Mango Sticky Rice Sigura-Gura',
      requestText: 'Ingin langganan Cabai Merah 10 kg tiap Selasa & Jumat...',
      avatarPath: 'assets/images/home/buyer_avatar.png',
    ),
    (
      id: 'syaiful',
      buyerName: 'Pak Syaiful',
      businessName: 'Warung Barokah Dinoyo',
      requestText:
          'Butuh Kacang Panjang 15 kg setiap Senin & Kamis untuk stok warung...',
      avatarPath: 'assets/images/home/syaiful_avatar.png',
    ),
  ];

  Timer? _notificationTimer;
  _DemandAction? _feedback;
  final _activeDemandIds = {'rina', 'syaiful'};
  bool _showNotification = false;

  void _openOrders() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ManageOrdersScreen()));
  }

  void _openStock() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const StockScreen()));
  }

  void _completeDemand(String id, _DemandAction action) {
    if (!_activeDemandIds.contains(id)) return;

    _notificationTimer?.cancel();
    setState(() {
      _activeDemandIds.remove(id);
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

  Future<void> _confirmReject(String id, String buyerName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _RejectDemandDialog(buyerName: buyerName),
    );

    if (confirmed == true && mounted) {
      _completeDemand(id, _DemandAction.rejected);
    }
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
        bottomNavigationBar: PaneninBottomNavigation(
          onDestinationSelected: (index) {
            if (index == 1) _openStock();
            if (index == 2) _openOrders();
          },
        ),
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
                          for (final demand in _demands)
                            if (_activeDemandIds.contains(demand.id))
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 6,
                                  bottom: 12,
                                ),
                                child: DemandRequestCard(
                                  key: ValueKey('demand-${demand.id}'),
                                  buyerName: demand.buyerName,
                                  businessName: demand.businessName,
                                  requestText: demand.requestText,
                                  avatarPath: demand.avatarPath,
                                  onAccept: () => _completeDemand(
                                    demand.id,
                                    _DemandAction.accepted,
                                  ),
                                  onReject: () => _confirmReject(
                                    demand.id,
                                    demand.buyerName,
                                  ),
                                  onNegotiate: () {},
                                ),
                              ),
                          ActiveOrdersSection(onViewAll: _openOrders),
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

class _RejectDemandDialog extends StatelessWidget {
  const _RejectDemandDialog({required this.buyerName});

  final String buyerName;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Yakin menolak permintaan?',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Permintaan kontrak tani dari $buyerName akan ditolak.',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.surfaceSubtle,
                          foregroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Batalkan'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Lanjutkan'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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

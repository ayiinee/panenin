import 'package:flutter/material.dart';
import 'package:panenin/app/theme/app_colors.dart';

class FarmerHomeHeader extends StatelessWidget {
  const FarmerHomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 274,
      child: Stack(
        children: [
          Container(
            height: 203,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryDark,
                  AppColors.primaryLight,
                  AppColors.primaryDark,
                ],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
            ),
            child: const _Greeting(),
          ),
          const Positioned(
            top: 92,
            left: 20,
            right: 20,
            child: _BalanceSummaryCard(),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Panenin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'Selamat Datang',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                key: const ValueKey('home-guest-pill'),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      key: ValueKey('home-guest-avatar'),
                      radius: 12,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person_rounded,
                        size: 17,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Text(
                        'Alvin!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: 'Buka pesan',
          child: IconButton(
            key: const ValueKey('home-message-button'),
            onPressed: () {},
            padding: EdgeInsets.zero,
            alignment: Alignment.topRight,
            icon: Transform.translate(
              offset: const Offset(0, -4),
              child: const Icon(
                Icons.chat_outlined,
                key: ValueKey('home-message-icon'),
                color: Colors.white,
              ),
            ),
            iconSize: 24,
            tooltip: 'Pesan',
          ),
        ),
      ],
    );
  }
}

class _BalanceSummaryCard extends StatelessWidget {
  const _BalanceSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      padding: const EdgeInsets.fromLTRB(11, 8, 11, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 78,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Saldo saat ini',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'IDR 150.000',
                          maxLines: 1,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          const Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.local_shipping_outlined,
                    label: 'Menunggu',
                    value: '3 pesanan',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.calendar_month_outlined,
                    label: 'Jadwal Kirim',
                    value: '2 Pesanan',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.spa_outlined,
                    label: 'Stock Aktif',
                    value: '5 Kategori',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        border: Border.all(color: AppColors.outlineWarm),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.black),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, height: 1.2),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

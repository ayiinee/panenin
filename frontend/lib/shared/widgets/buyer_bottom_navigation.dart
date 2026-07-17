import 'package:flutter/material.dart';
import 'package:panenin/core/constants/app_colors.dart';

enum BuyerNavigationDestination { home, messages, transactions, profile }

class BuyerBottomNavigation extends StatelessWidget {
  const BuyerBottomNavigation({
    required this.selected,
    required this.onHome,
    required this.onMessages,
    required this.onTransactions,
    required this.onProfile,
    super.key,
  });

  final BuyerNavigationDestination selected;
  final VoidCallback onHome;
  final VoidCallback onMessages;
  final VoidCallback onTransactions;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFFFEDD5))),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x26E47A32),
            offset: Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _NavigationItem(
              key: const ValueKey('home-navigation'),
              icon: Icons.home_outlined,
              label: 'Beranda',
              selected: selected == BuyerNavigationDestination.home,
              onPressed: onHome,
            ),
          ),
          Expanded(
            child: _NavigationItem(
              key: const ValueKey('messages-navigation'),
              icon: Icons.message_outlined,
              label: 'Pesan',
              selected: selected == BuyerNavigationDestination.messages,
              onPressed: onMessages,
            ),
          ),
          Expanded(
            child: _NavigationItem(
              key: const ValueKey('transactions-navigation'),
              icon: Icons.receipt_long_outlined,
              label: 'Transaksi',
              selected: selected == BuyerNavigationDestination.transactions,
              onPressed: onTransactions,
            ),
          ),
          Expanded(
            child: _NavigationItem(
              key: const ValueKey('profile-navigation'),
              icon: Icons.person_outline,
              label: 'Profil',
              selected: selected == BuyerNavigationDestination.profile,
              onPressed: onProfile,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : const Color(0xFFA8A29E);
    return InkWell(
      onTap: onPressed,
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

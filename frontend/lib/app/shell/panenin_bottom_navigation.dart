import 'package:flutter/material.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/app/theme/app_colors.dart';
import 'package:panenin/features/stock/domain/stock_item.dart';

class PaneninBottomNavigation extends StatelessWidget {
  const PaneninBottomNavigation({
    this.selectedIndex = 0,
    this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 73,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.navBorder)),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x26E47A32),
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _NavigationItem(
                      label: 'Beranda',
                      icon: Icons.home_outlined,
                      selected: selectedIndex == 0,
                      onTap: () => onDestinationSelected?.call(0),
                    ),
                  ),
                  Expanded(
                    child: _NavigationItem(
                      label: 'Stok',
                      icon: Icons.inventory_2_outlined,
                      selected: selectedIndex == 1,
                      onTap: () => onDestinationSelected?.call(1),
                    ),
                  ),
                  SizedBox(width: 82),
                  Expanded(
                    child: _NavigationItem(
                      label: 'Pesanan',
                      icon: Icons.receipt_long_outlined,
                      selected: selectedIndex == 2,
                      onTap: () => onDestinationSelected?.call(2),
                    ),
                  ),
                  Expanded(
                    child: _NavigationItem(
                      label: 'Profile',
                      icon: Icons.person_outline,
                      selected: selectedIndex == 3,
                      onTap: () => onDestinationSelected?.call(3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(top: -28, child: _QuickSellItem()),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickSellItem extends StatelessWidget {
  const _QuickSellItem();

  Future<void> _openCamera(BuildContext context) async {
    final photoPath = await Navigator.of(
      context,
    ).pushNamed(RouteNames.fotoJualCepat);
    if (photoPath is! String || !context.mounted) return;

    final item = await Navigator.of(
      context,
    ).pushNamed(RouteNames.formStok, arguments: photoPath);
    if (item is! StockItem || !context.mounted) return;

    await Navigator.of(
      context,
    ).pushReplacementNamed(RouteNames.stokSaya, arguments: item);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Jual Cepat',
      child: InkWell(
        key: const ValueKey('quick-sell-camera'),
        onTap: () => _openCamera(context),
        borderRadius: BorderRadius.circular(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x552F6B3F),
                    blurRadius: 8,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Jual Cepat',
              style: TextStyle(
                color: AppColors.primary,
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

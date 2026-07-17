import 'package:flutter/material.dart';
import 'package:panenin/app/app_repositories.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/app/shell/panenin_bottom_navigation.dart';
import 'package:panenin/features/home/presentation/screens/farmer_home_screen.dart';
import 'package:panenin/features/orders/presentation/screens/manage_orders_screen.dart';
import 'package:panenin/features/profile/presentation/screens/farmer_profile_screen.dart';
import 'package:panenin/features/stock/domain/stock_item.dart';
import 'package:panenin/features/stock/presentation/screens/stock_screen.dart';

class FarmerShell extends StatefulWidget {
  const FarmerShell({
    this.initialIndex = 0,
    this.initialStockItem,
    this.repositories,
    super.key,
  });

  final int initialIndex;
  final StockItem? initialStockItem;
  final AppRepositories? repositories;

  @override
  State<FarmerShell> createState() => _FarmerShellState();
}

class _FarmerShellState extends State<FarmerShell> {
  late int _selectedIndex;
  StockItem? _incomingStockItem;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, 3).toInt();
    _incomingStockItem = widget.initialStockItem;
  }

  void _selectDestination(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  Future<void> _openQuickSell() async {
    final photoPath = await Navigator.of(
      context,
    ).pushNamed(RouteNames.fotoJualCepat);
    if (photoPath is! String || !mounted) return;

    final item = await Navigator.of(
      context,
    ).pushNamed(RouteNames.formStok, arguments: photoPath);
    if (item is! StockItem || !mounted) return;

    var savedItem = item;
    if (widget.repositories case final repositories?) {
      try {
        savedItem = await repositories.stock.create(item);
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan stok: $error')));
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _incomingStockItem = savedItem;
      _selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          FarmerHomeScreen(
            demandRepository: widget.repositories?.demands,
            orderRepository: widget.repositories?.orders,
            embeddedInShell: true,
            onOpenStock: () => _selectDestination(1),
            onOpenOrders: () => _selectDestination(2),
          ),
          StockScreen(
            repository: widget.repositories?.stock,
            embeddedInShell: true,
            initialItem: _incomingStockItem,
          ),
          ManageOrdersScreen(
            repository: widget.repositories?.orders,
            embeddedInShell: true,
          ),
          const FarmerProfileScreen(embeddedInShell: true),
        ],
      ),
      bottomNavigationBar: PaneninBottomNavigation(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
        onQuickSell: _openQuickSell,
      ),
    );
  }
}

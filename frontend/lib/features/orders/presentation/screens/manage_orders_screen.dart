import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/app/shell/panenin_bottom_navigation.dart';
import 'package:panenin/app/theme/app_colors.dart';
import 'package:panenin/features/home/presentation/widgets/active_orders_section.dart';

enum _OrderFilter { all, awaitingPayment, processing, completed }

const _headerHeight = 155.0;
const _progressCardTop = 120.0;
const _progressCardHeight = 110.0;

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  _OrderFilter _filter = _OrderFilter.all;

  List<OrderListItem> get _visibleOrders {
    if (_filter == _OrderFilter.all) return demoOrders;

    final status = switch (_filter) {
      _OrderFilter.awaitingPayment => OrderStatus.awaitingPayment,
      _OrderFilter.processing => OrderStatus.processing,
      _OrderFilter.completed => OrderStatus.completed,
      _OrderFilter.all => throw StateError('Filter semua tidak punya status'),
    };
    return demoOrders.where((order) => order.status == status).toList();
  }

  void _openDetail(OrderListItem order) {
    Navigator.of(
      context,
    ).pushNamed(RouteNames.detailPesanan, arguments: order.detail);
  }

  @override
  Widget build(BuildContext context) {
    final orders = _visibleOrders;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        extendBody: true,
        bottomNavigationBar: PaneninBottomNavigation(
          selectedIndex: 2,
          onDestinationSelected: (index) {
            if (index == 0) Navigator.of(context).maybePop();
          },
        ),
        body: Column(
          children: [
            const _HeaderAndProgress(),
            _FilterBar(
              selected: _filter,
              onSelected: (filter) => setState(() => _filter = filter),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  92 + MediaQuery.paddingOf(context).bottom,
                ),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return OrderCard(
                    key: ValueKey('managed-order-${order.code}'),
                    order: order,
                    onTap: () => _openDetail(order),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderAndProgress extends StatelessWidget {
  const _HeaderAndProgress();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _progressCardTop + _progressCardHeight + 8,
      child: const Stack(
        children: [
          _OrdersHeader(),
          Positioned(
            top: _progressCardTop,
            left: 20,
            right: 20,
            child: _ActiveOrderProgress(),
          ),
        ],
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: _headerHeight,
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
      child: SafeArea(
        bottom: false,
        child: const Center(
          child: Text(
            'Kelola Pesanan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 32 / 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveOrderProgress extends StatelessWidget {
  const _ActiveOrderProgress();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _progressCardHeight,
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pesanan Aktif',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Positioned(
                  left: 100,
                  right: 100,
                  top: 28,
                  child: Divider(height: 1, color: AppColors.textMuted),
                ),
                Row(
                  children: const [
                    Expanded(
                      child: _ProgressStep(
                        icon: Icons.currency_exchange_rounded,
                        label: 'Menunggu DP',
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: _ProgressStep(
                        icon: Icons.local_shipping,
                        label: 'Siap Dikirim',
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: _ProgressStep(
                        icon: Icons.check_circle,
                        label: 'Selesai',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 57,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.textSecondary, width: 0.5),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: AppColors.primary),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, height: 18 / 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final _OrderFilter selected;
  final ValueChanged<_OrderFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Row(
        children: [
          for (final filter in _OrderFilter.values) ...[
            Expanded(
              child: ChoiceChip(
                key: ValueKey('order-filter-${filter.name}'),
                label: SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(_label(filter)),
                  ),
                ),
                selected: selected == filter,
                onSelected: (_) => onSelected(filter),
                showCheckmark: false,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(vertical: -3),
                labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                side: BorderSide(
                  color: selected == filter
                      ? AppColors.primary
                      : const Color(0x33000000),
                ),
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected == filter ? Colors.white : AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            if (filter != _OrderFilter.values.last) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  String _label(_OrderFilter filter) => switch (filter) {
    _OrderFilter.all => 'Semua',
    _OrderFilter.awaitingPayment => 'Menunggu DP',
    _OrderFilter.processing => 'Proses',
    _OrderFilter.completed => 'Selesai',
  };
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/core/constants/app_colors.dart';
import 'package:panenin/features/orders/data/buyer_orders_fixture.dart';
import 'package:panenin/shared/widgets/buyer_bottom_navigation.dart';

enum BuyerOrdersViewState { loading, empty, error, success }

class BuyerOrdersScreen extends StatefulWidget {
  const BuyerOrdersScreen({
    this.state = BuyerOrdersViewState.success,
    this.orders = BuyerOrdersFixture.active,
    this.historyState = BuyerOrdersViewState.success,
    this.historyOrders = BuyerOrdersFixture.history,
    super.key,
  });

  final BuyerOrdersViewState state;
  final List<BuyerOrderSummary> orders;
  final BuyerOrdersViewState historyState;
  final List<BuyerOrderSummary> historyOrders;

  @override
  State<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends State<BuyerOrdersScreen> {
  static const _designWidth = 428.0;
  var _historySelected = false;

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(constraints.maxWidth, _designWidth);
              return Center(
                child: SizedBox(
                  width: width,
                  height: constraints.maxHeight,
                  child: Stack(
                    children: [
                      Positioned.fill(child: _body(width < 390)),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: BuyerBottomNavigation(
                          selected: BuyerNavigationDestination.transactions,
                          onHome: () => Navigator.pushReplacementNamed(
                            context,
                            RouteNames.buyerHome,
                          ),
                          onTransactions: () {},
                          onProfile: () => Navigator.pushReplacementNamed(
                            context,
                            RouteNames.buyerProfile,
                          ),
                          onUnavailable: (label) =>
                              _message('$label akan segera tersedia.'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _body(bool compact) {
    return Column(
      children: [
        _OrdersTabs(
          historySelected: _historySelected,
          onChanged: (value) => setState(() => _historySelected = value),
        ),
        Expanded(child: _content(compact)),
      ],
    );
  }

  Widget _content(bool compact) {
    final state = _historySelected ? widget.historyState : widget.state;
    final orders = _historySelected ? widget.historyOrders : widget.orders;
    return switch (state) {
      BuyerOrdersViewState.loading => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      BuyerOrdersViewState.empty => _OrdersState(
        icon: _historySelected
            ? Icons.history_rounded
            : Icons.receipt_long_outlined,
        title: _historySelected
            ? 'Belum ada riwayat pesanan'
            : 'Belum ada pesanan',
        message: _historySelected
            ? 'Pesanan yang selesai akan muncul di sini.'
            : 'Pesanan yang Anda buat akan muncul di sini.',
      ),
      BuyerOrdersViewState.error => _OrdersState(
        icon: Icons.wifi_off_rounded,
        title: 'Gagal memuat pesanan',
        message: 'Periksa koneksi internet Anda, lalu coba lagi.',
        action: 'Coba Lagi',
        onPressed: () => _message('Mencoba memuat ulang pesanan...'),
      ),
      BuyerOrdersViewState.success when orders.isEmpty => _OrdersState(
        icon: _historySelected
            ? Icons.history_rounded
            : Icons.receipt_long_outlined,
        title: _historySelected
            ? 'Belum ada riwayat pesanan'
            : 'Belum ada pesanan',
        message: _historySelected
            ? 'Pesanan yang selesai akan muncul di sini.'
            : 'Pesanan yang Anda buat akan muncul di sini.',
      ),
      BuyerOrdersViewState.success => ListView.separated(
        key: const ValueKey('buyer-orders-list'),
        padding: EdgeInsets.fromLTRB(
          compact ? 16 : 45,
          24,
          compact ? 16 : 41,
          122,
        ),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) => _OrderCard(
          order: orders[index],
          compact: compact,
          onDetail: () => _showOrderDetail(orders[index]),
          onTrack: () => _showTracking(orders[index]),
        ),
      ),
    };
  }

  void _showOrderDetail(BuyerOrderSummary order) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _OrderInformationSheet(
        title: 'Detail Pesanan',
        order: order,
        children: [
          _InformationRow(label: 'Pemasok', value: order.seller),
          _InformationRow(label: 'Kualitas', value: 'Grade ${order.quality}'),
          _InformationRow(label: 'Jumlah', value: order.quantity),
          _InformationRow(label: 'Total', value: order.price),
          _InformationRow(label: 'Tanggal kirim', value: order.deliveryDate),
        ],
      ),
    );
  }

  void _showTracking(BuyerOrderSummary order) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _OrderInformationSheet(
        title: 'Lacak Pesanan',
        order: order,
        children: [
          _InformationRow(label: 'Status saat ini', value: order.status),
          _InformationRow(label: 'Estimasi tiba', value: order.deliveryDate),
          _InformationRow(label: 'Dikirim oleh', value: order.seller),
        ],
      ),
    );
  }
}

class _OrdersTabs extends StatelessWidget {
  const _OrdersTabs({required this.historySelected, required this.onChanged});

  final bool historySelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 71,
      padding: const EdgeInsets.fromLTRB(21, 8, 18, 0),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          _OrderTab(
            key: const ValueKey('active-orders-tab'),
            label: 'Pesananku',
            selected: !historySelected,
            onTap: () => onChanged(false),
          ),
          _OrderTab(
            key: const ValueKey('order-history-tab'),
            label: 'Riwayat Pesanan',
            selected: historySelected,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _OrderTab extends StatelessWidget {
  const _OrderTab({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            key: ValueKey('order-tab-indicator-$label'),
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Colors.white.withValues(alpha: 0.12) : null,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              border: Border(
                bottom: BorderSide(
                  color: selected ? AppColors.accent : Colors.white38,
                  width: selected ? 4 : 1,
                ),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onDetail,
    required this.onTrack,
    required this.compact,
  });

  final BuyerOrderSummary order;
  final VoidCallback onDetail;
  final VoidCallback onTrack;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF3F4F6)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  order.image,
                  width: compact ? 68 : 80,
                  height: compact ? 68 : 80,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: compact ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1A1C29),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flex(
                      direction: compact ? Axis.vertical : Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!compact)
                          Expanded(child: _OrderMetadata(order: order))
                        else
                          _OrderMetadata(order: order),
                        if (compact) const SizedBox(height: 4),
                        Text(
                          order.price,
                          style: const TextStyle(
                            color: Color(0xFF1A1C29),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _OrderButton(label: 'Detail', onPressed: onDetail),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OrderButton(
                  label: 'Lacak',
                  primary: true,
                  onPressed: onTrack,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderMetadata extends StatelessWidget {
  const _OrderMetadata({required this.order});

  final BuyerOrderSummary order;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          color: Color(0xFF7E8494),
          fontSize: 12,
          height: 16 / 12,
        ),
        children: [
          const TextSpan(text: 'Kualitas: '),
          TextSpan(
            text: '${order.quality}\n',
            style: const TextStyle(color: Colors.black),
          ),
          const TextSpan(text: 'Jumlah: '),
          TextSpan(
            text: order.quantity,
            style: const TextStyle(color: Color(0xFF1A1C29)),
          ),
        ],
      ),
    );
  }
}

class _OrderButton extends StatelessWidget {
  const _OrderButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: primary ? AppColors.primary : Colors.white,
          foregroundColor: primary ? Colors.white : const Color(0xFF1A1C29),
          side: BorderSide(
            color: primary ? AppColors.primary : const Color(0xFFF3F4F6),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}

class _OrdersState extends StatelessWidget {
  const _OrdersState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 48),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onPressed, child: Text(action!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderInformationSheet extends StatelessWidget {
  const _OrderInformationSheet({
    required this.title,
    required this.order,
    required this.children,
  });

  final String title;
  final BuyerOrderSummary order;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    order.image,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    order.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

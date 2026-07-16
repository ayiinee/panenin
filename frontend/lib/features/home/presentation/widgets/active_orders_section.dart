import 'package:flutter/material.dart';
import 'package:panenin/app/theme/app_colors.dart';
import 'package:panenin/features/orders/presentation/screens/order_detail_screen.dart';

enum OrderStatus { awaitingPayment, processing, completed }

const demoOrders = [
  OrderListItem(
    customer: 'Tacibay',
    product: 'Tomat',
    price: 'Rp15.000/Kg',
    deliveryDate: 'Kirim: 09 Juli 2026',
    code: 'E839KG',
    imagePath: 'assets/images/home/order_tomato.png',
    status: OrderStatus.completed,
  ),
  OrderListItem(
    customer: 'Rumah Makan Suhat',
    product: 'Lobak Putih',
    price: 'Rp20.000/Kg',
    deliveryDate: 'Kirim: 11 Juli 2026',
    code: 'E840KG',
    imagePath: 'assets/images/home/order_white_radish.png',
    status: OrderStatus.completed,
  ),
  OrderListItem(
    customer: 'Warung Tegal Klojen',
    product: 'Kacang Panjang',
    price: 'Rp16.000/Kg',
    deliveryDate: 'Kirim: 13 Juli 2026',
    code: 'E841KG',
    imagePath: 'assets/images/home/order_long_beans.png',
    status: OrderStatus.awaitingPayment,
  ),
  OrderListItem(
    customer: 'Warung Swimpit',
    product: 'Kubis',
    price: 'Rp5.000/Kg',
    deliveryDate: 'Kirim: 15 Juli 2026',
    code: 'E842KG',
    imagePath: 'assets/images/home/order_cabbage.png',
    status: OrderStatus.processing,
  ),
];

class ActiveOrdersSection extends StatelessWidget {
  const ActiveOrdersSection({this.onViewAll, super.key});

  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final activeOrders = demoOrders
        .where((order) => order.status != OrderStatus.completed)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Daftar Pesanan Aktif',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  height: 26 / 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 2),
        for (var index = 0; index < activeOrders.length; index++) ...[
          OrderCard(
            order: activeOrders[index],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    OrderDetailScreen(order: activeOrders[index].detail),
              ),
            ),
          ),
          if (index != activeOrders.length - 1) const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({required this.order, required this.onTap, super.key});

  final OrderListItem order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: ValueKey('active-order-${order.code}'),
      button: true,
      label: '${order.customer}, ${order.product}, ${order.statusLabel}',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            constraints: const BoxConstraints(minHeight: 116),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0x33000000), width: 0.5),
              borderRadius: BorderRadius.circular(9),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 340;

                return Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        order.imagePath,
                        width: compact ? 64 : 70,
                        height: compact ? 68 : 74,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _OrderDetails(order: order)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: compact ? 92 : 105,
                      height: 96,
                      child: _OrderActions(order: order, onTap: onTap),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderDetails extends StatelessWidget {
  const _OrderDetails({required this.order});

  final OrderListItem order;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          order.customer,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            height: 18 / 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          order.product,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, height: 18 / 14),
        ),
        Text(
          order.price,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, height: 18 / 14),
        ),
        const SizedBox(height: 3),
        Text(
          order.deliveryDate,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, height: 17 / 12),
        ),
      ],
    );
  }
}

class _OrderActions extends StatelessWidget {
  const _OrderActions({required this.order, required this.onTap});

  final OrderListItem order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          order.code,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 9, height: 1.2),
        ),
        const Spacer(),
        Container(
          height: 25,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: order.statusColor,
            borderRadius: BorderRadius.circular(5),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              order.statusLabel,
              style: TextStyle(
                color: order.statusTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 28,
          child: OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Lihat Detail'),
            ),
          ),
        ),
      ],
    );
  }
}

class OrderListItem {
  const OrderListItem({
    required this.customer,
    required this.product,
    required this.price,
    required this.deliveryDate,
    required this.code,
    required this.imagePath,
    required this.status,
  });

  final String customer;
  final String product;
  final String price;
  final String deliveryDate;
  final String code;
  final String imagePath;
  final OrderStatus status;

  OrderDetailData get detail => switch (code) {
    'E839KG' => const OrderDetailData(
      code: 'E839KG',
      customer: 'Tacibay',
      tagline: 'Olahan tomat segar setiap hari',
      recipient: 'Tacibay',
      address: 'Jl. Tidar No. 39, Malang',
      phone: '0812 3456 8390',
      item: 'Tomat 20 Kg',
      note: 'Pilih tomat matang dan segar',
      imagePath: 'assets/images/home/buyer_avatar.png',
      initialStage: OrderDetailStage.completed,
    ),
    'E840KG' => const OrderDetailData(
      code: 'E840KG',
      customer: 'Rumah Makan Suhat',
      tagline: 'Masakan rumahan di kawasan Suhat',
      recipient: 'Rumah Makan Suhat',
      address: 'Jl. Soekarno Hatta No. 40, Malang',
      phone: '0812 3456 8400',
      item: 'Lobak Putih 25 Kg',
      note: 'Ukuran sedang dan tidak memar',
      imagePath: 'assets/images/home/pasar_induk.png',
      initialStage: OrderDetailStage.completed,
    ),
    'E841KG' => const OrderDetailData(
      code: 'E841KG',
      customer: 'Warung Tegal Klojen',
      tagline: 'Sedia aneka masakan rumahan khas Tegal',
      recipient: 'Warung Tegal Klojen',
      address: 'Jl. Klojen No. 27, Malang',
      phone: '0812 3456 8410',
      item: 'Kacang Panjang 15 Kg',
      note: 'Pastikan masih segar',
      imagePath: 'assets/images/home/warteg_owner.png',
      initialStage: OrderDetailStage.awaitingPayment,
    ),
    _ => const OrderDetailData(
      code: 'E842KG',
      customer: 'Warung Swimpit',
      tagline: 'Sedia nasi hangat dan lauk rumahan setiap hari',
      recipient: 'Bu Siti',
      address: 'Jl. Swimpit No. 8, Malang',
      phone: '0812 3456 8420',
      item: 'Kubis 20 Kg',
      note: 'Pilih ukuran sedang',
      imagePath: 'assets/images/home/swimpit_owner.png',
      initialStage: OrderDetailStage.readyToShip,
    ),
  };

  String get statusLabel => switch (status) {
    OrderStatus.awaitingPayment => 'Menunggu DP',
    OrderStatus.processing => 'Proses',
    OrderStatus.completed => 'Selesai',
  };

  Color get statusColor => switch (status) {
    OrderStatus.awaitingPayment => const Color(0xFFDC2626),
    OrderStatus.processing => AppColors.accent,
    OrderStatus.completed => AppColors.primary,
  };

  Color get statusTextColor => switch (status) {
    OrderStatus.awaitingPayment => Colors.white,
    OrderStatus.processing => Colors.black,
    OrderStatus.completed => Colors.white,
  };
}

import 'package:flutter/material.dart';
import 'package:panenin/app/theme/app_colors.dart';

enum ActiveOrderStatus { completed, awaitingPayment, processing }

class ActiveOrdersSection extends StatelessWidget {
  const ActiveOrdersSection({super.key});

  static const _orders = [
    _ActiveOrder(
      customer: 'Tacibay',
      product: 'Tomat',
      price: 'Rp15.000/Kg',
      deliveryDate: 'Kirim: 09 Juli 2026',
      code: 'E839KG',
      imagePath: 'assets/images/home/order_tomato.png',
      status: ActiveOrderStatus.completed,
    ),
    _ActiveOrder(
      customer: 'Rumah Makan Suhat',
      product: 'Lobak Putih',
      price: 'Rp20.000/Kg',
      deliveryDate: 'Kirim: 11 Juli 2026',
      code: 'E840KG',
      imagePath: 'assets/images/home/order_white_radish.png',
      status: ActiveOrderStatus.completed,
    ),
    _ActiveOrder(
      customer: 'Warung Tegal Klojen',
      product: 'Kacang Panjang',
      price: 'Rp16.000/Kg',
      deliveryDate: 'Kirim: 13 Juli 2026',
      code: 'E841KG',
      imagePath: 'assets/images/home/order_long_beans.png',
      status: ActiveOrderStatus.awaitingPayment,
    ),
    _ActiveOrder(
      customer: 'Warung Swimpit',
      product: 'Kubis',
      price: 'Rp5.000/Kg',
      deliveryDate: 'Kirim: 15 Juli 2026',
      code: 'E842KG',
      imagePath: 'assets/images/home/order_cabbage.png',
      status: ActiveOrderStatus.processing,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
              onPressed: () {},
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
        for (var index = 0; index < _orders.length; index++) ...[
          _ActiveOrderCard(order: _orders[index]),
          if (index != _orders.length - 1) const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({required this.order});

  final _ActiveOrder order;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${order.customer}, ${order.product}, ${order.statusLabel}',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: () {},
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
                      child: _OrderActions(order: order),
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

  final _ActiveOrder order;

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
  const _OrderActions({required this.order});

  final _ActiveOrder order;

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
            onPressed: () {},
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

class _ActiveOrder {
  const _ActiveOrder({
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
  final ActiveOrderStatus status;

  String get statusLabel => switch (status) {
    ActiveOrderStatus.completed => 'Selesai',
    ActiveOrderStatus.awaitingPayment => 'Menunggu DP',
    ActiveOrderStatus.processing => 'Proses',
  };

  Color get statusColor => switch (status) {
    ActiveOrderStatus.completed => AppColors.primary,
    ActiveOrderStatus.awaitingPayment => const Color(0xFFDC2626),
    ActiveOrderStatus.processing => AppColors.accent,
  };

  Color get statusTextColor => switch (status) {
    ActiveOrderStatus.completed => Colors.white,
    ActiveOrderStatus.awaitingPayment => Colors.white,
    ActiveOrderStatus.processing => Colors.black,
  };
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panenin/app/theme/app_colors.dart';

enum OrderDetailStage { awaitingPayment, readyToShip, completed }

class OrderDetailData {
  const OrderDetailData({
    required this.code,
    required this.customer,
    required this.tagline,
    required this.recipient,
    required this.address,
    required this.phone,
    required this.item,
    required this.note,
    required this.imagePath,
    required this.initialStage,
  });

  final String code;
  final String customer;
  final String tagline;
  final String recipient;
  final String address;
  final String phone;
  final String item;
  final String note;
  final String imagePath;
  final OrderDetailStage initialStage;
}

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({required this.order, super.key});

  final OrderDetailData order;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late OrderDetailStage _stage = widget.order.initialStage;

  void _advanceOrder() {
    setState(() {
      _stage = switch (_stage) {
        OrderDetailStage.awaitingPayment => OrderDetailStage.readyToShip,
        OrderDetailStage.readyToShip => OrderDetailStage.completed,
        OrderDetailStage.completed => OrderDetailStage.completed,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: 32 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Stack(
            children: [
              const _DetailHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 111, 20, 0),
                child: Column(
                  children: [
                    _OrderSummary(order: widget.order, stage: _stage),
                    const SizedBox(height: 22),
                    _OrderProgress(stage: _stage),
                    const SizedBox(height: 28),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Identitas Penerima',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CustomerCard(order: widget.order),
                    const SizedBox(height: 32),
                    _ShippingDetails(order: widget.order),
                    if (_stage != OrderDetailStage.completed) ...[
                      const SizedBox(height: 36),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: FilledButton(
                          key: const ValueKey('advance-order'),
                          onPressed: _advanceOrder,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: Text(
                            _stage == OrderDetailStage.awaitingPayment
                                ? 'Konfirmasi Pengiriman Pesanan'
                                : 'Konfirmasi Pesanan',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 155,
      width: double.infinity,
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Center(
              child: Text(
                'Detail Pesanan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  height: 32 / 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                key: const ValueKey('detail-back'),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'Kembali ke kelola pesanan',
                color: Colors.white,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.order, required this.stage});

  final OrderDetailData order;
  final OrderDetailStage stage;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 71,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.widgets_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ID Pesanan:',
                  style: TextStyle(fontSize: 12, height: 18 / 12),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        order.code,
                        style: const TextStyle(
                          fontSize: 20,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    InkWell(
                      onTap: () =>
                          Clipboard.setData(ClipboardData(text: order.code)),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.copy_rounded, size: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 117,
            height: 31,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _statusColor(stage),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              _statusLabel(stage),
              style: TextStyle(
                color: stage == OrderDetailStage.readyToShip
                    ? Colors.black
                    : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderProgress extends StatelessWidget {
  const _OrderProgress({required this.stage});

  final OrderDetailStage stage;

  @override
  Widget build(BuildContext context) {
    final progress = stage.index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = (constraints.maxWidth - 40) / 3;

          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 28,
                left: boxWidth,
                width: 20,
                child: _ProgressLine(active: progress >= 1),
              ),
              Positioned(
                top: 28,
                left: boxWidth * 2 + 20,
                width: 20,
                child: _ProgressLine(active: progress >= 2),
              ),
              Row(
                children: [
                  Expanded(
                    child: _ProgressStep(
                      icon: Icons.payments_outlined,
                      label: 'Menunggu DP',
                      active: progress >= 0,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _ProgressStep(
                      icon: Icons.local_shipping,
                      label: 'Siap Dikirim',
                      active: progress >= 1,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _ProgressStep(
                      icon: Icons.check_circle,
                      label: 'Selesai',
                      active: progress >= 2,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      color: active ? AppColors.primary : AppColors.textMuted,
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 57,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.white,
        border: Border.all(color: AppColors.primary, width: 0.5),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: active ? Colors.white : AppColors.primary,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.black,
                fontSize: 12,
                height: 18 / 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShippingDetails extends StatelessWidget {
  const _ShippingDetails({required this.order});

  final OrderDetailData order;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detail Pengiriman',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0x66000000), width: 0.5),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Column(
            children: [
              _DetailRow(label: 'Penerima', value: order.recipient),
              _DetailRow(label: 'Alamat', value: order.address),
              _DetailRow(label: 'Nomor Hp', value: order.phone),
              _DetailRow(label: 'Barang', value: order.item),
              _DetailRow(label: 'Note', value: order.note),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 25,
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, height: 18 / 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                height: 18 / 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.order});

  final OrderDetailData order;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0x66000000), width: 0.5),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          ClipOval(
            child: Image.asset(
              order.imagePath,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  order.tagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, height: 15 / 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            tooltip: 'Hubungi ${order.customer}',
            icon: const Icon(Icons.chat_bubble_outline, size: 25),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

String _statusLabel(OrderDetailStage stage) => switch (stage) {
  OrderDetailStage.awaitingPayment => 'Menunggu DP',
  OrderDetailStage.readyToShip => 'Siap Dikirim',
  OrderDetailStage.completed => 'Selesai',
};

Color _statusColor(OrderDetailStage stage) => switch (stage) {
  OrderDetailStage.awaitingPayment => AppColors.danger,
  OrderDetailStage.readyToShip => AppColors.accent,
  OrderDetailStage.completed => AppColors.primary,
};

import 'package:panenin/features/home/presentation/widgets/active_orders_section.dart';
import 'package:panenin/features/orders/data/order_repository.dart';
import 'package:panenin/features/orders/presentation/screens/order_detail_screen.dart';

OrderListItem mapOrderToListItem(OrderRecord order) {
  final status = switch (order.status) {
    'COMPLETED' || 'REJECTED' || 'CANCELLED' => OrderStatus.completed,
    'PENDING_SELLER' => OrderStatus.awaitingPayment,
    _ => OrderStatus.processing,
  };
  final stage = switch (order.status) {
    'COMPLETED' || 'REJECTED' || 'CANCELLED' => OrderDetailStage.completed,
    'READY' || 'PICKED_UP' || 'DELIVERED' => OrderDetailStage.readyToShip,
    _ => OrderDetailStage.awaitingPayment,
  };
  final amount = order.totalAmount.round().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return OrderListItem(
    customer: order.buyerName,
    product: '${order.commodity} ${order.quantity}${order.unit}',
    price: 'Rp $amount',
    deliveryDate: _formatDate(order.deliveryDate),
    code: order.orderNumber,
    imagePath: 'assets/images/home/buyer_avatar.png',
    status: status,
    detailData: OrderDetailData(
      code: order.orderNumber,
      customer: order.buyerName,
      tagline: 'Pesanan Panenin',
      recipient: order.buyerName,
      address: order.deliveryAddress ?? 'Alamat tersedia setelah konfirmasi',
      phone: 'Kontak dilindungi',
      item: '${order.commodity} ${order.quantity}${order.unit}',
      note: 'Metode pengiriman: ${order.deliveryMethod}',
      imagePath: 'assets/images/home/buyer_avatar.png',
      initialStage: stage,
    ),
  );
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

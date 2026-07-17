enum StockStatus { available, low, empty, expired }

enum InventoryReservationStatus { active, released, consumed, expired }

class InventoryReservation {
  const InventoryReservation({
    required this.id,
    required this.inventoryBatchId,
    required this.orderId,
    required this.quantity,
    required this.status,
    required this.expiresAt,
  });

  final String id;
  final String inventoryBatchId;
  final String orderId;
  final num quantity;
  final InventoryReservationStatus status;
  final DateTime expiresAt;

  InventoryReservationStatus statusAt(DateTime now) =>
      status == InventoryReservationStatus.active && !now.isBefore(expiresAt)
      ? InventoryReservationStatus.expired
      : status;
}

class StockItem {
  const StockItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.price,
    this.harvestedAt,
    this.shelfLifeDays,
    this.reservations = const [],
    this.imagePath,
    this.photoStoragePath,
  });

  final String id;
  final String name;
  final int quantity;
  final String unit;
  final int price;
  final DateTime? harvestedAt;
  final int? shelfLifeDays;
  final List<InventoryReservation> reservations;
  final String? imagePath;
  final String? photoStoragePath;

  DateTime? get expiresAt => harvestedAt == null || shelfLifeDays == null
      ? null
      : harvestedAt!.add(Duration(days: shelfLifeDays!));

  StockStatus statusAt(DateTime now) {
    final expiry = expiresAt;
    if (quantity > 0 && expiry != null && !now.isBefore(expiry)) {
      return StockStatus.expired;
    }
    if (quantity == 0) return StockStatus.empty;
    if (quantity <= 10) return StockStatus.low;
    return StockStatus.available;
  }

  StockStatus get status => statusAt(DateTime.now());

  num reservedQuantityAt(DateTime now) => reservations
      .where(
        (reservation) =>
            reservation.statusAt(now) == InventoryReservationStatus.active,
      )
      .fold(0, (total, reservation) => total + reservation.quantity);

  StockItem copyWith({
    String? name,
    int? quantity,
    String? unit,
    int? price,
    DateTime? harvestedAt,
  }) {
    return StockItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      harvestedAt: harvestedAt ?? this.harvestedAt,
      shelfLifeDays: shelfLifeDays,
      reservations: reservations,
      imagePath: imagePath,
      photoStoragePath: photoStoragePath,
    );
  }
}

final demoStockItems = [
  const StockItem(
    id: 'cabai-merah',
    name: 'Cabai Merah',
    quantity: 12,
    unit: 'Kg',
    price: 40000,
    imagePath: 'assets/images/stock/red_chili.png',
  ),
  const StockItem(
    id: 'lobak-putih',
    name: 'Lobak Putih',
    quantity: 10,
    unit: 'Kg',
    price: 20000,
    imagePath: 'assets/images/home/order_white_radish.png',
  ),
  StockItem(
    id: 'kacang-panjang',
    name: 'Kacang Panjang',
    quantity: 15,
    unit: 'Kg',
    price: 16000,
    harvestedAt: DateTime(2026, 7, 13, 8),
    shelfLifeDays: 3,
    reservations: [
      InventoryReservation(
        id: 'reservation-kacang-panjang',
        inventoryBatchId: 'kacang-panjang',
        orderId: 'order-kacang-panjang',
        quantity: 5,
        status: InventoryReservationStatus.active,
        expiresAt: DateTime(2026, 7, 16, 8),
      ),
    ],
    imagePath: 'assets/images/home/order_long_beans.png',
  ),
];

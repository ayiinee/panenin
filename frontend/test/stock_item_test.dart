import 'package:flutter_test/flutter_test.dart';
import 'package:panenin/features/stock/domain/stock_item.dart';

void main() {
  test('batch berubah menjadi expired setelah umur simpan terlewati', () {
    final item = StockItem(
      id: 'batch-kacang-panjang',
      name: 'Kacang Panjang',
      quantity: 15,
      unit: 'Kg',
      price: 16000,
      harvestedAt: DateTime(2026, 7, 13, 8),
      shelfLifeDays: 3,
    );

    expect(item.statusAt(DateTime(2026, 7, 15, 8)), StockStatus.available);
    expect(item.statusAt(DateTime(2026, 7, 17, 8)), StockStatus.expired);
  });

  test(
    'reservation aktif berubah efektif menjadi expired saat melewati TTL',
    () {
      final reservation = InventoryReservation(
        id: 'reservation-1',
        inventoryBatchId: 'batch-1',
        orderId: 'order-1',
        quantity: 5,
        status: InventoryReservationStatus.active,
        expiresAt: DateTime(2026, 7, 17, 8),
      );

      expect(
        reservation.statusAt(DateTime(2026, 7, 17, 7)),
        InventoryReservationStatus.active,
      );
      expect(
        reservation.statusAt(DateTime(2026, 7, 17, 9)),
        InventoryReservationStatus.expired,
      );
    },
  );
}

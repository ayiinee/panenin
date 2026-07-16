enum StockStatus { available, low, empty }

class StockItem {
  const StockItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.price,
    this.imagePath,
  });

  final String id;
  final String name;
  final int quantity;
  final String unit;
  final int price;
  final String? imagePath;

  StockStatus get status {
    if (quantity == 0) return StockStatus.empty;
    if (quantity <= 10) return StockStatus.low;
    return StockStatus.available;
  }

  StockItem copyWith({String? name, int? quantity, String? unit, int? price}) {
    return StockItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      imagePath: imagePath,
    );
  }
}

const demoStockItems = [
  StockItem(
    id: 'cabai-merah',
    name: 'Cabai Merah',
    quantity: 12,
    unit: 'Kg',
    price: 40000,
    imagePath: 'assets/images/stock/red_chili.png',
  ),
  StockItem(
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
    quantity: 0,
    unit: 'Kg',
    price: 16000,
    imagePath: 'assets/images/home/order_long_beans.png',
  ),
];

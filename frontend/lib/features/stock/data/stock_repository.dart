import 'package:panenin/core/network/api_client.dart';
import 'package:panenin/features/stock/domain/stock_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StockRepository {
  StockRepository(this._api);

  factory StockRepository.create() {
    final supabase = Supabase.instance.client;
    return StockRepository(ApiClient(supabase));
  }

  final ApiTransport _api;

  Future<List<StockItem>> list() async {
    final data = await _api.get('/api/v1/inventory');
    return (data! as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_fromJson)
        .toList();
  }

  Future<StockItem> create(StockItem item) async {
    final data = await _api.post(
      '/api/v1/inventory',
      body: {
        'commodity': item.name,
        'quantity': item.quantity,
        'unit': item.unit,
        'harvestedAt': item.harvestedAt?.toUtc().toIso8601String(),
        'availableAt': DateTime.now().toUtc().toIso8601String(),
        'minimumPrice': item.price,
      },
    );
    return _fromJson(data! as Map<String, dynamic>);
  }

  Future<StockItem> update(StockItem item) async {
    final data = await _api.patch(
      '/api/v1/inventory/${item.id}',
      body: {'quantityAvailable': item.quantity, 'minimumPrice': item.price},
    );
    return _fromJson(data! as Map<String, dynamic>);
  }

  StockItem _fromJson(Map<String, dynamic> json) => StockItem(
    id: json['id'] as String,
    name: json['commodity'] as String,
    quantity: _number(json['quantityAvailable']).round(),
    unit: json['unit'] as String,
    price: _number(json['minimumPrice']).round(),
    harvestedAt: json['harvestedAt'] == null
        ? null
        : DateTime.parse(json['harvestedAt'] as String),
  );

  num _number(Object? value) => switch (value) {
    num number => number,
    String text => num.parse(text),
    _ => 0,
  };
}

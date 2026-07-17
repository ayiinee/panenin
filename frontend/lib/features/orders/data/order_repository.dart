import 'package:panenin/core/network/api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderRecord {
  const OrderRecord({
    required this.id,
    required this.orderNumber,
    required this.buyerName,
    required this.sellerName,
    required this.commodity,
    required this.quantity,
    required this.unit,
    required this.totalAmount,
    required this.status,
    required this.deliveryMethod,
    required this.deliveryDate,
    this.deliveryAddress,
  });

  final String id;
  final String orderNumber;
  final String buyerName;
  final String sellerName;
  final String commodity;
  final num quantity;
  final String unit;
  final num totalAmount;
  final String status;
  final String deliveryMethod;
  final DateTime deliveryDate;
  final String? deliveryAddress;

  factory OrderRecord.fromJson(Map<String, dynamic> json) => OrderRecord(
    id: json['id'] as String,
    orderNumber: json['orderNumber'] as String,
    buyerName: json['buyerName'] as String,
    sellerName: json['sellerName'] as String,
    commodity: json['commodity'] as String,
    quantity: _number(json['quantity']),
    unit: json['unit'] as String,
    totalAmount: _number(json['totalAmount']),
    status: json['status'] as String,
    deliveryMethod: json['deliveryMethod'] as String,
    deliveryDate: DateTime.parse(json['deliveryDate'] as String),
    deliveryAddress: json['deliveryAddress'] as String?,
  );

  static num _number(Object? value) => switch (value) {
    num number => number,
    String text => num.parse(text),
    _ => 0,
  };
}

class OrderRepository {
  OrderRepository(this._api);

  factory OrderRepository.create() {
    final supabase = Supabase.instance.client;
    return OrderRepository(ApiClient(supabase));
  }

  final ApiTransport _api;

  Future<List<OrderRecord>> list() async {
    final data = await _api.get('/api/v1/orders');
    return (data! as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(OrderRecord.fromJson)
        .toList();
  }

  Future<OrderRecord> get(String id) async {
    final data = await _api.get('/api/v1/orders/$id');
    return OrderRecord.fromJson(data! as Map<String, dynamic>);
  }
}

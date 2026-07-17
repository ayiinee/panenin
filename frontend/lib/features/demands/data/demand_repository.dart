import 'package:panenin/core/network/api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DemandRecord {
  const DemandRecord({
    required this.id,
    required this.buyerName,
    required this.commodity,
    required this.quantityRemaining,
    required this.unit,
    required this.maxPrice,
    required this.neededAt,
    required this.status,
  });

  final String id;
  final String buyerName;
  final String commodity;
  final num quantityRemaining;
  final String unit;
  final num maxPrice;
  final DateTime neededAt;
  final String status;

  factory DemandRecord.fromJson(Map<String, dynamic> json) => DemandRecord(
    id: json['id'] as String,
    buyerName: json['buyerName'] as String,
    commodity: json['commodity'] as String,
    quantityRemaining: _number(json['quantityRemaining']),
    unit: json['unit'] as String,
    maxPrice: _number(json['maxPrice']),
    neededAt: DateTime.parse(json['neededAt'] as String),
    status: json['status'] as String,
  );

  static num _number(Object? value) => switch (value) {
    num number => number,
    String text => num.parse(text),
    _ => 0,
  };
}

class DemandRepository {
  DemandRepository(this._api);

  factory DemandRepository.create() {
    final supabase = Supabase.instance.client;
    return DemandRepository(ApiClient(supabase));
  }

  final ApiTransport _api;

  Future<List<DemandRecord>> list() async {
    final data = await _api.get('/api/v1/demands');
    return (data! as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(DemandRecord.fromJson)
        .toList();
  }
}

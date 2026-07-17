import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panenin/core/network/api_client.dart';
import 'package:panenin/features/demands/data/demand_repository.dart';
import 'package:panenin/features/home/presentation/screens/farmer_home_screen.dart';
import 'package:panenin/features/orders/data/order_repository.dart';

void main() {
  testWidgets('data demo petani tetap tampil saat backend masih kosong', (
    tester,
  ) async {
    final api = _EmptyFarmerHomeApi();

    await tester.pumpWidget(
      MaterialApp(
        home: FarmerHomeScreen(
          demandRepository: DemandRepository(api),
          orderRepository: OrderRepository(api),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mbak Rina'), findsOneWidget);
    expect(find.text('Pak Syaiful'), findsOneWidget);
    expect(find.text('Warung Tegal Klojen'), findsOneWidget);
    expect(find.text('Warung Swimpit'), findsOneWidget);
  });
}

class _EmptyFarmerHomeApi implements ApiTransport {
  @override
  Future<Object?> get(String path) async => switch (path) {
    '/api/v1/demands' || '/api/v1/orders' => <Map<String, dynamic>>[],
    _ => throw StateError('Unexpected request: GET $path'),
  };

  @override
  Future<Object?> patch(String path, {Object? body}) =>
      throw UnimplementedError();

  @override
  Future<Object?> post(String path, {Object? body}) =>
      throw UnimplementedError();

  @override
  Future<Object?> put(String path, {Object? body}) =>
      throw UnimplementedError();
}

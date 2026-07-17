import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panenin/core/network/api_client.dart';
import 'package:panenin/features/orders/data/order_repository.dart';
import 'package:panenin/features/orders/presentation/screens/manage_orders_screen.dart';
import 'package:panenin/features/stock/data/stock_repository.dart';
import 'package:panenin/features/stock/presentation/screens/stock_screen.dart';

void main() {
  testWidgets('empty inventory keeps the previous demo stock', (tester) async {
    await _setMobileSurface(tester);
    final repository = StockRepository(
      _FarmerApi(responses: {'/api/v1/inventory': const []}),
    );

    await tester.pumpWidget(
      MaterialApp(home: StockScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cabai Merah'), findsOneWidget);
    expect(find.text('Lobak Putih'), findsOneWidget);
    expect(find.text('Belum ada stok.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inventory failure keeps the previous demo stock', (
    tester,
  ) async {
    await _setMobileSurface(tester);
    final repository = StockRepository(
      _FarmerApi(errors: {'/api/v1/inventory'}),
    );

    await tester.pumpWidget(
      MaterialApp(home: StockScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cabai Merah'), findsOneWidget);
    expect(find.text('Lobak Putih'), findsOneWidget);
    expect(find.textContaining('Gagal memuat stok:'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty orders keep the previous demo order list', (tester) async {
    await _setMobileSurface(tester);
    final repository = OrderRepository(
      _FarmerApi(responses: {'/api/v1/orders': const []}),
    );

    await tester.pumpWidget(
      MaterialApp(home: ManageOrdersScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Warung Tegal Klojen'), findsOneWidget);
    expect(find.text('Warung Swimpit'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('orders failure keeps the previous demo order list', (
    tester,
  ) async {
    await _setMobileSurface(tester);
    final repository = OrderRepository(_FarmerApi(errors: {'/api/v1/orders'}));

    await tester.pumpWidget(
      MaterialApp(home: ManageOrdersScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Warung Tegal Klojen'), findsOneWidget);
    expect(find.text('Warung Swimpit'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _setMobileSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(428, 938);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _FarmerApi implements ApiTransport {
  _FarmerApi({
    this.responses = const <String, Object?>{},
    this.errors = const <String>{},
  });

  final Map<String, Object?> responses;
  final Set<String> errors;

  @override
  Future<Object?> get(String path) async {
    if (errors.contains(path)) throw StateError('backend unavailable');
    if (responses.containsKey(path)) return responses[path];
    throw StateError('Unexpected GET $path');
  }

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

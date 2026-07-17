import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panenin/core/network/api_client.dart';
import 'package:panenin/features/home/data/buyer_home_repository.dart';
import 'package:panenin/features/home/presentation/screens/buyer_home_screen.dart';
import 'package:panenin/features/profile/data/profile_repository.dart';

void main() {
  test('empty catalog uses the previous buyer home fixture', () async {
    final api = _BuyerHomeApi(catalog: const []);
    final repository = BuyerHomeRepository(api, ProfileRepository(api));

    final data = await repository.load();

    expect(data.location, 'Batu, Jawa Timur');
    expect(data.categories.map((category) => category.name), [
      'Cabai',
      'Tomat',
      'Sayuran',
      'Kentang',
      'Buah',
    ]);
    expect(data.products.map((product) => product.name), [
      'Cabai Merah Kering',
      'Kentang',
      'Sawi',
      'Bawang Putih',
    ]);
  });

  test('available catalog still takes priority over the fixture', () async {
    final api = _BuyerHomeApi(
      catalog: const [
        {'commodity': 'Tomat Organik', 'pricePerUnit': 18000},
      ],
    );
    final repository = BuyerHomeRepository(api, ProfileRepository(api));

    final data = await repository.load();

    expect(data.location, 'Batu, Jawa Timur');
    expect(data.categories.single.name, 'Tomat Organik');
    expect(data.products.single.name, 'Tomat Organik');
    expect(data.products.single.price, 'Rp 18.000');
  });

  testWidgets('backend failure still renders the previous buyer home fixture', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(428, 926);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _BuyerHomeApi(
      catalog: const [],
      catalogError: StateError('backend unavailable'),
    );
    final repository = BuyerHomeRepository(api, ProfileRepository(api));

    await tester.pumpWidget(
      MaterialApp(home: BuyerHomeScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Malang, Jawa Timur'), findsOneWidget);
    expect(find.text('Cabai Merah Kering'), findsOneWidget);
    expect(find.text('Bawang Putih'), findsOneWidget);
    expect(find.text('Gagal memuat beranda'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _BuyerHomeApi implements ApiTransport {
  _BuyerHomeApi({required this.catalog, this.catalogError});

  final List<Map<String, dynamic>> catalog;
  final Object? catalogError;

  @override
  Future<Object?> get(String path) async {
    if (path == '/api/v1/me/profile') {
      return {
        'name': 'Bu Ani',
        'organizationName': 'Dapur Bu Ani',
        'organizationType': 'UMKM',
        'address': 'Batu, Jawa Timur',
        'commodityNames': ['Tomat'],
      };
    }
    if (path == '/api/v1/catalog/listings') {
      if (catalogError case final error?) throw error;
      return catalog;
    }
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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panenin/core/network/api_client.dart';
import 'package:panenin/features/auth/domain/user_role.dart';
import 'package:panenin/features/orders/data/order_repository.dart';
import 'package:panenin/features/profile/data/profile_repository.dart';
import 'package:panenin/features/stock/data/stock_repository.dart';
import 'package:panenin/features/whatsapp/data/whatsapp_repository.dart';
import 'package:panenin/features/whatsapp/presentation/whatsapp_link_screen.dart';

void main() {
  test('user roles separate auth metadata from organization type', () {
    expect(UserRole.farmer.authValue, 'FARMER');
    expect(UserRole.farmer.organizationType, 'FARM');
    expect(UserRole.buyer.authValue, 'BUYER');
    expect(UserRole.buyer.organizationType, 'UMKM');
    expect(UserRole.fromApiValue('FARMER'), UserRole.farmer);
    expect(UserRole.fromApiValue('BUYER'), UserRole.buyer);
  });

  test('profile repository sends canonical organization role', () async {
    final api = _FakeApi(
      responses: {
        'PUT /api/v1/me/profile': {
          'name': 'Pak Ferdi',
          'organizationName': 'Tani Makmur',
          'organizationType': 'FARM',
          'address': 'Garut',
          'commodityNames': ['Tomat'],
        },
      },
    );
    final repository = ProfileRepository(api);

    final profile = await repository.saveProfile(
      const ProfileInput(
        name: 'Pak Ferdi',
        organizationName: 'Tani Makmur',
        role: UserRole.farmer,
        address: 'Garut',
        commodityNames: ['Tomat'],
      ),
    );

    expect(api.lastBody?['organizationType'], 'FARM');
    expect(profile.organizationType, 'FARM');
  });

  test('stock repository maps backend inventory', () async {
    final repository = StockRepository(
      _FakeApi(
        responses: {
          'GET /api/v1/inventory': [
            {
              'id': '11111111-1111-1111-1111-111111111111',
              'commodity': 'Tomat',
              'quantityAvailable': '12.000',
              'unit': 'kg',
              'minimumPrice': '8000.00',
              'harvestedAt': '2026-07-17T00:00:00Z',
            },
          ],
        },
      ),
    );

    final items = await repository.list();

    expect(items.single.name, 'Tomat');
    expect(items.single.quantity, 12);
    expect(items.single.price, 8000);
  });

  test('order repository maps order response', () async {
    final repository = OrderRepository(
      _FakeApi(
        responses: {
          'GET /api/v1/orders': [
            {
              'id': '22222222-2222-2222-2222-222222222222',
              'orderNumber': 'PNN-001',
              'buyerName': 'Warung Demo',
              'sellerName': 'Tani Demo',
              'commodity': 'Tomat',
              'quantity': '20',
              'unit': 'kg',
              'totalAmount': '200000',
              'status': 'PENDING_SELLER',
              'deliveryMethod': 'PICKUP',
              'deliveryDate': '2026-07-20',
              'deliveryAddress': null,
            },
          ],
        },
      ),
    );

    final orders = await repository.list();

    expect(orders.single.orderNumber, 'PNN-001');
    expect(orders.single.totalAmount, 200000);
  });

  testWidgets('WhatsApp linking requests and renders one-time code', (
    tester,
  ) async {
    String? openedLinkCode;
    final repository = WhatsAppRepository(
      _FakeApi(
        responses: {
          'GET /api/v1/whatsapp/status': {'linked': false, 'verifiedAt': null},
          'POST /api/v1/whatsapp/link-code': {
            'linkCode': 'ABC123',
            'expiresAt': '2026-07-17T12:10:00Z',
            'instruction': 'Kirim HUBUNGKAN ABC123 melalui WhatsApp.',
          },
        },
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: WhatsAppLinkScreen(
          repository: repository,
          openWhatsApp: (linkCode) async => openedLinkCode = linkCode,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create-whatsapp-link-code')));
    await tester.pumpAndSettle();

    expect(find.text('ABC123'), findsOneWidget);
    expect(find.textContaining('HUBUNGKAN ABC123'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('open-whatsapp-link')));
    await tester.pumpAndSettle();

    expect(openedLinkCode, 'ABC123');
  });
}

class _FakeApi implements ApiTransport {
  _FakeApi({required this.responses});

  final Map<String, Object?> responses;
  Map<String, dynamic>? lastBody;

  @override
  Future<Object?> get(String path) => _response('GET', path);

  @override
  Future<Object?> patch(String path, {Object? body}) {
    lastBody = body as Map<String, dynamic>?;
    return _response('PATCH', path);
  }

  @override
  Future<Object?> post(String path, {Object? body}) {
    lastBody = body as Map<String, dynamic>?;
    return _response('POST', path);
  }

  @override
  Future<Object?> put(String path, {Object? body}) {
    lastBody = body as Map<String, dynamic>?;
    return _response('PUT', path);
  }

  Future<Object?> _response(String method, String path) async {
    final key = '$method $path';
    if (!responses.containsKey(key)) throw StateError('Missing response: $key');
    return responses[key];
  }
}

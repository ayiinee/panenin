import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/features/profile/data/whatsapp_service.dart';
import 'package:panenin/features/profile/presentation/screens/farmer_profile_screen.dart';

void main() {
  test('tautan WhatsApp menormalisasi nomor dan mengisi pesan awal', () {
    final uri = WhatsAppService.buildConnectionUri('+62 812-3456-7890');

    expect(uri.host, 'wa.me');
    expect(uri.path, '/6281234567890');
    expect(
      uri.queryParameters['text'],
      'Halo Panenin, saya ingin menghubungkan akun petani saya.',
    );
  });

  test('tautan WhatsApp mengisi kode penghubung dari backend', () {
    final uri = WhatsAppService.buildConnectionUri(
      '+62 812-3456-7890',
      linkCode: 'abc123',
    );

    expect(uri.queryParameters['text'], 'HUBUNGKAN ABC123');
  });

  testWidgets('aksi WhatsApp membuka halaman penghubung akun', (tester) async {
    await _pumpProfile(tester);
    expect(find.byKey(const ValueKey('profile-guest-avatar')), findsOneWidget);

    final action = find.byKey(const ValueKey('connect-whatsapp-action'));
    await tester.scrollUntilVisible(
      action,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.text('Halaman Hubungkan WhatsApp'), findsOneWidget);
  });

  testWidgets('logout meminta konfirmasi lalu membersihkan navigasi', (
    tester,
  ) async {
    var signedOut = false;
    await _pumpProfile(tester, signOut: () async => signedOut = true);

    final action = find.byKey(const ValueKey('sign-out-action'));
    await tester.scrollUntilVisible(
      action,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.text('Keluar dari akun?'), findsOneWidget);
    expect(signedOut, isFalse);

    await tester.tap(find.widgetWithText(FilledButton, 'Keluar'));
    await tester.pumpAndSettle();

    expect(signedOut, isTrue);
    expect(find.text('Halaman Login'), findsOneWidget);
    expect(find.byType(FarmerProfileScreen), findsNothing);
  });
}

Future<void> _pumpProfile(
  WidgetTester tester, {
  ProfileActionCallback? signOut,
}) async {
  tester.view.physicalSize = const Size(428, 926);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      routes: {
        RouteNames.login: (_) => const Scaffold(body: Text('Halaman Login')),
        RouteNames.whatsapp: (_) =>
            const Scaffold(body: Text('Halaman Hubungkan WhatsApp')),
      },
      home: FarmerProfileScreen(signOut: signOut),
    ),
  );
}

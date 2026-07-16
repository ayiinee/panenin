import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panenin/app/app.dart';
import 'package:panenin/shared/widgets/app_notification_card.dart';

void main() {
  testWidgets('menampilkan informasi utama home petani', (tester) async {
    await _pumpApp(tester);

    expect(find.text('IDR 150.000'), findsOneWidget);
    expect(find.text('Permintaan Baru'), findsOneWidget);
    expect(find.text('Terima Permintaan'), findsOneWidget);
    expect(find.text('Daftar Pesanan Aktif'), findsOneWidget);
    expect(find.text('Tacibay'), findsOneWidget);
    expect(find.text('Rumah Makan Suhat'), findsOneWidget);
    expect(find.text('Warung Tegal Klojen'), findsOneWidget);
    expect(find.text('Warung Swimpit'), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsNothing);

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
  });

  testWidgets('menerima permintaan menampilkan notifikasi lalu menutup kartu', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Terima Permintaan'));
    await tester.pump();

    expect(find.text('Mbak Rina'), findsNothing);
    expect(find.text('Berhasil!'), findsNothing);

    await tester.pump();
    expect(find.text('Berhasil!'), findsOneWidget);
    expect(find.text('Pesanan berhasil diterima.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Berhasil!'), findsNothing);
  });

  testWidgets('menolak permintaan menampilkan notifikasi merah', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Tolak'));
    await tester.pump();

    expect(find.text('Mbak Rina'), findsNothing);
    expect(find.text('Ditolak!'), findsNothing);

    await tester.pump();
    expect(find.text('Ditolak!'), findsOneWidget);
    expect(find.text('Pesanan berhasil ditolak.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('negosiasi tidak menutup permintaan', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Negosiasi'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Mbak Rina'), findsOneWidget);
    expect(find.text('Berhasil!'), findsNothing);
    expect(find.text('Ditolak!'), findsNothing);
  });

  testWidgets('notifikasi responsif pada viewport desktop', (tester) async {
    await _pumpApp(tester, size: const Size(1280, 800));

    await tester.tap(find.text('Terima Permintaan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final notification = find.byType(AppNotificationCard);
    expect(tester.getSize(notification).width, lessThanOrEqualTo(420));
    expect(tester.getTopLeft(notification).dx, greaterThan(800));
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('pesanan aktif responsif pada layar mobile sempit', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(320, 700));

    expect(find.text('Daftar Pesanan Aktif'), findsOneWidget);
    expect(find.text('Warung Swimpit'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -500),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  Size size = const Size(428, 938),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const PaneninApp());
}

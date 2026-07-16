import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panenin/app/app.dart';
import 'package:panenin/shared/widgets/app_notification_card.dart';

void main() {
  testWidgets('menampilkan informasi utama home petani', (tester) async {
    await _pumpApp(tester);

    expect(find.text('IDR 150.000'), findsOneWidget);
    expect(find.text('Alvin!'), findsOneWidget);
    expect(find.text('Permintaan Baru'), findsOneWidget);
    expect(find.text('Terima Permintaan'), findsNWidgets(2));
    expect(find.text('Mbak Rina'), findsOneWidget);
    expect(find.text('Pak Syaiful'), findsOneWidget);
    expect(find.textContaining('Kacang Panjang 15 kg'), findsOneWidget);
    expect(find.text('Daftar Pesanan Aktif'), findsOneWidget);
    expect(find.text('Tacibay'), findsNothing);
    expect(find.text('Rumah Makan Suhat'), findsNothing);
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

    await tester.tap(_inDemand('rina', 'Terima Permintaan'));
    await tester.pump();

    expect(find.text('Mbak Rina'), findsNothing);
    expect(find.text('Pak Syaiful'), findsOneWidget);
    expect(find.text('Berhasil!'), findsNothing);

    await tester.pump();
    expect(find.text('Berhasil!'), findsOneWidget);
    expect(find.text('Pesanan berhasil diterima.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Berhasil!'), findsNothing);
  });

  testWidgets(
    'menolak permintaan perlu konfirmasi lalu menampilkan notifikasi',
    (tester) async {
      await _pumpApp(tester);

      await tester.tap(_inDemand('rina', 'Tolak'));
      await tester.pumpAndSettle();

      expect(find.text('Yakin menolak permintaan?'), findsOneWidget);
      expect(
        find.text('Permintaan kontrak tani dari Mbak Rina akan ditolak.'),
        findsOneWidget,
      );
      expect(find.text('Mbak Rina'), findsOneWidget);

      await tester.tap(find.text('Batalkan'));
      await tester.pumpAndSettle();
      expect(find.text('Mbak Rina'), findsOneWidget);

      await tester.tap(_inDemand('rina', 'Tolak'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjutkan'));
      await tester.pump();

      expect(find.text('Mbak Rina'), findsNothing);
      expect(find.text('Ditolak!'), findsNothing);

      await tester.pump();
      expect(find.text('Ditolak!'), findsOneWidget);
      expect(find.text('Pesanan berhasil ditolak.'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 300));
    },
  );

  testWidgets('negosiasi tidak menutup permintaan', (tester) async {
    await _pumpApp(tester);

    await tester.tap(_inDemand('rina', 'Negosiasi'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Mbak Rina'), findsOneWidget);
    expect(find.text('Berhasil!'), findsNothing);
    expect(find.text('Ditolak!'), findsNothing);
  });

  testWidgets('notifikasi responsif pada viewport desktop', (tester) async {
    await _pumpApp(tester, size: const Size(1280, 800));

    await tester.tap(_inDemand('rina', 'Terima Permintaan'));
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

  testWidgets('detail Warung Tegal maju dua tahap hingga selesai', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _openOrder(tester, 'E841KG');

    expect(find.text('Detail Pesanan'), findsOneWidget);
    expect(find.text('Identitas Penerima'), findsOneWidget);
    expect(find.text('Warung Tegal Klojen'), findsNWidgets(2));
    expect(find.text('Sedia aneka masakan rumahan khas Tegal'), findsOneWidget);
    expect(find.text('Konfirmasi Pengiriman Pesanan'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Sedia aneka masakan rumahan khas Tegal')).dy,
      lessThan(tester.getTopLeft(find.text('Detail Pengiriman')).dy),
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('advance-order')));
    await tester.pump();
    expect(find.text('Konfirmasi Pesanan'), findsOneWidget);
    expect(find.text('Siap Dikirim'), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey('advance-order')));
    await tester.pump();
    expect(find.byKey(const ValueKey('advance-order')), findsNothing);
    expect(find.text('Selesai'), findsNWidgets(2));
  });

  testWidgets('detail Warung Swimpit dimulai dari siap dikirim', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _openOrder(tester, 'E842KG');

    expect(find.text('Warung Swimpit'), findsOneWidget);
    expect(
      find.text('Sedia nasi hangat dan lauk rumahan setiap hari'),
      findsOneWidget,
    );
    expect(find.text('Konfirmasi Pesanan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Finder _inDemand(String id, String label) {
  return find.descendant(
    of: find.byKey(ValueKey('demand-$id')),
    matching: find.text(label),
  );
}

Finder _inOrder(String code, String label) {
  return find.descendant(
    of: find.byKey(ValueKey('active-order-$code')),
    matching: find.text(label),
  );
}

Future<void> _openOrder(WidgetTester tester, String code) async {
  final detailButton = _inOrder(code, 'Lihat Detail');
  await tester.scrollUntilVisible(
    detailButton,
    400,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(detailButton);
  await tester.pumpAndSettle();
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

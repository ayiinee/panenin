import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panenin/app/app.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/app/shell/farmer_shell.dart';
import 'package:panenin/app/shell/panenin_bottom_navigation.dart';
import 'package:panenin/app/theme/app_colors.dart';
import 'package:panenin/app/theme/app_theme.dart';
import 'package:panenin/core/network/api_client.dart';
import 'package:panenin/features/auth/data/models/authenticated_user.dart';
import 'package:panenin/features/auth/data/models/email_sign_up_result.dart';
import 'package:panenin/features/auth/domain/user_role.dart';
import 'package:panenin/features/auth/presentation/screens/create_account_screen.dart';
import 'package:panenin/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:panenin/features/auth/presentation/screens/login_screen.dart';
import 'package:panenin/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:panenin/features/auth/presentation/screens/select_role_screen.dart';
import 'package:panenin/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:panenin/features/auth/presentation/widgets/google_auth_button.dart';
import 'package:panenin/features/home/presentation/screens/buyer_home_screen.dart';
import 'package:panenin/features/home/presentation/widgets/active_orders_section.dart';
import 'package:panenin/features/marketplace/presentation/screens/product_detail_screen.dart';
import 'package:panenin/features/marketplace/presentation/screens/negotiation_chat_screen.dart';
import 'package:panenin/features/messages/presentation/screens/buyer_messages_screen.dart';
import 'package:panenin/features/marketplace/presentation/screens/recurring_supply_screen.dart';
import 'package:panenin/features/orders/presentation/screens/buyer_orders_screen.dart';
import 'package:panenin/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:panenin/features/profile/data/profile_repository.dart';
import 'package:panenin/features/profile/presentation/screens/farmer_profile_screen.dart';
import 'package:panenin/features/home/presentation/screens/farmer_home_screen.dart';
import 'package:panenin/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:panenin/features/orders/presentation/screens/manage_orders_screen.dart';
import 'package:panenin/features/profile/presentation/screens/buyer_profile_screen.dart';
import 'package:panenin/features/quick_sell/presentation/screens/quick_sell_camera_screen.dart';
import 'package:panenin/features/stock/domain/stock_item.dart';
import 'package:panenin/features/stock/presentation/screens/stock_form_screen.dart';
import 'package:panenin/features/stock/presentation/screens/stock_screen.dart';
import 'package:panenin/shared/widgets/app_notification_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('route utama mengikuti nama branch UI', () {
    expect(RouteNames.homePetani, '/beranda');
    expect(RouteNames.farmerProfile, '/petani/profile');
    expect(RouteNames.kelolaPesanan, '/kelola-pesanan');
    expect(RouteNames.detailPesanan, '/detail-pesanan');
    expect(RouteNames.stokSaya, '/stok');
    expect(RouteNames.fotoJualCepat, '/jual-cepat/foto');
    expect(RouteNames.formStok, '/stok/form');
    expect(
      buildAppRoutes().keys,
      containsAll([
        RouteNames.homePetani,
        RouteNames.farmerProfile,
        RouteNames.buyerMessages,
        RouteNames.kelolaPesanan,
        RouteNames.detailPesanan,
        RouteNames.stokSaya,
        RouteNames.fotoJualCepat,
        RouteNames.formStok,
      ]),
    );
  });

  testWidgets('menampilkan informasi utama home petani', (tester) async {
    await _pumpApp(tester);

    expect(find.text('IDR 150.000'), findsOneWidget);
    expect(find.text('Alvin!'), findsOneWidget);
    expect(
      tester.getCenter(find.byKey(const ValueKey('home-message-icon'))).dy,
      closeTo(
        tester.getCenter(find.byKey(const ValueKey('home-guest-avatar'))).dy,
        1,
      ),
    );
    expect(find.byKey(const ValueKey('home-guest-avatar')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-guest-pill')),
        matching: find.byKey(const ValueKey('home-guest-avatar')),
      ),
      findsOneWidget,
    );
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
    final orderCard = tester.widget<Container>(
      find.byKey(const ValueKey('order-card-surface-E841KG')),
    );
    final orderDecoration = orderCard.decoration! as BoxDecoration;
    expect(orderDecoration.color, Colors.white);
    expect(orderDecoration.border, isNull);
    expect(
      tester.widget<Text>(find.text('Kacang Panjang')).style?.fontSize,
      13,
    );
    expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    for (final label in const ['Terima Permintaan', 'Negosiasi', 'Tolak']) {
      final button = tester.widget<FilledButton>(
        find
            .ancestor(of: find.text(label), matching: find.byType(FilledButton))
            .first,
      );
      expect(button.style?.textStyle?.resolve({})?.fontWeight, FontWeight.w700);
    }
    expect(
      demoOrders.singleWhere((order) => order.code == 'E841KG').statusColor,
      AppColors.danger,
    );

    final detailButton = find.ancestor(
      of: _inOrder('E841KG', 'Lihat Detail'),
      matching: find.byType(OutlinedButton),
    );
    expect(
      tester.getBottomRight(detailButton).dy,
      lessThanOrEqualTo(
        tester.getBottomRight(find.text('Kirim: 13 Juli 2026')).dy,
      ),
    );

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
      final cancelButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('cancel-reject-request')),
      );
      expect(cancelButton.style?.backgroundColor?.resolve({}), Colors.white);
      expect(
        cancelButton.style?.foregroundColor?.resolve({}),
        AppColors.danger,
      );
      expect(cancelButton.style?.side?.resolve({})?.color, AppColors.danger);
      expect(
        tester
            .widget<Dialog>(find.byKey(const ValueKey('reject-request-dialog')))
            .backgroundColor,
        Colors.white,
      );

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
    expect(
      ModalRoute.settingsOf(
        tester.element(find.byType(OrderDetailScreen)),
      )!.name,
      RouteNames.detailPesanan,
    );
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

  testWidgets('lihat semua membuka kelola pesanan dengan empat kategori', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.scrollUntilVisible(
      find.text('Lihat Semua').last,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Lihat Semua').last);
    await tester.pumpAndSettle();

    expect(find.byType(ManageOrdersScreen), findsOneWidget);
    expect(find.text('Kelola Pesanan'), findsOneWidget);
    expect(
      ModalRoute.settingsOf(
        tester.element(find.byType(ManageOrdersScreen)),
      )!.name,
      RouteNames.kelolaPesanan,
    );
    expect(find.text('Pesanan Aktif'), findsOneWidget);
    expect(tester.widget<Text>(find.text('Tomat')).style?.fontSize, 13);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('active-order-progress-line')))
          .width,
      greaterThan(300),
    );
    expect(find.byKey(const ValueKey('order-filter-all')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('order-filter-awaitingPayment')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('order-filter-processing')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('order-filter-completed')),
      findsOneWidget,
    );
  });

  testWidgets('filter pesanan dan detail selesai dapat kembali ke kelola', (
    tester,
  ) async {
    await _pumpManageOrders(tester);

    expect(find.byKey(const ValueKey('managed-order-E839KG')), findsOneWidget);
    expect(find.byKey(const ValueKey('managed-order-E842KG')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('order-filter-completed')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('managed-order-E839KG')), findsOneWidget);
    expect(find.byKey(const ValueKey('managed-order-E840KG')), findsOneWidget);
    expect(find.byKey(const ValueKey('managed-order-E841KG')), findsNothing);
    expect(find.byKey(const ValueKey('managed-order-E842KG')), findsNothing);

    final manageTitleTop = tester.getTopLeft(find.text('Kelola Pesanan')).dy;

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('managed-order-E839KG')),
        matching: find.text('Lihat Detail'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detail Pesanan'), findsOneWidget);
    expect(find.text('Tacibay'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('advance-order')), findsNothing);
    expect(find.byType(PaneninBottomNavigation), findsNothing);
    expect(
      tester.getTopLeft(find.text('Detail Pesanan')).dy,
      closeTo(manageTitleTop, 0.1),
    );

    await tester.tap(find.byKey(const ValueKey('detail-back')));
    await tester.pumpAndSettle();
    expect(find.byType(ManageOrdersScreen), findsOneWidget);
  });

  testWidgets('empat kategori pesanan sejajar pada layar sempit', (
    tester,
  ) async {
    await _pumpManageOrders(tester, size: const Size(320, 700));

    final filters = [
      for (final name in const [
        'all',
        'awaitingPayment',
        'processing',
        'completed',
      ])
        find.byKey(ValueKey('order-filter-$name')),
    ];
    final centerY = tester.getCenter(filters.first).dy;

    for (final filter in filters.skip(1)) {
      expect(tester.getCenter(filter).dy, closeTo(centerY, 0.1));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('navbar stok membuka halaman stok dan form tanpa navbar', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Stok'));
    await tester.pumpAndSettle();

    expect(find.byType(StockScreen), findsOneWidget);
    expect(find.text('Stok Saya'), findsOneWidget);
    expect(find.text('3 Produk  •  22 Kg tersedia'), findsOneWidget);
    expect(
      ModalRoute.settingsOf(tester.element(find.byType(StockScreen)))!.name,
      RouteNames.stokSaya,
    );

    await tester.tap(find.byKey(const ValueKey('add-stock')));
    await tester.pumpAndSettle();

    expect(find.byType(StockFormScreen), findsOneWidget);
    expect(find.byType(PaneninBottomNavigation), findsNothing);
    expect(find.text('Isi dan Jumlah Harga'), findsOneWidget);
    expect(find.byType(Image), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('stock-name-field')),
      'Bayam',
    );
    await tester.enterText(
      find.byKey(const ValueKey('stock-price-field')),
      '12000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('stock-quantity-field')),
      '25',
    );
    await tester.tap(find.byKey(const ValueKey('save-stock')));
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi Inventaris'), findsOneWidget);
    expect(find.text('Bayam'), findsNWidgets(2));
    expect(find.text('25 Kg'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-inventory')));
    await tester.pumpAndSettle();

    expect(find.byType(StockScreen), findsOneWidget);
    expect(find.text('Bayam'), findsOneWidget);
    expect(find.text('4 Produk  •  47 Kg tersedia'), findsOneWidget);
  });

  testWidgets('farmer shell berpindah ke seluruh tab tanpa menumpuk route', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const FarmerShell()),
    );

    await tester.tap(find.text('Stok'));
    await tester.pump();
    expect(find.text('Stok Saya'), findsOneWidget);

    await tester.tap(find.text('Pesanan'));
    await tester.pump();
    expect(find.text('Kelola Pesanan'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pump();
    expect(find.byType(FarmerProfileScreen), findsOneWidget);
    expect(find.text('Profile Petani'), findsOneWidget);

    await tester.tap(find.text('Beranda'));
    await tester.pump();
    expect(find.text('Permintaan Baru'), findsOneWidget);
    expect(find.byType(PaneninBottomNavigation), findsOneWidget);
  });

  testWidgets('form stok menampilkan error inline sebelum membuka modal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(428, 938);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: StockFormScreen()));

    await tester.ensureVisible(find.byKey(const ValueKey('save-stock')));
    await tester.tap(find.byKey(const ValueKey('save-stock')));
    await tester.pump();

    expect(find.text('Nama produk wajib diisi.'), findsOneWidget);
    expect(find.text('Harga jual wajib diisi.'), findsOneWidget);
    expect(find.text('Jumlah stok wajib diisi.'), findsOneWidget);
    expect(find.text('Konfirmasi Inventaris'), findsNothing);
  });

  testWidgets('jual cepat membuka kamera tanpa tombol galeri', (tester) async {
    tester.view.physicalSize = const Size(428, 938);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          RouteNames.fotoJualCepat: (_) => QuickSellCameraScreen(
            initializeCamera: () async => throw CameraException(
              'CameraAccessDenied',
              'Permission denied for test',
            ),
          ),
          RouteNames.homePetani: (_) => const FarmerShell(),
        },
        home: const Scaffold(bottomNavigationBar: PaneninBottomNavigation()),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('quick-sell-camera')));
    await tester.pumpAndSettle();

    expect(find.byType(QuickSellCameraScreen), findsOneWidget);
    expect(find.text('Foto Produk Anda!'), findsOneWidget);
    expect(find.byKey(const ValueKey('camera-header-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('camera-back')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('camera-back'))).dx,
      tester.getTopLeft(find.byKey(const ValueKey('camera-header-panel'))).dx,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('camera-back-icon'))).dx -
          tester
              .getTopLeft(find.byKey(const ValueKey('camera-header-panel')))
              .dx,
      inInclusiveRange(12, 20),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('camera-back'))).dy,
      lessThan(tester.getCenter(find.text('Foto Produk Anda!')).dy),
    );
    expect(find.byKey(const ValueKey('take-picture')), findsOneWidget);
    expect(find.byKey(const ValueKey('toggle-flash')), findsOneWidget);
    expect(find.text('Flash'), findsOneWidget);
    expect(find.text('Galeri'), findsNothing);
    final previewSize = tester.getSize(
      find.byKey(const ValueKey('camera-square-preview')),
    );
    expect(previewSize.width, previewSize.height);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('take-picture'))).dy,
      greaterThanOrEqualTo(
        tester
            .getBottomLeft(find.byKey(const ValueKey('camera-square-preview')))
            .dy,
      ),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('camera-controls-panel')),
        matching: find.byKey(const ValueKey('take-picture')),
      ),
      findsOneWidget,
    );
    expect(
      find.text('Izin kamera diperlukan untuk memotret produk.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('camera-back')));
    await tester.pumpAndSettle();
    expect(find.byType(QuickSellCameraScreen), findsNothing);
    expect(find.byType(FarmerShell), findsOneWidget);
  });

  testWidgets('hasil foto jual cepat dipotong menjadi rasio 1:1', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, 8, 4),
        ui.Paint()..color = Colors.red,
      );
      final source = await recorder.endRecording().toImage(8, 4);
      final sourceData = await source.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final squareBytes = await cropImageToSquare(
        sourceData!.buffer.asUint8List(),
      );
      final codec = await ui.instantiateImageCodec(squareBytes);
      final frame = await codec.getNextFrame();

      expect(frame.image.width, frame.image.height);
      expect(frame.image.width, 4);

      frame.image.dispose();
      codec.dispose();
      source.dispose();
    });
  });

  testWidgets('foto jual cepat masuk ke form lalu tampil pada stok', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(428, 938);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final photoPath = File('assets/images/stock/red_chili.png').absolute.path;

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          RouteNames.fotoJualCepat: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const ValueKey('fake-take-picture'),
                onPressed: () => Navigator.of(context).pop(photoPath),
                child: const Text('Ambil Foto'),
              ),
            ),
          ),
          RouteNames.formStok: (context) => StockFormScreen(
            capturedPhotoPath:
                ModalRoute.settingsOf(context)!.arguments! as String,
          ),
          RouteNames.stokSaya: (context) => StockScreen(
            initialItem:
                ModalRoute.settingsOf(context)!.arguments! as StockItem,
          ),
        },
        home: const Scaffold(bottomNavigationBar: PaneninBottomNavigation()),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('quick-sell-camera')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('fake-take-picture')));
    await tester.pumpAndSettle();

    expect(find.byType(StockFormScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('captured-stock-photo')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('stock-name-field')),
      'Buncis',
    );
    await tester.enterText(
      find.byKey(const ValueKey('stock-price-field')),
      '14000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('stock-quantity-field')),
      '8',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('save-stock')));
    await tester.tap(find.byKey(const ValueKey('save-stock')));
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi Inventaris'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-inventory')));
    await tester.pumpAndSettle();

    expect(find.byType(StockScreen), findsOneWidget);
    expect(find.text('Buncis'), findsOneWidget);
    expect(find.byKey(const ValueKey('stock-file-photo')), findsOneWidget);
  });

  testWidgets('tiga titik vertikal membuka edit stok produk', (tester) async {
    await _pumpStock(tester);

    expect(find.byIcon(Icons.more_vert_rounded), findsWidgets);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    final card = tester.widget<Container>(
      find.byKey(const ValueKey('stock-card-surface-cabai-merah')),
    );
    final decoration = card.decoration! as BoxDecoration;
    expect(decoration.color, Colors.white);
    expect(decoration.border, isNull);
    for (final field in const ['quantity', 'price', 'status']) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey('stock-$field-cabai-merah')),
          matching: find.byType(Container),
        ),
        findsNothing,
      );
    }
    final quantityY = tester
        .getTopLeft(find.byKey(const ValueKey('stock-quantity-cabai-merah')))
        .dy;
    final priceY = tester
        .getTopLeft(find.byKey(const ValueKey('stock-price-cabai-merah')))
        .dy;
    final statusY = tester
        .getTopLeft(find.byKey(const ValueKey('stock-status-cabai-merah')))
        .dy;
    expect(quantityY, lessThan(priceY));
    expect(priceY, lessThan(statusY));
    expect(
      tester
          .getBottomRight(
            find.byKey(const ValueKey('stock-status-cabai-merah')),
          )
          .dy,
      closeTo(
        tester
            .getBottomRight(
              find.byKey(const ValueKey('stock-image-cabai-merah')),
            )
            .dy,
        1,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('edit-stock-cabai-merah')));
    await tester.pumpAndSettle();

    expect(find.byType(StockFormScreen), findsOneWidget);
    expect(find.byType(PaneninBottomNavigation), findsNothing);
    expect(find.text('12'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('stock-quantity-field')),
      '20',
    );
    await tester.tap(find.byKey(const ValueKey('save-stock')));
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi Inventaris'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-inventory')));
    await tester.pumpAndSettle();

    expect(find.byType(StockScreen), findsOneWidget);
    expect(find.text('20Kg'), findsOneWidget);
    expect(find.text('Ubah Stok'), findsNothing);
    expect(find.text('Ubah Harga'), findsNothing);
    expect(find.text('Jual'), findsNothing);
  });

  testWidgets('batch melewati umur simpan menampilkan kartu peringatan', (
    tester,
  ) async {
    await _pumpStock(tester);

    expect(find.text('Perlu Ditinjau'), findsOneWidget);
    expect(find.textContaining('Melewati umur simpan 3 hari'), findsOneWidget);

    final card = tester.widget<Container>(
      find.byKey(const ValueKey('stock-card-surface-kacang-panjang')),
    );
    final decoration = card.decoration! as BoxDecoration;
    expect(decoration.border!.top.color, AppColors.danger);
  });

  const demoUser = AuthenticatedUser(
    id: '11111111-1111-1111-1111-111111111111',
    email: 'demo@panenin.id',
    name: 'Demo Panenin',
    provider: 'email',
  );

  const demoFarmer = AuthenticatedUser(
    id: '22222222-2222-2222-2222-222222222222',
    email: 'petani@panenin.id',
    name: 'Pak Ferdi',
    provider: 'email',
    role: UserRole.farmer,
  );

  testWidgets('renders correctly typed create account fields', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreateAccountScreen()));

    expect(find.text('Buat Akun Anda'), findsOneWidget);
    expect(find.text('Nama Pengguna'), findsOneWidget);
    expect(find.text('Alamat Email'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('Konfirmasi Kata Sandi'), findsOneWidget);
    expect(find.byType(GoogleAuthButton), findsOneWidget);

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields, hasLength(4));
    expect(fields[0].obscureText, isFalse);
    expect(fields[0].textCapitalization, TextCapitalization.words);
    expect(fields[1].obscureText, isFalse);
    expect(fields[1].keyboardType, TextInputType.emailAddress);
    expect(fields[2].obscureText, isTrue);
    expect(fields[3].obscureText, isTrue);
    expect(fields[3].textInputAction, TextInputAction.done);
  });

  testWidgets('aplikasi dimulai dari halaman login', (tester) async {
    await tester.pumpWidget(const PaneninApp());

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(CreateAccountScreen), findsNothing);
    expect(find.byType(SelectRoleScreen), findsNothing);
  });

  testWidgets('renders the role selection screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SelectRoleScreen()));

    expect(find.byType(SelectRoleScreen), findsOneWidget);
    expect(find.textContaining('Halo!'), findsOneWidget);
    expect(find.text('Saya ingin menjual\nhasil panen'), findsOneWidget);
    expect(find.text('Saya ingin membeli\nhasil panen'), findsOneWidget);
    expect(find.text('Jual Hasil Panen'), findsOneWidget);
    expect(find.text('Beli Hasil Panen'), findsOneWidget);

    final farmerButton = tester.widget<Material>(
      find.byKey(const ValueKey('farmer-role-button')),
    );
    final buyerButton = tester.widget<Material>(
      find.byKey(const ValueKey('buyer-role-button')),
    );
    expect(farmerButton.color, AppColors.primary);
    expect(buyerButton.color, AppColors.accent);
    expect(
      tester.getSize(find.byKey(const ValueKey('farmer-role-button'))).height,
      greaterThanOrEqualTo(44),
    );

    final farmerCard = tester.getRect(
      find.byKey(const ValueKey('farmer-role-card')),
    );
    final buyerCard = tester.getRect(
      find.byKey(const ValueKey('buyer-role-card')),
    );
    final farmerImage = tester.getRect(
      find.byKey(const ValueKey('farmer-role-image')),
    );
    final buyerImage = tester.getRect(
      find.byKey(const ValueKey('buyer-role-image')),
    );

    expect(farmerCard.height, 205);
    expect(buyerCard.height, 205);
    expect(farmerImage.top, farmerCard.top);
    expect(farmerImage.bottom, farmerCard.bottom);
    expect(buyerImage.top, buyerCard.top);
    expect(buyerImage.bottom, buyerCard.bottom);
    expect(buyerCard.top, greaterThan(farmerCard.bottom));
  });

  testWidgets('farmer role continues to farmer profile setup', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          RouteNames.profile: (context) => ProfileSetupScreen(
            role: ModalRoute.of(context)!.settings.arguments! as UserRole,
          ),
        },
        home: const SelectRoleScreen(),
      ),
    );

    final farmerAction = find.text('Jual Hasil Panen');
    await tester.ensureVisible(farmerAction);
    await tester.tap(farmerAction);
    await tester.pumpAndSettle();

    expect(find.byType(ProfileSetupScreen), findsOneWidget);
    expect(find.text('Nama Petani'), findsOneWidget);
    expect(find.text('Komoditas Penjualan'), findsOneWidget);
  });

  testWidgets('buyer role continues to UMKM profile setup', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          RouteNames.profile: (context) => ProfileSetupScreen(
            role: ModalRoute.of(context)!.settings.arguments! as UserRole,
          ),
        },
        home: const SelectRoleScreen(),
      ),
    );

    final buyerAction = find.text('Beli Hasil Panen');
    await tester.ensureVisible(buyerAction);
    await tester.tap(buyerAction);
    await tester.pumpAndSettle();

    expect(find.byType(ProfileSetupScreen), findsOneWidget);
    expect(find.text('Nama Pengguna'), findsOneWidget);
    expect(find.text('Kategori Produk UMKM'), findsOneWidget);
  });

  testWidgets('registration validates required fields before Supabase', (
    tester,
  ) async {
    var called = false;
    await tester.pumpWidget(
      MaterialApp(
        home: CreateAccountScreen(
          emailSignUp: (name, email, password) async {
            called = true;
            return const EmailSignUpResult(requiresEmailVerification: true);
          },
        ),
      ),
    );

    await tester.ensureVisible(find.text('Daftarkan Akun'));
    await tester.tap(find.text('Daftarkan Akun'));
    await tester.pump();

    expect(called, isFalse);
    expect(find.text('Nama pengguna wajib diisi.'), findsOneWidget);
  });

  testWidgets('email registration opens verification instructions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: CreateAccountScreen(
          emailSignUp: (name, email, password) async {
            expect(name, 'Demo Panenin');
            expect(email, 'demo@panenin.id');
            expect(password, 'password123');
            return const EmailSignUpResult(requiresEmailVerification: true);
          },
        ),
      ),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), ' Demo Panenin ');
    await tester.enterText(fields.at(1), 'DEMO@PANENIN.ID');
    await tester.enterText(fields.at(2), 'password123');
    await tester.enterText(fields.at(3), 'password123');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.ensureVisible(find.text('Daftarkan Akun'));
    await tester.tap(find.text('Daftarkan Akun'));
    await tester.pumpAndSettle();

    expect(find.byType(VerifyEmailScreen), findsOneWidget);
    expect(find.text('demo@panenin.id'), findsOneWidget);
  });

  testWidgets('Google registration validates the returned user', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        routes: {RouteNames.selectRole: (_) => const SelectRoleScreen()},
        home: CreateAccountScreen(googleSignIn: () async => demoUser),
      ),
    );

    final googleButton = find.byType(GoogleAuthButton);
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await tester.pumpAndSettle();

    expect(find.byType(SelectRoleScreen), findsOneWidget);
  });

  testWidgets('login screen is separate and navigable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        routes: {'/login': (_) => const LoginScreen()},
        home: const CreateAccountScreen(),
      ),
    );

    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Selamat Datang Kembali'), findsOneWidget);
  });

  testWidgets('email and password login validates with the backend user', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {RouteNames.selectRole: (_) => const SelectRoleScreen()},
        home: LoginScreen(
          emailSignIn: (email, password) async {
            expect(email, 'demo@panenin.id');
            expect(password, 'password123');
            return demoUser;
          },
        ),
      ),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'DEMO@PANENIN.ID');
    await tester.enterText(fields.at(1), 'password123');
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.byType(SelectRoleScreen), findsOneWidget);
  });

  testWidgets('akun dengan role petani langsung masuk ke home petani', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {RouteNames.homePetani: (_) => const FarmerShell()},
        home: LoginScreen(emailSignIn: (_, _) async => demoFarmer),
      ),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'petani@panenin.id');
    await tester.enterText(fields.at(1), 'password123');
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.byType(FarmerShell), findsOneWidget);
    expect(find.byType(FarmerHomeScreen), findsOneWidget);
    expect(find.text('Permintaan Baru'), findsOneWidget);
  });

  testWidgets('login tanpa role melanjutkan ke pengisian profil petani', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          RouteNames.selectRole: (context) => SelectRoleScreen(
            flow:
                ModalRoute.settingsOf(context)!.arguments! as RoleSelectionFlow,
          ),
          RouteNames.profile: (context) => ProfileSetupScreen(
            role: ModalRoute.settingsOf(context)!.arguments! as UserRole,
          ),
        },
        home: LoginScreen(emailSignIn: (_, _) async => demoUser),
      ),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'demo@panenin.id');
    await tester.enterText(fields.at(1), 'password123');
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Jual Hasil Panen'));
    await tester.tap(find.text('Jual Hasil Panen'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileSetupScreen), findsOneWidget);
    expect(find.text('Nama Petani'), findsOneWidget);
  });

  testWidgets('forgot password sends a privacy-safe response', (tester) async {
    String? requestedEmail;
    await tester.pumpWidget(
      MaterialApp(
        home: ForgotPasswordScreen(
          sendPasswordReset: (email) async => requestedEmail = email,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'DEMO@PANENIN.ID');
    await tester.tap(find.text('Kirim Tautan Pemulihan'));
    await tester.pumpAndSettle();

    expect(requestedEmail, 'demo@panenin.id');
    expect(
      find.text('Jika email terdaftar, tautan pemulihan akan segera dikirim.'),
      findsOneWidget,
    );
  });

  testWidgets('password recovery event opens the reset screen', (tester) async {
    final authEvents = StreamController<AuthState>();
    addTearDown(authEvents.close);
    await tester.pumpWidget(PaneninApp(authEvents: authEvents.stream));

    authEvents.add(const AuthState(AuthChangeEvent.passwordRecovery, null));
    await tester.pumpAndSettle();

    expect(find.byType(ResetPasswordScreen), findsOneWidget);
  });

  testWidgets('reset password rejects a mismatched confirmation', (
    tester,
  ) async {
    var called = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ResetPasswordScreen(
          updatePassword: (password) async => called = true,
        ),
      ),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'password123');
    await tester.enterText(fields.at(1), 'different123');
    await tester.ensureVisible(find.text('Simpan Kata Sandi'));
    await tester.tap(find.text('Simpan Kata Sandi'));
    await tester.pump();

    expect(called, isFalse);
    expect(find.text('Konfirmasi kata sandi tidak sama.'), findsOneWidget);
  });

  testWidgets('reset password succeeds and returns to login', (tester) async {
    String? updatedPassword;
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: RouteNames.resetPassword,
        routes: {
          RouteNames.resetPassword: (_) => ResetPasswordScreen(
            updatePassword: (password) async => updatedPassword = password,
          ),
          RouteNames.login: (_) => const Scaffold(body: Text('Halaman Masuk')),
        },
      ),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'password123');
    await tester.enterText(fields.at(1), 'password123');
    await tester.ensureVisible(find.text('Simpan Kata Sandi'));
    await tester.tap(find.text('Simpan Kata Sandi'));
    await tester.pumpAndSettle();

    expect(updatedPassword, 'password123');
    expect(find.text('Halaman Masuk'), findsOneWidget);
  });

  testWidgets('Google login shows the backend-validated user', (tester) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        routes: {RouteNames.selectRole: (_) => const SelectRoleScreen()},
        home: LoginScreen(googleSignIn: () async => demoUser),
      ),
    );

    final googleButton = find.byType(GoogleAuthButton);
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await tester.pumpAndSettle();

    expect(find.byType(SelectRoleScreen), findsOneWidget);
  });

  testWidgets('Google login failure gives actionable feedback', (tester) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          googleSignIn: () async => throw Exception('Sesi ditolak backend.'),
        ),
      ),
    );

    final googleButton = find.byType(GoogleAuthButton);
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await tester.pumpAndSettle();

    expect(find.text('Login Google gagal. Silakan coba lagi'), findsOneWidget);
  });

  testWidgets('role selection adapts to a narrow screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: SelectRoleScreen()));

    expect(tester.takeException(), isNull);
    expect(find.text('Beli Hasil Panen'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('farmer-role-button'))).height,
      greaterThanOrEqualTo(44),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('buyer-role-button'))).height,
      greaterThanOrEqualTo(44),
    );
  });

  testWidgets('role cards are accessible and entirely tappable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          RouteNames.profile: (context) => ProfileSetupScreen(
            role: ModalRoute.of(context)!.settings.arguments! as UserRole,
          ),
        },
        home: const SelectRoleScreen(),
      ),
    );

    expect(
      find.bySemanticsLabel(
        'Pilih peran petani. Menjual hasil panen kepada UMKM.',
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('buyer-role-card')));
    await tester.tap(find.byKey(const ValueKey('buyer-role-card')));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileSetupScreen), findsOneWidget);
    expect(find.text('Kategori Produk UMKM'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('role selection supports landscape and large text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MaterialApp(home: SelectRoleScreen()),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const ValueKey('buyer-role-card')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('registration continues through role to farmer profile setup', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          RouteNames.selectRole: (_) => const SelectRoleScreen(),
          RouteNames.profile: (context) => ProfileSetupScreen(
            role: ModalRoute.of(context)!.settings.arguments! as UserRole,
          ),
        },
        home: CreateAccountScreen(
          emailSignUp: (name, email, password) async => const EmailSignUpResult(
            requiresEmailVerification: false,
            user: demoUser,
          ),
        ),
      ),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Demo Panenin');
    await tester.enterText(fields.at(1), 'demo@panenin.id');
    await tester.enterText(fields.at(2), 'password123');
    await tester.enterText(fields.at(3), 'password123');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.ensureVisible(find.text('Daftarkan Akun'));
    await tester.tap(find.text('Daftarkan Akun'));
    await tester.pumpAndSettle();

    expect(find.byType(SelectRoleScreen), findsOneWidget);
    await tester.ensureVisible(find.text('Jual Hasil Panen'));
    await tester.tap(find.text('Jual Hasil Panen'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileSetupScreen), findsOneWidget);
    expect(find.text('Silahkan Isi Data Diri Anda'), findsOneWidget);
    expect(find.text('Daftar Sekarang'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('profile-submit-button')))
          .height,
      54,
    );
  });

  testWidgets('registration continues through role to UMKM profile setup', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          RouteNames.selectRole: (_) => const SelectRoleScreen(),
          RouteNames.profile: (context) => ProfileSetupScreen(
            role: ModalRoute.of(context)!.settings.arguments! as UserRole,
          ),
        },
        home: CreateAccountScreen(
          emailSignUp: (name, email, password) async => const EmailSignUpResult(
            requiresEmailVerification: false,
            user: demoUser,
          ),
        ),
      ),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Demo Panenin');
    await tester.enterText(fields.at(1), 'demo@panenin.id');
    await tester.enterText(fields.at(2), 'password123');
    await tester.enterText(fields.at(3), 'password123');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.ensureVisible(find.text('Daftarkan Akun'));
    await tester.tap(find.text('Daftarkan Akun'));
    await tester.pumpAndSettle();

    expect(find.byType(SelectRoleScreen), findsOneWidget);
    await tester.ensureVisible(find.text('Beli Hasil Panen'));
    await tester.tap(find.text('Beli Hasil Panen'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileSetupScreen), findsOneWidget);
    expect(find.text('Nama Pengguna'), findsOneWidget);
    expect(find.text('Kategori Produk UMKM'), findsOneWidget);
    expect(find.text('Nama Bisnis (Opsional)'), findsOneWidget);
    expect(find.text('Masukkan nama bisnis'), findsOneWidget);
  });

  testWidgets('buyer profile continues to the buyer home', (tester) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        routes: {RouteNames.buyerHome: (_) => const BuyerHomeScreen()},
        home: const ProfileSetupScreen(role: UserRole.buyer),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('buyer-name-field')),
      'Mbak Ani',
    );
    await tester.enterText(
      find.byKey(const ValueKey('address-field')),
      'Ambarawa, Jawa Tengah',
    );
    await tester.tap(find.text('Tomat'));
    await tester.tap(find.byKey(const ValueKey('terms-row')));
    await tester.tap(find.text('Daftar Sekarang'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    expect(find.byType(BuyerHomeScreen), findsOneWidget);
    expect(find.text('Komoditas Cepat'), findsOneWidget);
  });

  testWidgets('buyer home renders the Figma content and large tap targets', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: BuyerHomeScreen()));

    expect(find.text('Lokasi Anda'), findsOneWidget);
    expect(find.text('Malang, Jawa Timur'), findsOneWidget);
    expect(find.text('Pasokan rutin,\nusaha makin pasti'), findsOneWidget);
    expect(find.text('Cabai Merah Kering'), findsOneWidget);
    expect(find.text('Rp 49.500'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Maps'), findsNothing);
    expect(find.byKey(const ValueKey('messages-navigation')), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('find-commodities-button')))
          .height,
      greaterThanOrEqualTo(44),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('pencarian buyer memvalidasi input sebelum mencari', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: BuyerHomeScreen()));

    final search = find.byKey(const ValueKey('buyer-home-search'));
    await tester.tap(search);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(find.text('Masukkan komoditas yang ingin dicari.'), findsOneWidget);

    await tester.enterText(search, ' Tomat ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(find.text('Mencari Tomat...'), findsOneWidget);
  });

  testWidgets('buyer home supports loading, empty, and error states', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BuyerHomeScreen(state: BuyerHomeViewState.loading),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(home: BuyerHomeScreen(state: BuyerHomeViewState.empty)),
    );
    expect(find.text('Komoditas belum tersedia'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(home: BuyerHomeScreen(state: BuyerHomeViewState.error)),
    );
    expect(find.text('Gagal memuat beranda'), findsOneWidget);
  });

  testWidgets('transaction navigation opens the buyer orders page', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          RouteNames.buyerHome: (_) => const BuyerHomeScreen(),
          RouteNames.buyerOrders: (_) => const BuyerOrdersScreen(),
        },
        home: const BuyerHomeScreen(),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('transactions-navigation')));
    await tester.pumpAndSettle();

    expect(find.byType(BuyerOrdersScreen), findsOneWidget);
    expect(find.text('Pesananku'), findsOneWidget);
    expect(find.text('Tomat Segar'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-navigation')));
    await tester.pumpAndSettle();
    expect(find.byType(BuyerHomeScreen), findsOneWidget);
  });

  testWidgets('buyer orders follows the Figma layout and switches tabs', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: BuyerOrdersScreen()));

    expect(find.text('Kacang Panjang'), findsOneWidget);
    expect(find.text('Rp 250.000'), findsWidgets);
    expect(find.text('Transaksi'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('active-orders-tab')))
          .flagsCollection
          .isSelected,
      ui.Tristate.isTrue,
    );
    await tester.tap(find.byKey(const ValueKey('order-history-tab')));
    await tester.pump();
    expect(find.text('Cabai Merah'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('order-history-tab')))
          .flagsCollection
          .isSelected,
      ui.Tristate.isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('buyer orders supports loading, empty, and error states', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BuyerOrdersScreen(state: BuyerOrdersViewState.loading),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: BuyerOrdersScreen(state: BuyerOrdersViewState.empty),
      ),
    );
    expect(find.text('Belum ada pesanan'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: BuyerOrdersScreen(state: BuyerOrdersViewState.error),
      ),
    );
    expect(find.text('Gagal memuat pesanan'), findsOneWidget);
  });

  testWidgets('buyer orders handles empty success data on both tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BuyerOrdersScreen(orders: [], historyOrders: []),
      ),
    );

    expect(find.text('Belum ada pesanan'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('order-history-tab')));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada riwayat pesanan'), findsOneWidget);
  });

  testWidgets('buyer profile renders procurement-focused content', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: BuyerProfileScreen()));

    expect(find.text('Profil Usaha'), findsOneWidget);
    expect(find.text('Dapur Bu Ani'), findsOneWidget);
    expect(find.text('Buyer terverifikasi'), findsOneWidget);
    expect(find.text('WhatsApp Companion'), findsOneWidget);
    expect(find.text('Komoditas rutin'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('profile-navigation'))).height,
      greaterThanOrEqualTo(44),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('buyer profile supports loading empty and error states', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BuyerProfileScreen(state: BuyerProfileViewState.loading),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(
        home: BuyerProfileScreen(state: BuyerProfileViewState.empty),
      ),
    );
    expect(find.text('Profil usaha belum lengkap'), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(
        home: BuyerProfileScreen(state: BuyerProfileViewState.error),
      ),
    );
    expect(find.text('Gagal memuat profil'), findsOneWidget);
  });

  testWidgets('buyer profile adapts to a narrow phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: BuyerProfileScreen()));

    expect(find.text('Dapur Bu Ani'), findsOneWidget);
    expect(find.text('Buyer terverifikasi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile navigation opens the buyer profile page', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        routes: {RouteNames.buyerProfile: (_) => const BuyerProfileScreen()},
        home: const BuyerHomeScreen(),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('profile-navigation')));
    await tester.pumpAndSettle();
    expect(find.byType(BuyerProfileScreen), findsOneWidget);
  });

  testWidgets('buyer order actions show detail and tracking information', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: BuyerOrdersScreen()));

    await tester.tap(find.text('Detail').first);
    await tester.pumpAndSettle();
    expect(find.text('Detail Pesanan'), findsOneWidget);
    expect(find.text('Pak Ferdi · Kelompok Tani Ambarawa'), findsOneWidget);
    expect(find.text('Rp 425.000'), findsWidgets);
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lacak').first);
    await tester.pumpAndSettle();
    expect(find.text('Lacak Pesanan'), findsOneWidget);
    expect(find.text('Dalam pengiriman'), findsOneWidget);
    expect(find.text('18 Juli 2026'), findsOneWidget);
  });

  testWidgets('buyer orders adapts to a narrow screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: BuyerOrdersScreen()));

    expect(find.text('Tomat Segar'), findsOneWidget);
    expect(find.text('Rp 425.000'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byKey(const ValueKey('buyer-orders-list')),
      const Offset(0, -400),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('buyer home adapts to a narrow screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: BuyerHomeScreen()));

    expect(find.text('Komoditas Cepat'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byKey(const ValueKey('buyer-home-scroll')),
      const Offset(0, -500),
    );
    await tester.pump();
    expect(find.text('Bawang Putih'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a buyer product opens its detail page', (tester) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        routes: {RouteNames.productDetail: ProductDetailScreen.fromRoute},
        home: const BuyerHomeScreen(),
      ),
    );

    final product = find.byKey(const ValueKey('open-Cabai Merah Kering'));
    await tester.ensureVisible(product);
    await tester.tap(product);
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(find.text('Detail Produk'), findsOneWidget);
    expect(find.text('Cabai Merah Kering'), findsOneWidget);
    expect(find.text('Tomat Segar'), findsNothing);
    expect(
      find.textContaining('Supplier: Kelompok Tani Makmur'),
      findsOneWidget,
    );
  });

  testWidgets('buyer add action does not open the product detail', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        routes: {RouteNames.productDetail: ProductDetailScreen.fromRoute},
        home: const BuyerHomeScreen(),
      ),
    );

    final addButton = find.byKey(const ValueKey('add-Cabai Merah Kering'));
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pump();

    expect(find.byType(BuyerHomeScreen), findsOneWidget);
    expect(find.byType(ProductDetailScreen), findsNothing);
    expect(
      find.text('Cabai Merah Kering ditambahkan ke keranjang.'),
      findsOneWidget,
    );
  });

  testWidgets('product detail switches from description to reviews', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(428, 1055));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: ProductDetailScreen()));

    expect(find.text('Buat Kontrak Pasokan'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('product-reviews-tab')));
    await tester.pumpAndSettle();

    expect(find.text('Tambah Ulasan'), findsOneWidget);
    expect(find.text('Es Buah Rosyidah'), findsOneWidget);
    expect(find.text('Tacibay'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('review-filter-Semua'))).height,
      greaterThanOrEqualTo(44),
    );
    await tester.drag(
      find.byKey(const ValueKey('review-filter-scroll')),
      const Offset(-500, 0),
    );
    await tester.pump();
    expect(tester.getTopLeft(find.text('Bintang 1')).dx, lessThan(428));
    await tester.ensureVisible(find.text('Bintang 4'));
    await tester.tap(find.text('Bintang 4'));
    await tester.pump();
    expect(find.text('Belum ada ulasan untuk rating ini.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('product detail supports loading, empty, and error states', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProductDetailScreen(state: ProductDetailViewState.loading),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: ProductDetailScreen(state: ProductDetailViewState.empty),
      ),
    );
    expect(find.text('Produk tidak ditemukan'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: ProductDetailScreen(state: ProductDetailViewState.error),
      ),
    );
    expect(find.text('Gagal memuat produk'), findsOneWidget);
  });

  testWidgets('product detail adapts to a narrow screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: ProductDetailScreen()));

    expect(find.text('Detail Produk'), findsOneWidget);
    await tester.ensureVisible(find.text('Beli Sekarang'));
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(
      find.byKey(const ValueKey('product-reviews-tab')),
    );
    await tester.tap(find.byKey(const ValueKey('product-reviews-tab')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('review-filter-scroll')),
      const Offset(-500, 0),
    );
    await tester.pump();

    expect(tester.getTopLeft(find.text('Bintang 1')).dx, lessThan(320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('supply contract opens negotiation before recurring supply', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(428, 1056));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          RouteNames.negotiationChat: NegotiationChatScreen.fromRoute,
          RouteNames.recurringSupply: RecurringSupplyScreen.fromRoute,
        },
        home: const ProductDetailScreen(),
      ),
    );

    await tester.ensureVisible(find.text('Buat Kontrak Pasokan'));
    await tester.tap(find.text('Buat Kontrak Pasokan'));
    await tester.pumpAndSettle();

    expect(find.byType(NegotiationChatScreen), findsOneWidget);
    expect(find.byType(RecurringSupplyScreen), findsNothing);
    expect(find.text('Balasan Nego dari Pemasok'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('negotiation-chat-scroll')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    tester
        .widget<ElevatedButton>(find.byKey(const ValueKey('agree-offer')))
        .onPressed!();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('continue-contract')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('continue-contract')));
    await tester.pumpAndSettle();

    expect(find.byType(RecurringSupplyScreen), findsOneWidget);
    expect(find.text('Atur Pasokan Rutin'), findsOneWidget);
    expect(find.text('Tomat Segar • Grade Premium'), findsOneWidget);
    expect(find.text('Rp 470.000'), findsWidgets);
  });

  testWidgets('price negotiation uses its own copy and validates price', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(428, 1056));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        routes: {RouteNames.negotiationChat: NegotiationChatScreen.fromRoute},
        home: const ProductDetailScreen(),
      ),
    );

    await tester.ensureVisible(find.text('Negosiasi Harga'));
    await tester.tap(find.text('Negosiasi Harga'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Halo Pak, saya ingin menegosiasikan harga untuk pembelian berikut:',
      ),
      findsOneWidget,
    );
    expect(find.text('Frekuensi'), findsNothing);
    expect(find.text('Jadwal'), findsNothing);

    await tester.drag(
      find.byKey(const ValueKey('negotiation-chat-scroll')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('negotiate-again')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('negotiation-price-field')),
      '',
    );
    await tester.tap(find.text('Kirim Ajuan'));
    await tester.pump();

    expect(find.text('Masukkan harga lebih dari Rp0.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('negotiation chat sends a buyer message and supports states', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: NegotiationChatScreen()));

    await tester.tap(find.byKey(const ValueKey('send-chat-message')));
    await tester.pump();
    expect(find.text('Masukkan pesan sebelum mengirim.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('chat-message-field')),
      'Apakah pengiriman pagi bisa?',
    );
    await tester.pump();
    expect(find.text('Masukkan pesan sebelum mengirim.'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('send-chat-message')));
    await tester.pumpAndSettle();
    expect(find.text('Apakah pengiriman pagi bisa?'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      const MaterialApp(
        home: NegotiationChatScreen(state: NegotiationChatViewState.loading),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: NegotiationChatScreen(state: NegotiationChatViewState.empty),
      ),
    );
    expect(find.text('Belum ada percakapan'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: NegotiationChatScreen(state: NegotiationChatViewState.error),
      ),
    );
    expect(find.text('Percakapan gagal dimuat'), findsOneWidget);
  });

  testWidgets('negotiation back button returns to product detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {RouteNames.productDetail: ProductDetailScreen.fromRoute},
        home: const NegotiationChatScreen(),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('negotiation-back')));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(find.text('Detail Produk'), findsOneWidget);
  });

  testWidgets('recurring supply route falls back to official tomato fixture', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(428, 1056));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: RouteNames.recurringSupply,
        routes: {RouteNames.recurringSupply: RecurringSupplyScreen.fromRoute},
      ),
    );

    expect(find.text('Kelompok Tani Ambarawa'), findsOneWidget);
    expect(find.text('Tomat • Grade B'), findsOneWidget);
    expect(find.text('Rp 85.000'), findsWidgets);
    expect(
      find.text('Harga mengikuti listing pemasok saat ini'),
      findsOneWidget,
    );
    final activeDay = tester.widget<Ink>(
      find.descendant(
        of: find.byKey(const ValueKey('delivery-day-0')),
        matching: find.byType(Ink),
      ),
    );
    expect((activeDay.decoration! as BoxDecoration).color, AppColors.accent);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('recurring-supply-submit')))
          .height,
      greaterThanOrEqualTo(44),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('recurring supply recalculates quantity and unit', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(428, 1056));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: RecurringSupplyScreen()));

    await tester.enterText(
      find.byKey(const ValueKey('recurring-quantity-field')),
      '2',
    );
    await tester.tap(find.byKey(const ValueKey('delivery-unit-quintal')));
    await tester.pump();

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('recurring-supply-estimate')))
          .data,
      'Rp 1.700.000',
    );
    expect(find.text('200 kg'), findsOneWidget);
  });

  testWidgets('recurring supply controls feed the confirmation summary', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(428, 1056));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: RecurringSupplyScreen()));

    await tester.tap(
      find.byKey(const ValueKey('delivery-frequency-twiceWeekly')),
    );
    await tester.tap(find.byKey(const ValueKey('delivery-day-0')));
    await tester.tap(find.byKey(const ValueKey('delivery-day-2')));
    await tester.ensureVisible(find.byKey(const ValueKey('quality-dropdown')));
    await tester.tap(find.byKey(const ValueKey('quality-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grade A (Premium)').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('recurring-supply-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi Pasokan Rutin'), findsOneWidget);
    expect(find.textContaining('2 hari per minggu'), findsOneWidget);
    expect(find.textContaining('Grade A (Premium)'), findsWidgets);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi Pasokan Rutin'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('recurring-supply-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Konfirmasi'));
    await tester.pump();
    expect(find.text('Pasokan rutin berhasil dikonfirmasi.'), findsOneWidget);
  });

  testWidgets('recurring supply disables checkout for invalid quantity', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RecurringSupplyScreen()));

    await tester.enterText(
      find.byKey(const ValueKey('recurring-quantity-field')),
      '',
    );
    await tester.pump();

    final button = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('recurring-supply-submit')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('recurring supply supports loading empty and error states', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RecurringSupplyScreen(state: RecurringSupplyViewState.loading),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: RecurringSupplyScreen(state: RecurringSupplyViewState.empty),
      ),
    );
    expect(find.text('Pasokan belum tersedia'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: RecurringSupplyScreen(state: RecurringSupplyViewState.error),
      ),
    );
    expect(find.text('Gagal memuat pasokan'), findsOneWidget);
    expect(find.byKey(const ValueKey('recurring-supply-submit')), findsNothing);
    await tester.tap(find.text('Coba Lagi'));
    await tester.pump();
    expect(find.text('Mencoba memuat ulang pasokan...'), findsOneWidget);
  });

  testWidgets('recurring supply enforces schedule rules', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RecurringSupplyScreen()));

    expect(find.text('Pengiriman dilakukan setiap hari'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('delivery-day-0')));
    await tester.pump();
    expect(
      find.text('Pengiriman harian berlaku untuk semua hari.'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('delivery-frequency-twiceWeekly')),
    );
    await tester.pump();
    expect(find.text('Pilih tepat 2 hari pengiriman'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('delivery-day-2')));
    await tester.pump();
    expect(
      find.text('Pilih maksimal 2 hari untuk frekuensi ini.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('delivery-day-0')));
    await tester.pump();
    var button = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('recurring-supply-submit')),
    );
    expect(button.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('delivery-day-2')));
    await tester.tap(find.byKey(const ValueKey('delivery-frequency-weekly')));
    await tester.pump();
    expect(find.text('Pilih tepat 1 hari pengiriman'), findsOneWidget);
    button = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('recurring-supply-submit')),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('recurring supply limits quantity and exposes semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(home: RecurringSupplyScreen()));

    expect(find.bySemanticsLabel('Jumlah per pengiriman'), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('Satuan Kg')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('quality-dropdown')));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('Kualitas produk')), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('recurring-quantity-field')),
      '123456789',
    );
    await tester.pump();
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('recurring-quantity-field')),
          )
          .controller
          ?.text,
      '123456',
    );
    semantics.dispose();
  });

  testWidgets('recurring supply back button returns to previous screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const RecurringSupplyScreen(),
              ),
            ),
            child: const Text('Buka Pasokan'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka Pasokan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recurring-supply-back')));
    await tester.pumpAndSettle();

    expect(find.text('Buka Pasokan'), findsOneWidget);
    expect(find.byType(RecurringSupplyScreen), findsNothing);
  });

  testWidgets('recurring supply adapts to a narrow screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: RecurringSupplyScreen()));

    expect(find.text('Atur Pasokan Rutin'), findsOneWidget);
    expect(find.byKey(const ValueKey('delivery-day-scroll')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byKey(const ValueKey('recurring-supply-scroll')),
      const Offset(0, -600),
    );
    await tester.pump();
    expect(find.text('Rincian Harga'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile setup requires terms before submission', (tester) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: ProfileSetupScreen()));

    await tester.tap(find.text('Daftar Sekarang'));
    await tester.pump();

    expect(
      find.text('Setujui Syarat & Ketentuan untuk melanjutkan.'),
      findsOneWidget,
    );
  });

  testWidgets('profile setup validates commodity selection', (tester) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: ProfileSetupScreen()));

    await tester.tap(find.byKey(const ValueKey('terms-row')));
    await tester.tap(find.text('Daftar Sekarang'));
    await tester.pump();

    expect(
      find.text('Pilih minimal satu komoditas penjualan.'),
      findsOneWidget,
    );
  });

  testWidgets('profile setup adapts to a narrow screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: ProfileSetupScreen()));

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Daftar Sekarang'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile setup keeps location action accessible', (tester) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: ProfileSetupScreen()));

    expect(
      tester
          .getSize(find.byKey(const ValueKey('choose-location-button')))
          .height,
      greaterThanOrEqualTo(44),
    );
    await tester.tap(find.byKey(const ValueKey('choose-location-button')));
    await tester.pump();
    expect(
      find.text('Pemilihan lokasi di peta akan segera tersedia.'),
      findsOneWidget,
    );
  });

  testWidgets('profile setup submits a valid profile', (tester) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    UserRole? savedRole;
    await tester.pumpWidget(
      MaterialApp(
        routes: {RouteNames.homePetani: (_) => const FarmerShell()},
        home: ProfileSetupScreen(saveRole: (role) async => savedRole = role),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('farmer-name-field')),
      'Pak Ferdi',
    );
    await tester.enterText(
      find.byKey(const ValueKey('farmer-group-field')),
      'Kelompok Tani Makmur',
    );
    await tester.enterText(
      find.byKey(const ValueKey('address-field')),
      'Garut, Jawa Barat',
    );
    await tester.tap(find.text('Tomat'));
    await tester.tap(find.byKey(const ValueKey('terms-row')));
    await tester.tap(find.text('Daftar Sekarang'));
    await tester.pump();

    await tester.pumpAndSettle();
    expect(savedRole, UserRole.farmer);
    expect(find.byType(FarmerHomeScreen), findsOneWidget);
    expect(find.text('Permintaan Baru'), findsOneWidget);
  });

  testWidgets('profile is persisted before auth role is saved', (tester) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final events = <String>[];
    final repository = ProfileRepository(_RecordingProfileApi(events));
    await tester.pumpWidget(
      MaterialApp(
        routes: {RouteNames.homePetani: (_) => const FarmerShell()},
        home: ProfileSetupScreen(
          repository: repository,
          saveRole: (role) async => events.add('role:${role.authValue}'),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('farmer-name-field')),
      'Pak Ferdi',
    );
    await tester.enterText(
      find.byKey(const ValueKey('farmer-group-field')),
      'Kelompok Tani Makmur',
    );
    await tester.enterText(
      find.byKey(const ValueKey('address-field')),
      'Garut, Jawa Barat',
    );
    await tester.tap(find.text('Tomat'));
    await tester.tap(find.byKey(const ValueKey('terms-row')));
    await tester.tap(find.text('Daftar Sekarang'));
    await tester.pumpAndSettle();

    expect(events, ['profile:FARM', 'role:FARMER']);
    expect(find.byType(FarmerHomeScreen), findsOneWidget);
  });

  testWidgets('profile setup validates required fields', (tester) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: ProfileSetupScreen()));

    await tester.tap(find.text('Tomat'));
    await tester.tap(find.byKey(const ValueKey('terms-row')));
    await tester.tap(find.text('Daftar Sekarang'));
    await tester.pump();

    expect(find.text('Bagian ini wajib diisi.'), findsNWidgets(3));
  });

  testWidgets('buyer messages renders fixture and filters conversations', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: BuyerMessagesScreen()));

    expect(find.text('Pesan'), findsNWidgets(2));
    expect(find.text('Pak Ferdi'), findsOneWidget);
    expect(find.text('3 baru'), findsOneWidget);
    expect(find.byKey(const ValueKey('unread-Pak Ferdi')), findsOneWidget);
    expect(find.byKey(const ValueKey('buyer-messages-list')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.enterText(
      find.byKey(const ValueKey('messages-search-field')),
      'kentang',
    );
    await tester.pump();

    expect(find.text('Bu Rini'), findsOneWidget);
    expect(find.text('Pak Ferdi'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('clear-messages-search')));
    await tester.pump();
    expect(find.text('Pak Ferdi'), findsOneWidget);
  });

  testWidgets('buyer messages shows helpful no-result and error states', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: BuyerMessagesScreen()));
    await tester.enterText(
      find.byKey(const ValueKey('messages-search-field')),
      'tidak ada',
    );
    await tester.pump();
    expect(find.text('Percakapan tidak ditemukan'), findsOneWidget);
    expect(find.text('Hapus Pencarian'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: BuyerMessagesScreen(state: BuyerMessagesViewState.error),
      ),
    );
    expect(find.text('Pesan gagal dimuat'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
  });

  testWidgets('buyer messages opens existing negotiation chat', (tester) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: const BuyerMessagesScreen(),
        routes: {RouteNames.negotiationChat: NegotiationChatScreen.fromRoute},
      ),
    );

    await tester.tap(find.text('Pak Ferdi'));
    await tester.pumpAndSettle();

    expect(find.byType(NegotiationChatScreen), findsOneWidget);
    expect(find.text('Pak Ferdi'), findsOneWidget);
  });

  testWidgets('buyer home message navigation opens the inbox', (tester) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: const BuyerHomeScreen(),
        routes: {RouteNames.buyerMessages: (_) => const BuyerMessagesScreen()},
      ),
    );

    await tester.tap(find.byKey(const ValueKey('messages-navigation')));
    await tester.pumpAndSettle();
    expect(find.byType(BuyerMessagesScreen), findsOneWidget);
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
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      routes: buildAppRoutes(),
      home: const FarmerHomeScreen(),
    ),
  );
}

Future<void> _pumpManageOrders(
  WidgetTester tester, {
  Size size = const Size(428, 938),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      routes: buildAppRoutes(),
      home: const ManageOrdersScreen(),
    ),
  );
}

Future<void> _pumpStock(WidgetTester tester) async {
  tester.view.physicalSize = const Size(428, 938);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      routes: buildAppRoutes(),
      home: const StockScreen(),
    ),
  );
}

class _RecordingProfileApi implements ApiTransport {
  _RecordingProfileApi(this.events);

  final List<String> events;

  @override
  Future<Object?> get(String path) => throw UnimplementedError();

  @override
  Future<Object?> patch(String path, {Object? body}) =>
      throw UnimplementedError();

  @override
  Future<Object?> post(String path, {Object? body}) =>
      throw UnimplementedError();

  @override
  Future<Object?> put(String path, {Object? body}) async {
    final payload = body! as Map<String, Object>;
    events.add('profile:${payload['organizationType']}');
    return {
      'name': payload['name'],
      'organizationName': payload['organizationName'],
      'organizationType': payload['organizationType'],
      'address': payload['address'],
      'commodityNames': payload['commodityNames'],
    };
  }
}

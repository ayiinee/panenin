import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panenin/app/app.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/app/shell/panenin_bottom_navigation.dart';
import 'package:panenin/app/theme/app_colors.dart';
import 'package:panenin/app/theme/app_theme.dart';
import 'package:panenin/features/auth/data/models/authenticated_user.dart';
import 'package:panenin/features/auth/data/models/email_sign_up_result.dart';
import 'package:panenin/features/auth/presentation/screens/create_account_screen.dart';
import 'package:panenin/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:panenin/features/auth/presentation/screens/login_screen.dart';
import 'package:panenin/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:panenin/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:panenin/features/auth/presentation/widgets/google_auth_button.dart';
import 'package:panenin/features/home/presentation/screens/farmer_home_screen.dart';
import 'package:panenin/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:panenin/features/orders/presentation/screens/manage_orders_screen.dart';
import 'package:panenin/features/stock/presentation/screens/stock_form_screen.dart';
import 'package:panenin/features/stock/presentation/screens/stock_screen.dart';
import 'package:panenin/shared/widgets/app_notification_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('route utama mengikuti nama branch UI', () {
    expect(RouteNames.homePetani, '/beranda');
    expect(RouteNames.kelolaPesanan, '/kelola-pesanan');
    expect(RouteNames.detailPesanan, '/detail-pesanan');
    expect(RouteNames.stokSaya, '/stok');
    expect(
      buildAppRoutes().keys,
      containsAll([
        RouteNames.homePetani,
        RouteNames.kelolaPesanan,
        RouteNames.detailPesanan,
        RouteNames.stokSaya,
      ]),
    );
  });

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

  testWidgets('garis progress tersambung dan label tahap proporsional', (
    tester,
  ) async {
    await _pumpManageOrders(tester, size: const Size(320, 700));

    final awaiting = find.byKey(const ValueKey('progress-awaiting-payment'));
    final firstConnector = find.byKey(
      const ValueKey('progress-connector-first'),
    );
    final ready = find.byKey(const ValueKey('progress-ready-to-ship'));
    final secondConnector = find.byKey(
      const ValueKey('progress-connector-second'),
    );
    final completed = find.byKey(const ValueKey('progress-completed'));

    expect(
      tester.getRect(awaiting).right,
      closeTo(tester.getRect(firstConnector).left, 0.1),
    );
    expect(
      tester.getRect(firstConnector).right,
      closeTo(tester.getRect(ready).left, 0.1),
    );
    expect(
      tester.getRect(ready).right,
      closeTo(tester.getRect(secondConnector).left, 0.1),
    );
    expect(
      tester.getRect(secondConnector).right,
      closeTo(tester.getRect(completed).left, 0.1),
    );

    final label = tester.widget<Text>(
      find.descendant(of: awaiting, matching: find.text('Menunggu DP')),
    );
    expect(label.style!.fontSize, 10.5);
  });

  testWidgets('tipografi seluruh kartu pesanan memiliki hierarki rapi', (
    tester,
  ) async {
    await _pumpManageOrders(tester);

    expect(tester.widget<Text>(find.text('Tacibay')).style!.fontSize, 15);
    expect(tester.widget<Text>(find.text('Tomat')).style!.fontSize, 13);
    expect(tester.widget<Text>(find.text('Rp15.000/Kg')).style!.fontSize, 14);
    expect(
      tester.widget<Text>(find.text('Kirim: 09 Juli 2026')).style!.fontSize,
      12,
    );
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
    await tester.tap(find.byKey(const ValueKey('increase-stock')));
    await tester.tap(find.byKey(const ValueKey('save-stock')));
    await tester.pumpAndSettle();

    expect(find.byType(StockScreen), findsOneWidget);
    expect(find.text('Bayam'), findsOneWidget);
    expect(find.text('4 Produk  •  23 Kg tersedia'), findsOneWidget);
  });

  testWidgets('ikon pensil mengedit jumlah stok produk', (tester) async {
    await _pumpStock(tester);

    await tester.tap(find.byKey(const ValueKey('edit-stock-cabai-merah')));
    await tester.pumpAndSettle();

    expect(find.byType(StockFormScreen), findsOneWidget);
    expect(find.byType(PaneninBottomNavigation), findsNothing);
    expect(find.text('12'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('increase-stock')));
    await tester.tap(find.byKey(const ValueKey('save-stock')));
    await tester.pumpAndSettle();

    expect(find.byType(StockScreen), findsOneWidget);
    expect(find.text('13Kg'), findsOneWidget);
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

  testWidgets('renders correctly typed create account fields', (tester) async {
    await tester.pumpWidget(const PaneninApp());

    expect(find.text('Buat Akun Anda'), findsOneWidget);
    expect(find.text('Nama Pengguna'), findsOneWidget);
    expect(find.text('Alamat Email'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.byType(GoogleAuthButton), findsOneWidget);

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields, hasLength(3));
    expect(fields[0].obscureText, isFalse);
    expect(fields[0].textCapitalization, TextCapitalization.words);
    expect(fields[1].obscureText, isFalse);
    expect(fields[1].keyboardType, TextInputType.emailAddress);
    expect(fields[2].obscureText, isTrue);
    expect(fields[2].textInputAction, TextInputAction.done);
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
        home: CreateAccountScreen(googleSignIn: () async => demoUser),
      ),
    );

    final googleButton = find.byType(GoogleAuthButton);
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Pendaftaran berhasil sebagai Demo Panenin.'),
      findsOneWidget,
    );
  });

  testWidgets('login screen is separate and navigable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const PaneninApp());

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

    expect(find.text('Berhasil masuk sebagai Demo Panenin.'), findsOneWidget);
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
      MaterialApp(home: LoginScreen(googleSignIn: () async => demoUser)),
    );

    final googleButton = find.byType(GoogleAuthButton);
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await tester.pumpAndSettle();

    expect(find.text('Berhasil masuk sebagai Demo Panenin.'), findsOneWidget);
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

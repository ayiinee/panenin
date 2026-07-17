import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panenin/app/app.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/features/auth/presentation/screens/create_account_screen.dart';
import 'package:panenin/features/auth/presentation/screens/login_screen.dart';
import 'package:panenin/features/auth/presentation/screens/select_role_screen.dart';
import 'package:panenin/core/constants/app_colors.dart';
import 'package:panenin/features/auth/domain/user_role.dart';
import 'package:panenin/features/home/presentation/screens/buyer_home_screen.dart';
import 'package:panenin/features/marketplace/presentation/screens/product_detail_screen.dart';
import 'package:panenin/features/profile/presentation/screens/profile_setup_screen.dart';

void main() {
  testWidgets('renders the role selection screen', (tester) async {
    await tester.pumpWidget(const PaneninApp());

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
  });

  testWidgets('farmer role continues to account creation', (tester) async {
    await tester.pumpWidget(const PaneninApp());

    final farmerAction = find.text('Jual Hasil Panen');
    await tester.ensureVisible(farmerAction);
    await tester.tap(farmerAction);
    await tester.pumpAndSettle();

    expect(find.byType(CreateAccountScreen), findsOneWidget);
    expect(find.text('Daftar sebagai Petani'), findsOneWidget);
    expect(
      ModalRoute.of(
        tester.element(find.byType(CreateAccountScreen)),
      )?.settings.arguments,
      UserRole.farmer,
    );
  });

  testWidgets('buyer role continues to account creation', (tester) async {
    await tester.pumpWidget(const PaneninApp());

    final buyerAction = find.text('Beli Hasil Panen');
    await tester.ensureVisible(buyerAction);
    await tester.tap(buyerAction);
    await tester.pumpAndSettle();

    expect(find.byType(CreateAccountScreen), findsOneWidget);
    expect(find.text('Daftar sebagai UMKM'), findsOneWidget);
    expect(
      ModalRoute.of(
        tester.element(find.byType(CreateAccountScreen)),
      )?.settings.arguments,
      UserRole.buyer,
    );
  });

  testWidgets('register action gives the user feedback', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreateAccountScreen()));

    final registerButton = find.text('Daftarkan Akun');
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pump();

    expect(find.text('Formulir pendaftaran siap diproses.'), findsOneWidget);
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

    final loginLink = find.text('Masuk');
    await tester.ensureVisible(loginLink);
    await tester.tap(loginLink);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Selamat Datang Kembali'), findsOneWidget);
    expect(find.text('Masukkan email'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Belum punya akun?'), findsOneWidget);
  });

  testWidgets('login action gives the user feedback', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.text('Formulir login siap diproses.'), findsOneWidget);
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

  testWidgets('farmer registration continues to profile setup', (tester) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const PaneninApp());

    await tester.tap(find.text('Jual Hasil Panen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daftarkan Akun'));
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

  testWidgets('buyer registration continues to the UMKM profile setup', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const PaneninApp());

    await tester.tap(find.text('Beli Hasil Panen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daftarkan Akun'));
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
    expect(find.text('Maps'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('find-commodities-button')))
          .height,
      greaterThanOrEqualTo(44),
    );
    expect(tester.takeException(), isNull);
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
    await tester.pumpWidget(const MaterialApp(home: ProfileSetupScreen()));

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

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('Data diri berhasil disimpan.'), findsOneWidget);
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
}

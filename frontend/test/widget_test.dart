import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panenin/app/app.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/core/constants/app_colors.dart';
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
import 'package:panenin/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const demoUser = AuthenticatedUser(
  id: '11111111-1111-1111-1111-111111111111',
  email: 'demo@panenin.id',
  name: 'Demo Panenin',
  provider: 'email',
);

void main() {
  testWidgets('renders correctly typed create account fields', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreateAccountScreen()));

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

  testWidgets('opens registration as the first screen', (tester) async {
    await tester.pumpWidget(const PaneninApp());

    expect(find.byType(CreateAccountScreen), findsOneWidget);
    expect(find.text('Buat Akun Anda'), findsOneWidget);
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

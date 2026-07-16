import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panenin/app/app.dart';
import 'package:panenin/app/router/route_names.dart';
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
import 'package:panenin/shared/widgets/app_notification_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    MaterialApp(theme: AppTheme.light, home: const FarmerHomeScreen()),
  );
}

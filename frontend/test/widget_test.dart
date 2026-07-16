import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panenin/app/app.dart';
import 'package:panenin/features/auth/presentation/screens/login_screen.dart';
import 'package:panenin/features/auth/presentation/widgets/google_auth_button.dart';

void main() {
  testWidgets('renders the create account screen', (tester) async {
    await tester.pumpWidget(const PaneninApp());

    expect(find.text('Buat Akun Anda'), findsOneWidget);
    expect(find.text('Kami hadir untuk membantu usahamu'), findsOneWidget);
    expect(find.text('Nama Pengguna'), findsOneWidget);
    expect(find.text('Alamat Email'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('Daftarkan Akun'), findsOneWidget);
    expect(find.text('Atau Daftar Dengan'), findsOneWidget);
    expect(find.byType(GoogleAuthButton), findsOneWidget);
    expect(find.text('Sudah punya akun?'), findsOneWidget);
  });

  testWidgets('register action gives the user feedback', (tester) async {
    await tester.pumpWidget(const PaneninApp());

    final registerButton = find.text('Daftarkan Akun');
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pump();

    expect(find.text('Formulir pendaftaran siap diproses.'), findsOneWidget);
  });

  testWidgets('login screen is separate and navigable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(428, 926));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const PaneninApp());

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
}

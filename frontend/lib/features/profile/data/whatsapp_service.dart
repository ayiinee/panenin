import 'package:panenin/core/config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  const WhatsAppService({
    this.phoneNumber = AppConfig.whatsappPhoneNumber,
    this.launcher = launchUrl,
  });

  final String phoneNumber;
  final Future<bool> Function(Uri url, {LaunchMode mode}) launcher;

  Future<void> openConnectionChat() async {
    final uri = buildConnectionUri(phoneNumber);
    final opened = await launcher(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      throw const WhatsAppLaunchException(
        'WhatsApp tidak dapat dibuka. Pastikan WhatsApp sudah terpasang.',
      );
    }
  }

  static Uri buildConnectionUri(String phoneNumber) {
    final normalizedPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalizedPhone.isEmpty) {
      throw const WhatsAppLaunchException(
        'Nomor WhatsApp Panenin belum dikonfigurasi.',
      );
    }

    return Uri.https('wa.me', '/$normalizedPhone', {
      'text': 'Halo Panenin, saya ingin menghubungkan akun petani saya.',
    });
  }
}

class WhatsAppLaunchException implements Exception {
  const WhatsAppLaunchException(this.message);

  final String message;

  @override
  String toString() => message;
}

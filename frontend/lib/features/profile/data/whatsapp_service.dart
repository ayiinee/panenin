import 'package:panenin/core/config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  const WhatsAppService({
    this.phoneNumber = AppConfig.whatsappPhoneNumber,
    this.launcher = launchUrl,
  });

  final String phoneNumber;
  final Future<bool> Function(Uri url, {LaunchMode mode}) launcher;

  Future<void> openConnectionChat({String? linkCode}) async {
    final uri = buildConnectionUri(phoneNumber, linkCode: linkCode);
    final opened = await launcher(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      throw const WhatsAppLaunchException(
        'WhatsApp tidak dapat dibuka. Pastikan WhatsApp sudah terpasang.',
      );
    }
  }

  static Uri buildConnectionUri(String phoneNumber, {String? linkCode}) {
    final normalizedPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalizedPhone.isEmpty) {
      throw const WhatsAppLaunchException(
        'Nomor WhatsApp Panenin belum dikonfigurasi.',
      );
    }
    final normalizedCode = linkCode?.trim().toUpperCase();
    if (linkCode != null &&
        (normalizedCode == null || normalizedCode.isEmpty)) {
      throw const WhatsAppLaunchException(
        'Kode penghubung WhatsApp tidak valid.',
      );
    }

    return Uri.https('wa.me', '/$normalizedPhone', {
      'text': normalizedCode == null
          ? 'Halo Panenin, saya ingin menghubungkan akun petani saya.'
          : 'HUBUNGKAN $normalizedCode',
    });
  }
}

class WhatsAppLaunchException implements Exception {
  const WhatsAppLaunchException(this.message);

  final String message;

  @override
  String toString() => message;
}

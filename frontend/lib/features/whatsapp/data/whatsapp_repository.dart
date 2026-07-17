import 'package:panenin/core/network/api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WhatsAppLinkCode {
  const WhatsAppLinkCode({
    required this.code,
    required this.expiresAt,
    required this.instruction,
  });

  final String code;
  final DateTime expiresAt;
  final String instruction;
}

class WhatsAppStatus {
  const WhatsAppStatus({required this.linked, this.verifiedAt});

  final bool linked;
  final DateTime? verifiedAt;
}

class WhatsAppRepository {
  WhatsAppRepository(this._api);

  factory WhatsAppRepository.create() {
    final supabase = Supabase.instance.client;
    return WhatsAppRepository(ApiClient(supabase));
  }

  final ApiTransport _api;

  Future<WhatsAppLinkCode> createLinkCode() async {
    final data = await _api.post('/api/v1/whatsapp/link-code');
    final json = data! as Map<String, dynamic>;
    return WhatsAppLinkCode(
      code: json['linkCode'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      instruction: json['instruction'] as String,
    );
  }

  Future<WhatsAppStatus> status() async {
    final data = await _api.get('/api/v1/whatsapp/status');
    final json = data! as Map<String, dynamic>;
    return WhatsAppStatus(
      linked: json['linked'] as bool,
      verifiedAt: json['verifiedAt'] == null
          ? null
          : DateTime.parse(json['verifiedAt'] as String),
    );
  }
}

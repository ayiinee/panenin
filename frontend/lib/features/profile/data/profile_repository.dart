import 'package:panenin/core/network/api_client.dart';
import 'package:panenin/features/auth/domain/user_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileInput {
  const ProfileInput({
    required this.name,
    required this.organizationName,
    required this.role,
    required this.address,
    required this.commodityNames,
  });

  final String name;
  final String organizationName;
  final UserRole role;
  final String address;
  final List<String> commodityNames;

  Map<String, Object> toJson() => {
    'name': name,
    'organizationName': organizationName,
    'organizationType': role.apiValue,
    'address': address,
    'commodityNames': commodityNames,
  };
}

class ProfileData {
  const ProfileData({
    required this.name,
    required this.organizationName,
    required this.organizationType,
    required this.address,
    required this.commodityNames,
  });

  final String name;
  final String organizationName;
  final String organizationType;
  final String? address;
  final List<String> commodityNames;

  factory ProfileData.fromJson(Map<String, dynamic> json) => ProfileData(
    name: json['name'] as String,
    organizationName: json['organizationName'] as String,
    organizationType: json['organizationType'] as String,
    address: json['address'] as String?,
    commodityNames: (json['commodityNames'] as List<dynamic>? ?? const [])
        .cast<String>(),
  );
}

class ProfileRepository {
  ProfileRepository(this._api);

  factory ProfileRepository.create() {
    final supabase = Supabase.instance.client;
    return ProfileRepository(ApiClient(supabase));
  }

  final ApiTransport _api;

  Future<ProfileData> getProfile() async {
    final data = await _api.get('/api/v1/me/profile');
    return ProfileData.fromJson(data! as Map<String, dynamic>);
  }

  Future<ProfileData> saveProfile(ProfileInput input) async {
    final data = await _api.put('/api/v1/me/profile', body: input.toJson());
    return ProfileData.fromJson(data! as Map<String, dynamic>);
  }
}

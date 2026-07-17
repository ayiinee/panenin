import 'package:panenin/core/constants/app_assets.dart';
import 'package:panenin/core/network/api_client.dart';
import 'package:panenin/features/home/data/buyer_home_fixture.dart';
import 'package:panenin/features/profile/data/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BuyerHomeRepository {
  BuyerHomeRepository(this._api, this._profiles);

  factory BuyerHomeRepository.create() {
    final supabase = Supabase.instance.client;
    final api = ApiClient(supabase);
    return BuyerHomeRepository(api, ProfileRepository(api));
  }

  final ApiTransport _api;
  final ProfileRepository _profiles;

  Future<BuyerHomeData> load() async {
    final profile = await _profiles.getProfile();
    final data = await _api.get('/api/v1/catalog/listings');
    final listings = (data! as List<dynamic>).cast<Map<String, dynamic>>();
    final commodityNames = listings
        .map((item) => item['commodity'] as String)
        .toSet()
        .take(5)
        .toList();
    return BuyerHomeData(
      locationLabel: 'Lokasi Anda',
      location: profile.address ?? profile.organizationName,
      categories: commodityNames
          .map((name) => BuyerHomeCategory(name, _assetFor(name)))
          .toList(),
      products: listings.take(8).map((item) {
        final name = item['commodity'] as String;
        return BuyerHomeProduct(
          name,
          'Rp ${_formatPrice(item['pricePerUnit'])}',
          _assetFor(name),
        );
      }).toList(),
    );
  }

  static String _assetFor(String commodity) {
    final value = commodity.toLowerCase();
    if (value.contains('cabai')) return AppAssets.categoryChili;
    if (value.contains('tomat')) return AppAssets.categoryTomato;
    if (value.contains('kentang')) return AppAssets.categoryPotato;
    if (value.contains('buah')) return AppAssets.categoryFruit;
    return AppAssets.categoryVegetable;
  }

  static String _formatPrice(Object? value) {
    final number = switch (value) {
      num number => number.round(),
      String text => num.parse(text).round(),
      _ => 0,
    };
    return number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
  }
}

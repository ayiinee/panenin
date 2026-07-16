import 'package:panenin/core/constants/app_assets.dart';

class BuyerHomeData {
  const BuyerHomeData({
    required this.locationLabel,
    required this.location,
    required this.categories,
    required this.products,
  });

  final String locationLabel;
  final String location;
  final List<BuyerHomeCategory> categories;
  final List<BuyerHomeProduct> products;
}

class BuyerHomeCategory {
  const BuyerHomeCategory(this.name, this.asset);

  final String name;
  final String asset;
}

class BuyerHomeProduct {
  const BuyerHomeProduct(this.name, this.price, this.asset);

  final String name;
  final String price;
  final String asset;
}

/// Replaceable typed fixture until the marketplace endpoint is integrated.
abstract final class BuyerHomeFixture {
  static const design = BuyerHomeData(
    locationLabel: 'Lokasi Anda',
    location: 'Malang, Jawa Timur',
    categories: [
      BuyerHomeCategory('Cabai', AppAssets.categoryChili),
      BuyerHomeCategory('Tomat', AppAssets.categoryTomato),
      BuyerHomeCategory('Sayuran', AppAssets.categoryVegetable),
      BuyerHomeCategory('Kentang', AppAssets.categoryPotato),
      BuyerHomeCategory('Buah', AppAssets.categoryFruit),
    ],
    products: [
      BuyerHomeProduct(
        'Cabai Merah Kering',
        'Rp 49.500',
        AppAssets.productDriedChili,
      ),
      BuyerHomeProduct('Kentang', 'Rp 29.500', AppAssets.productPotato),
      BuyerHomeProduct('Sawi', 'Rp 15.500', AppAssets.productSawi),
      BuyerHomeProduct('Bawang Putih', 'Rp 10.000', AppAssets.productGarlic),
    ],
  );
}

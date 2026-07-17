import 'package:panenin/core/constants/app_assets.dart';
import 'package:panenin/features/marketplace/data/product_detail_fixture.dart';

enum DeliveryUnit {
  kilogram('Kg', 1),
  quintal('Kuintal', 100),
  ton('Ton', 1000);

  const DeliveryUnit(this.label, this.kilogramMultiplier);

  final String label;
  final int kilogramMultiplier;
}

enum DeliveryFrequency {
  daily('Harian'),
  twiceWeekly('2x seminggu'),
  weekly('Mingguan');

  const DeliveryFrequency(this.label);

  final String label;
}

class RecurringSupplyData {
  const RecurringSupplyData({
    required this.supplierName,
    required this.commodityName,
    required this.itemDescription,
    required this.supplierImage,
    required this.unitPrice,
    required this.qualityOptions,
    required this.initialQuality,
  });

  final String supplierName;
  final String commodityName;
  final String itemDescription;
  final String supplierImage;
  final int unitPrice;
  final List<String> qualityOptions;
  final String initialQuality;
}

/// Replaceable typed fixture until the recurring-supply API is available.
abstract final class RecurringSupplyFixture {
  static const demo = RecurringSupplyData(
    supplierName: 'Kelompok Tani Ambarawa',
    commodityName: 'Tomat',
    itemDescription: 'Tomat • Grade B',
    supplierImage: AppAssets.supplierMakmur,
    unitPrice: 8500,
    qualityOptions: ['Grade A (Premium)', 'Grade B (Standard)', 'Grade Olahan'],
    initialQuality: 'Grade B (Standard)',
  );

  static RecurringSupplyData fromProductDetail(
    ProductDetailData product, {
    int? unitPrice,
  }) {
    final parsedPrice = int.tryParse(
      product.price.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    return RecurringSupplyData(
      supplierName: product.supplierName,
      commodityName: product.name,
      itemDescription: '${product.name} • Grade Premium',
      supplierImage: product.supplierImage,
      unitPrice: unitPrice ?? parsedPrice ?? demo.unitPrice,
      qualityOptions: demo.qualityOptions,
      initialQuality: demo.initialQuality,
    );
  }
}

import 'package:panenin/core/constants/app_assets.dart';
import 'package:panenin/features/marketplace/data/product_detail_fixture.dart';

class BuyerConversation {
  const BuyerConversation({
    required this.farmerName,
    required this.farmName,
    required this.initials,
    required this.preview,
    required this.timeLabel,
    required this.commodity,
    required this.product,
    this.avatar,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  final String farmerName;
  final String farmName;
  final String initials;
  final String preview;
  final String timeLabel;
  final String commodity;
  final ProductDetailData product;
  final String? avatar;
  final int unreadCount;
  final bool isOnline;
}

abstract final class BuyerMessagesFixture {
  static const conversations = [
    BuyerConversation(
      farmerName: 'Pak Ferdi',
      farmName: 'Kelompok Tani Ambarawa',
      initials: 'PF',
      preview: 'Siap, 50 kg tomat Grade B bisa dikirim besok pagi.',
      timeLabel: '09.42',
      commodity: 'Tomat Grade B',
      unreadCount: 2,
      isOnline: true,
      avatar: AppAssets.supplierMakmur,
      product: ProductDetailData(
        name: 'Tomat Grade B',
        price: 'Rp 8.500',
        image: AppAssets.productDetailTomato,
        tags: ['Lokal', 'Grade B', 'Besok'],
        rating: 4.9,
        supplierName: 'Pak Ferdi',
        supplierLocation: 'Kepanjen',
        supplierImage: AppAssets.supplierMakmur,
        description: 'Tomat Grade B untuk kebutuhan rutin dapur dan olahan.',
        availableQuantity: '80 kg',
        distance: '8 km',
        reviews: [],
      ),
    ),
    BuyerConversation(
      farmerName: 'Bu Rini',
      farmName: 'Tani Sejahtera Pujon',
      initials: 'BR',
      preview: 'Harga kentang minggu ini tetap, Kak. Stoknya masih aman.',
      timeLabel: 'Kemarin',
      commodity: 'Kentang Dieng',
      unreadCount: 1,
      product: ProductDetailData(
        name: 'Kentang Dieng',
        price: 'Rp 14.000',
        image: AppAssets.productPotato,
        tags: ['Lokal', 'Grade A'],
        rating: 4.8,
        supplierName: 'Bu Rini',
        supplierLocation: 'Pujon, Malang',
        supplierImage: AppAssets.supplierMakmur,
        description: 'Kentang padat dan bersih untuk kebutuhan usaha kuliner.',
        availableQuantity: '120 kg',
        distance: '12 km',
        reviews: [],
      ),
    ),
    BuyerConversation(
      farmerName: 'Pak Darto',
      farmName: 'Kebun Makmur Batu',
      initials: 'PD',
      preview: 'Terima kasih, jadwal kirim cabai hari Kamis sudah dicatat.',
      timeLabel: 'Sen',
      commodity: 'Cabai Kering',
      product: ProductDetailData(
        name: 'Cabai Kering',
        price: 'Rp 38.000',
        image: AppAssets.productDriedChili,
        tags: ['Kering', 'Siap olah'],
        rating: 4.7,
        supplierName: 'Pak Darto',
        supplierLocation: 'Batu, Malang',
        supplierImage: AppAssets.supplierMakmur,
        description: 'Cabai kering pilihan dengan tingkat kekeringan stabil.',
        availableQuantity: '45 kg',
        distance: '16 km',
        reviews: [],
      ),
    ),
  ];
}

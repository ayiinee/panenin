import 'package:panenin/core/constants/app_assets.dart';

class BuyerOrderSummary {
  const BuyerOrderSummary({
    required this.name,
    required this.quality,
    required this.quantity,
    required this.price,
    required this.image,
    required this.seller,
    required this.deliveryDate,
    required this.status,
  });

  final String name;
  final String quality;
  final String quantity;
  final String price;
  final String image;
  final String seller;
  final String deliveryDate;
  final String status;
}

abstract final class BuyerOrdersFixture {
  static const active = [
    BuyerOrderSummary(
      name: 'Tomat Segar',
      quality: 'B',
      quantity: '50 kg',
      price: 'Rp 425.000',
      image: AppAssets.orderCherryTomato,
      seller: 'Pak Ferdi · Kelompok Tani Ambarawa',
      deliveryDate: '18 Juli 2026',
      status: 'Dalam pengiriman',
    ),
    BuyerOrderSummary(
      name: 'Kacang Panjang',
      quality: 'A',
      quantity: '10 kg',
      price: 'Rp 250.000',
      image: AppAssets.orderLongBeans,
      seller: 'Kelompok Tani Makmur',
      deliveryDate: '20 Juli 2026',
      status: 'Pesanan diterima',
    ),
    BuyerOrderSummary(
      name: 'Tomat Ceri Manis Banget',
      quality: 'A',
      quantity: '10 kg',
      price: 'Rp 250.000',
      image: AppAssets.orderChili,
      seller: 'Tani Sejahtera',
      deliveryDate: '21 Juli 2026',
      status: 'Menunggu konfirmasi petani',
    ),
    BuyerOrderSummary(
      name: 'Wortel Banget',
      quality: 'A',
      quantity: '10 kg',
      price: 'Rp 250.000',
      image: AppAssets.orderCarrot,
      seller: 'Kebun Bersama',
      deliveryDate: '22 Juli 2026',
      status: 'Pesanan diproses',
    ),
  ];

  static const history = [
    BuyerOrderSummary(
      name: 'Cabai Merah',
      quality: 'A',
      quantity: '10 kg',
      price: 'Rp 250.000',
      image: AppAssets.orderChili,
      seller: 'Tani Sejahtera',
      deliveryDate: '12 Juli 2026',
      status: 'Selesai',
    ),
  ];
}

import 'package:panenin/core/constants/app_assets.dart';

class ProductDetailData {
  const ProductDetailData({
    required this.name,
    required this.price,
    required this.image,
    required this.tags,
    required this.rating,
    required this.supplierName,
    required this.supplierLocation,
    required this.supplierImage,
    required this.description,
    required this.availableQuantity,
    required this.distance,
    required this.descriptionSupplier,
    required this.reviews,
  });

  final String name;
  final String price;
  final String image;
  final List<String> tags;
  final double rating;
  final String supplierName;
  final String supplierLocation;
  final String supplierImage;
  final String description;
  final String availableQuantity;
  final String distance;
  final String descriptionSupplier;
  final List<ProductReview> reviews;
}

class ProductReview {
  const ProductReview({
    required this.author,
    required this.avatar,
    required this.rating,
    required this.comment,
  });

  final String author;
  final String avatar;
  final int rating;
  final String comment;
}

/// Replaceable typed fixture until GET /api/v1/listings/{id} is integrated.
abstract final class ProductDetailFixture {
  static const design = ProductDetailData(
    name: 'Tomat Segar',
    price: 'Rp 49.500',
    image: AppAssets.productDetailTomato,
    tags: ['buah', 'Vitamin', 'Sehat'],
    rating: 4.9,
    supplierName: 'Kelompok Tani Makmur',
    supplierLocation: 'Kel. Sukomulyo, Kec. Pujon',
    supplierImage: AppAssets.supplierMakmur,
    description:
        'Tomat merah segar dengan kualitas premium dan pasokan stabil '
        'langsung dari kelompok tani terpercaya.',
    availableQuantity: '180 kg',
    distance: '10 km',
    descriptionSupplier: 'Kelompok Tani Lestari',
    reviews: [
      ProductReview(
        author: 'Es Buah Rosyidah',
        avatar: AppAssets.reviewEsBuah,
        rating: 5,
        comment:
            'Tomatnya segar dan terasa fresh ketika saya olah menjadi sebuah '
            'jus. Saya merekomendasikan teman teman agar bisa merasakannya',
      ),
      ProductReview(
        author: 'Tacibay',
        avatar: AppAssets.reviewTacibay,
        rating: 5,
        comment:
            'Saya sering memesan di sini untuk membuat sambal tomat untuk '
            'dipadukan dengan ayam geprek buatan saya',
      ),
    ],
  );
}

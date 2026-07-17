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
  final List<ProductReview> reviews;
}

class ProductDetailRouteArguments {
  const ProductDetailRouteArguments({
    required this.name,
    required this.price,
    required this.image,
  });

  final String name;
  final String price;
  final String image;
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
  static ProductDetailData fromRoute(ProductDetailRouteArguments product) {
    return ProductDetailData(
      name: product.name,
      price: product.price,
      image: product.image,
      tags: const ['Lokal', 'Pilihan', 'Sehat'],
      rating: 4.9,
      supplierName: 'Kelompok Tani Makmur',
      supplierLocation: 'Kel. Sukomulyo, Kec. Pujon',
      supplierImage: AppAssets.supplierMakmur,
      description:
          '${product.name} berkualitas premium dengan pasokan stabil langsung '
          'dari kelompok tani terpercaya.',
      availableQuantity: '180 kg',
      distance: '10 km',
      reviews: const [
        ProductReview(
          author: 'Es Buah Rosyidah',
          avatar: AppAssets.reviewEsBuah,
          rating: 5,
          comment:
              'Produknya segar dan kualitasnya sangat baik ketika diolah. '
              'Saya merekomendasikannya untuk kebutuhan usaha.',
        ),
        ProductReview(
          author: 'Tacibay',
          avatar: AppAssets.reviewTacibay,
          rating: 5,
          comment:
              'Saya sering memesan di sini karena kualitas produk dan '
              'pelayanannya selalu konsisten.',
        ),
      ],
    );
  }

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

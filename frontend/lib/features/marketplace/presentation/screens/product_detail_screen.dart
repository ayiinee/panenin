import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panenin/core/constants/app_colors.dart';
import 'package:panenin/features/marketplace/data/product_detail_fixture.dart';

enum ProductDetailViewState { loading, empty, error, success }

/// Buyer-facing listing detail with description and review tabs.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    this.state = ProductDetailViewState.success,
    this.data = ProductDetailFixture.design,
    super.key,
  });

  final ProductDetailViewState state;
  final ProductDetailData data;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const _designWidth = 428.0;
  bool _showReviews = false;
  int? _ratingFilter;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(constraints.maxWidth, _designWidth);
              return ColoredBox(
                color: Colors.white,
                child: Center(
                  child: SizedBox(
                    width: width,
                    height: constraints.maxHeight,
                    child: _buildState(width),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildState(double width) {
    return switch (widget.state) {
      ProductDetailViewState.loading => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      ProductDetailViewState.empty => _StateView(
        icon: Icons.inventory_2_outlined,
        title: 'Produk tidak ditemukan',
        message: 'Produk ini mungkin sudah tidak tersedia.',
        action: 'Kembali',
        onPressed: () => Navigator.maybePop(context),
      ),
      ProductDetailViewState.error => _StateView(
        icon: Icons.wifi_off_rounded,
        title: 'Gagal memuat produk',
        message: 'Periksa koneksi internet Anda, lalu coba lagi.',
        action: 'Coba Lagi',
        onPressed: () => _showMessage('Mencoba memuat detail produk...'),
      ),
      ProductDetailViewState.success => SingleChildScrollView(
        key: const ValueKey('product-detail-scroll'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProductHeader(
              onBack: () => Navigator.maybePop(context),
              onShare: () => _showMessage('Tautan produk siap dibagikan.'),
            ),
            _ProductOverview(data: widget.data, width: width),
            const SizedBox(
              height: 6,
              child: ColoredBox(color: Color(0xFFE8E8E8)),
            ),
            _SectionTabs(
              showReviews: _showReviews,
              onChanged: (showReviews) => setState(() {
                _showReviews = showReviews;
              }),
            ),
            if (_showReviews)
              _ReviewsSection(
                reviews: widget.data.reviews,
                ratingFilter: _ratingFilter,
                onFilterChanged: (rating) => setState(() {
                  _ratingFilter = rating;
                }),
                onAddReview: () => _showMessage(
                  'Formulir ulasan akan tersedia setelah pesanan selesai.',
                ),
              )
            else
              _DescriptionSection(data: widget.data, onAction: _showMessage),
          ],
        ),
      ),
    };
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.onBack, required this.onShare});

  final VoidCallback onBack;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 57,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'Detail Produk',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 24 / 16,
            ),
          ),
          Positioned(
            left: 28,
            child: _RoundIconButton(
              key: const ValueKey('product-detail-back'),
              tooltip: 'Kembali',
              icon: Icons.arrow_back,
              onPressed: onBack,
            ),
          ),
          Positioned(
            right: 28,
            child: _RoundIconButton(
              key: const ValueKey('product-detail-share'),
              tooltip: 'Bagikan produk',
              icon: Icons.share_rounded,
              onPressed: onShare,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          foregroundColor: AppColors.primary,
        ),
        icon: Icon(icon, size: 22),
      ),
    );
  }
}

class _ProductOverview extends StatelessWidget {
  const _ProductOverview({required this.data, required this.width});

  final ProductDetailData data;
  final double width;

  @override
  Widget build(BuildContext context) {
    final compact = width < 380;
    return SizedBox(
      height: 531,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: width,
            height: 355,
            child: Image.asset(data.image, fit: BoxFit.cover),
          ),
          Positioned(
            top: 322,
            left: 0,
            right: 0,
            child: Container(
              height: 215,
              padding: EdgeInsets.fromLTRB(compact ? 18 : 25, 15, 20, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 22 / 14,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    data.price,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      height: 32 / 24,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      for (
                        var index = 0;
                        index < data.tags.length;
                        index++
                      ) ...[
                        Flexible(child: _TagPill(label: data.tags[index])),
                        if (index != data.tags.length - 1)
                          const SizedBox(width: 4),
                      ],
                      const Spacer(),
                      _RatingPill(rating: data.rating),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFE6DDD8)),
                  const SizedBox(height: 7),
                  Expanded(
                    child: Row(
                      children: [
                        _SupplierLogo(asset: data.supplierImage),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.supplierName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                data.supplierLocation,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF448D54),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Terverifikasi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierLogo extends StatelessWidget {
  const _SupplierLogo({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox.square(
        dimension: 42,
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: 190,
          maxWidth: 190,
          child: Image.asset(asset, width: 190, height: 44, fit: BoxFit.fill),
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 21,
      constraints: const BoxConstraints(minWidth: 55, maxWidth: 105),
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFA8A29E)),
        borderRadius: BorderRadius.circular(15),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          height: 16 / 11,
        ),
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 21,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        border: Border.all(color: const Color(0xFFA8A29E)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFF5A400), size: 14),
          Text(
            ' ${rating.toStringAsFixed(1)}/5.0',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTabs extends StatelessWidget {
  const _SectionTabs({required this.showReviews, required this.onChanged});

  final bool showReviews;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE6DDD8))),
      ),
      child: Row(
        children: [
          const Spacer(),
          _TabButton(
            label: 'Deskripsi',
            selected: !showReviews,
            onPressed: () => onChanged(false),
          ),
          const SizedBox(width: 112),
          _TabButton(
            key: const ValueKey('product-reviews-tab'),
            label: 'Ulasan',
            selected: showReviews,
            onPressed: () => onChanged(true),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: SizedBox(
        width: 74,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 1.5,
              color: selected ? AppColors.textPrimary : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.data, required this.onAction});

  final ProductDetailData data;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 20, 52),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            data.description,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 22 / 14,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tersedia: ${data.availableQuantity}\n'
            'Jarak: ${data.distance}\n'
            'Supplier: ${data.descriptionSupplier}\n'
            'Rating: ${data.rating.toStringAsFixed(1)}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 22 / 14,
            ),
          ),
          const SizedBox(height: 42),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              key: const ValueKey('supply-contract-button'),
              onPressed: () =>
                  onAction('Membuka permintaan kontrak pasokan...'),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Buat Kontrak Pasokan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => onAction('Membuka negosiasi harga...'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Negosiasi Harga',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () =>
                        onAction('Produk siap ditambahkan ke pesanan.'),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Beli Sekarang',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({
    required this.reviews,
    required this.ratingFilter,
    required this.onFilterChanged,
    required this.onAddReview,
  });

  final List<ProductReview> reviews;
  final int? ratingFilter;
  final ValueChanged<int?> onFilterChanged;
  final VoidCallback onAddReview;

  @override
  Widget build(BuildContext context) {
    final visibleReviews = ratingFilter == null
        ? reviews
        : reviews.where((review) => review.rating == ratingFilter).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 37),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 19),
            child: Row(
              children: [
                _ReviewFilter(
                  label: 'Semua',
                  selected: ratingFilter == null,
                  onPressed: () => onFilterChanged(null),
                ),
                for (var rating = 5; rating >= 1; rating--) ...[
                  const SizedBox(width: 5),
                  _ReviewFilter(
                    label: 'Bintang $rating',
                    selected: ratingFilter == rating,
                    onPressed: () => onFilterChanged(rating),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 7),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 44,
                child: Center(
                  child: ElevatedButton.icon(
                    key: const ValueKey('add-review-button'),
                    onPressed: onAddReview,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      minimumSize: const Size(156, 29),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 19),
                    label: const Text(
                      'Tambah Ulasan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (visibleReviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 38),
              child: Text(
                'Belum ada ulasan untuk rating ini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            )
          else
            for (var index = 0; index < visibleReviews.length; index++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 23),
                child: _ReviewCard(review: visibleReviews[index]),
              ),
              if (index != visibleReviews.length - 1)
                const SizedBox(height: 13),
            ],
        ],
      ),
    );
  }
}

class _ReviewFilter extends StatelessWidget {
  const _ReviewFilter({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white,
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: selected ? 14 : 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final ProductReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.textPrimary),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 39,
                height: 39,
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(review.avatar, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.author,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 18 / 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          review.rating,
                          (_) => const Icon(
                            Icons.star_rounded,
                            color: AppColors.accent,
                            size: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            review.comment,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              height: 15 / 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StateView extends StatelessWidget {
  const _StateView({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 48),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onPressed, child: Text(action)),
          ],
        ),
      ),
    );
  }
}

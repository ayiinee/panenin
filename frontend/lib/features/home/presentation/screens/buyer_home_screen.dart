import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panenin/core/constants/app_assets.dart';
import 'package:panenin/core/constants/app_colors.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/features/home/data/buyer_home_fixture.dart';

enum BuyerHomeViewState { loading, empty, error, success }

/// Buyer landing page shown after the UMKM profile is completed.
class BuyerHomeScreen extends StatelessWidget {
  const BuyerHomeScreen({
    this.state = BuyerHomeViewState.success,
    this.data = BuyerHomeFixture.design,
    super.key,
  });

  static const _designWidth = 428.0;

  final BuyerHomeViewState state;
  final BuyerHomeData data;

  void _showMessage(BuildContext context, String message) {
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
              final pageWidth = math.min(constraints.maxWidth, _designWidth);
              return ColoredBox(
                color: Colors.white,
                child: Center(
                  child: SizedBox(
                    width: pageWidth,
                    height: constraints.maxHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(child: _buildBody(context, pageWidth)),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: BuyerBottomNavigation(
                            onUnavailable: (label) => _showMessage(
                              context,
                              '$label akan segera tersedia.',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, double pageWidth) {
    return switch (state) {
      BuyerHomeViewState.loading => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      BuyerHomeViewState.empty => _HomeStateView(
        icon: Icons.inventory_2_outlined,
        title: 'Komoditas belum tersedia',
        message: 'Coba kembali sebentar lagi untuk melihat pasokan terbaru.',
        action: 'Muat Ulang',
        onPressed: () => _showMessage(context, 'Memuat ulang komoditas...'),
      ),
      BuyerHomeViewState.error => _HomeStateView(
        icon: Icons.wifi_off_rounded,
        title: 'Gagal memuat beranda',
        message: 'Periksa koneksi internet Anda, lalu coba lagi.',
        action: 'Coba Lagi',
        onPressed: () => _showMessage(context, 'Mencoba memuat beranda...'),
      ),
      BuyerHomeViewState.success => _BuyerHomeContent(
        data: data,
        compact: pageWidth < 390,
        onAction: (message) => _showMessage(context, message),
      ),
    };
  }
}

class _BuyerHomeContent extends StatelessWidget {
  const _BuyerHomeContent({
    required this.data,
    required this.compact,
    required this.onAction,
  });

  final BuyerHomeData data;
  final bool compact;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = compact ? 16.0 : 20.0;
    return SingleChildScrollView(
      key: const ValueKey('buyer-home-scroll'),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        7,
        horizontalPadding,
        116,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BuyerHeader(
            locationLabel: data.locationLabel,
            location: data.location,
            onAction: onAction,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: TextField(
              key: const ValueKey('buyer-home-search'),
              onSubmitted: (value) => onAction(
                value.trim().isEmpty
                    ? 'Masukkan komoditas yang ingin dicari.'
                    : 'Mencari $value...',
              ),
              decoration: InputDecoration(
                hintText: 'Cari sayuran, buah, atau petani...',
                hintStyle: const TextStyle(
                  color: Color(0xFFA1A9B8),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF868FA0),
                  size: 20,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: const BorderSide(color: Color(0xFFD9DDE4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SupplyBanner(
            onPressed: () => onAction('Membuka semua komoditas...'),
          ),
          const SizedBox(height: 20),
          const Text(
            'Komoditas Cepat',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 24 / 16,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: data.categories
                .map(
                  (category) => _CategoryButton(
                    category: category,
                    compact: compact,
                    onPressed: () =>
                        onAction('Menampilkan komoditas ${category.name}.'),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const ValueKey('see-all-products'),
              onPressed: () => onAction('Membuka semua komoditas...'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                minimumSize: const Size(88, 44),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Lihat Semua',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          GridView.builder(
            key: const ValueKey('buyer-product-grid'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.products.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: compact ? 10 : 15,
              mainAxisSpacing: 14,
              mainAxisExtent: compact ? 280 : 300,
            ),
            itemBuilder: (context, index) => _ProductCard(
              product: data.products[index],
              compact: compact,
              onOpen: () =>
                  Navigator.pushNamed(context, RouteNames.productDetail),
              onAdd: () => onAction(
                '${data.products[index].name} ditambahkan ke keranjang.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuyerHeader extends StatelessWidget {
  const _BuyerHeader({
    required this.locationLabel,
    required this.location,
    required this.onAction,
  });

  final String locationLabel;
  final String location;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: AppColors.primary,
            size: 28,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locationLabel,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 18 / 12,
                  ),
                ),
                Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 18 / 12,
                  ),
                ),
              ],
            ),
          ),
          _HeaderAction(
            tooltip: 'Notifikasi',
            icon: Icons.notifications_none_rounded,
            onPressed: () => onAction('Belum ada notifikasi baru.'),
          ),
          _HeaderAction(
            tooltip: 'Keranjang',
            icon: Icons.shopping_cart_outlined,
            onPressed: () => onAction('Keranjang belanja masih kosong.'),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      padding: EdgeInsets.zero,
      icon: Icon(icon, color: AppColors.primary, size: 25),
    );
  }
}

class _SupplyBanner extends StatelessWidget {
  const _SupplyBanner({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 172,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF537832), Color(0xFF2B472E), Color(0xFF537832)],
              stops: [0, 0.45, 1],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 19,
                left: 20,
                width: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pasokan rutin,\nusaha makin pasti',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 28 / 20,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Dapatkan bahan baku segar langsung\ndari kelompok terpercaya.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 16 / 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: ElevatedButton(
                          key: const ValueKey('find-commodities-button'),
                          onPressed: onPressed,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(144, 30),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            elevation: 3,
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cari Komoditas',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -14,
                right: -43,
                width: 232,
                height: 210,
                child: Image.asset(
                  AppAssets.buyerHomeBanner,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.category,
    required this.compact,
    required this.onPressed,
  });

  final BuyerHomeCategory category;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 52.0 : 60.0;
    return Semantics(
      button: true,
      label: 'Lihat ${category.name}',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(36),
        child: SizedBox(
          width: compact ? 55 : 64,
          child: Column(
            children: [
              ClipOval(
                child: Image.asset(
                  category.asset,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    height: 16 / 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.compact,
    required this.onOpen,
    required this.onAdd,
  });

  final BuyerHomeProduct product;
  final bool compact;
  final VoidCallback onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Buka detail ${product.name}',
      child: InkWell(
        key: ValueKey('open-${product.name}'),
        onTap: onOpen,
        borderRadius: BorderRadius.circular(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                offset: Offset(0, 4),
                blurRadius: 4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: Image.asset(product.asset, fit: BoxFit.cover)),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 5 : 7,
                    6,
                    compact ? 5 : 7,
                    4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          height: 20 / 14,
                        ),
                      ),
                      Text(
                        product.price,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 22 / 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Row(
                        children: [
                          _ProductTag(label: 'Bisa COD'),
                          SizedBox(width: 3),
                          Flexible(
                            child: _ProductTag(
                              label: 'Jakarta Utara',
                              icon: Icons.location_on,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 44,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: ValueKey('add-${product.name}'),
                            onTap: onAdd,
                            borderRadius: BorderRadius.circular(8),
                            child: Center(
                              child: Container(
                                height: 30,
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.primary),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shopping_cart_outlined,
                                      color: Colors.black,
                                      size: 23,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Tambah',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
      ),
    );
  }
}

class _ProductTag extends StatelessWidget {
  const _ProductTag({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF9A4600), width: 0.5),
        borderRadius: BorderRadius.circular(4.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 10, color: const Color(0xFF5C2700)),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF5C2700),
                fontSize: 8.9,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BuyerBottomNavigation extends StatelessWidget {
  const BuyerBottomNavigation({required this.onUnavailable, super.key});

  final ValueChanged<String> onUnavailable;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 98,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 74,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFFFEDD5))),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x26E47A32),
                  offset: Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                const Expanded(
                  child: _NavigationItem(
                    icon: Icons.home_outlined,
                    label: 'Beranda',
                    selected: true,
                  ),
                ),
                Expanded(
                  child: _NavigationItem(
                    icon: Icons.message_outlined,
                    label: 'Pesan',
                    onPressed: () => onUnavailable('Pesan'),
                  ),
                ),
                const Expanded(child: SizedBox()),
                Expanded(
                  child: _NavigationItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'Transaksi',
                    onPressed: () => onUnavailable('Transaksi'),
                  ),
                ),
                Expanded(
                  child: _NavigationItem(
                    icon: Icons.person_outline,
                    label: 'Profil',
                    onPressed: () => onUnavailable('Profil'),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: Column(
              children: [
                Material(
                  color: const Color(0xFF847C7C),
                  elevation: 8,
                  shadowColor: const Color(0xFFA8A29E),
                  shape: const CircleBorder(
                    side: BorderSide(color: Colors.white, width: 4),
                  ),
                  child: InkWell(
                    key: const ValueKey('maps-navigation'),
                    onTap: () => onUnavailable('Maps'),
                    customBorder: const CircleBorder(),
                    child: const SizedBox.square(
                      dimension: 64,
                      child: Icon(
                        Icons.map_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Maps',
                  style: TextStyle(
                    color: Color(0xFFA8A29E),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 15 / 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : const Color(0xFFA8A29E);
    return InkWell(
      onTap: onPressed,
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeStateView extends StatelessWidget {
  const _HomeStateView({
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
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 110),
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
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onPressed, child: Text(action)),
          ],
        ),
      ),
    );
  }
}

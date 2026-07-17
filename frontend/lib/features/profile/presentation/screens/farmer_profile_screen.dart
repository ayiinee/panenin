import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/app/shell/panenin_bottom_navigation.dart';
import 'package:panenin/app/theme/app_colors.dart';

class FarmerProfileScreen extends StatelessWidget {
  const FarmerProfileScreen({this.embeddedInShell = false, super.key});

  final bool embeddedInShell;

  void _openDestination(BuildContext context, int index) {
    if (index == 3) return;
    final route = switch (index) {
      0 => RouteNames.homePetani,
      1 => RouteNames.stokSaya,
      2 => RouteNames.kelolaPesanan,
      _ => RouteNames.farmerProfile,
    };
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAF6),
        bottomNavigationBar: embeddedInShell
            ? null
            : PaneninBottomNavigation(
                selectedIndex: 3,
                onDestinationSelected: (index) =>
                    _openDestination(context, index),
              ),
        body: CustomScrollView(
          key: const ValueKey('farmer-profile-scroll'),
          slivers: [
            const SliverToBoxAdapter(child: _ProfileHeader()),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                92 + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverList.list(
                children: [
                  const _FarmerIdentityCard(),
                  const SizedBox(height: 18),
                  _ProfileAction(
                    icon: Icons.person_outline_rounded,
                    title: 'Data Diri',
                    subtitle: 'Nama, kelompok tani, dan alamat',
                    onTap: () => _comingSoon(context),
                  ),
                  _ProfileAction(
                    icon: Icons.eco_outlined,
                    title: 'Komoditas Penjualan',
                    subtitle: 'Kelola komoditas yang Anda tawarkan',
                    onTap: () => _comingSoon(context),
                  ),
                  _ProfileAction(
                    icon: Icons.location_on_outlined,
                    title: 'Lokasi Kebun',
                    subtitle: 'Atur lokasi pengambilan hasil panen',
                    onTap: () => _comingSoon(context),
                  ),
                  _ProfileAction(
                    icon: Icons.help_outline_rounded,
                    title: 'Bantuan',
                    subtitle: 'Panduan dan dukungan Panenin',
                    onTap: () => _comingSoon(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Fitur ini akan segera tersedia.')),
      );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primaryLight,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: const SafeArea(
        bottom: false,
        child: Text(
          'Profile Petani',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _FarmerIdentityCard extends StatelessWidget {
  const _FarmerIdentityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/home/farmer_avatar.png',
              width: 68,
              height: 68,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alvin',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'Kelompok Tani Makmur',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                SizedBox(height: 6),
                Text(
                  'Petani terverifikasi',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0x1F000000)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        minTileHeight: 68,
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          foregroundColor: AppColors.primary,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/app/shell/panenin_bottom_navigation.dart';
import 'package:panenin/app/theme/app_colors.dart';
import 'package:panenin/features/auth/data/auth_service.dart';
import 'package:panenin/features/profile/data/whatsapp_service.dart';

typedef ProfileActionCallback = Future<void> Function();

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({
    this.embeddedInShell = false,
    this.signOut,
    this.openWhatsApp,
    super.key,
  });

  final bool embeddedInShell;
  final ProfileActionCallback? signOut;
  final ProfileActionCallback? openWhatsApp;

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  bool _isSigningOut = false;
  bool _isOpeningWhatsApp = false;

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

  Future<void> _connectWhatsApp() async {
    if (_isOpeningWhatsApp) return;
    setState(() => _isOpeningWhatsApp = true);
    try {
      await (widget.openWhatsApp ??
          const WhatsAppService().openConnectionChat)();
    } on WhatsAppLaunchException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage('Gagal membuka WhatsApp. Silakan coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _isOpeningWhatsApp = false);
    }
  }

  Future<void> _confirmSignOut() async {
    if (_isSigningOut) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Anda perlu masuk kembali untuk mengelola panen dan pesanan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB3261E),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSigningOut = true);
    try {
      await (widget.signOut ?? AuthService.create().signOut)();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(RouteNames.login, (_) => false);
    } catch (_) {
      if (mounted) {
        setState(() => _isSigningOut = false);
        _showMessage('Gagal keluar dari akun. Silakan coba lagi.');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
        bottomNavigationBar: widget.embeddedInShell
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
                    icon: const Icon(Icons.person_outline_rounded),
                    title: 'Data Diri',
                    subtitle: 'Nama, kelompok tani, dan alamat',
                    onTap: () => _comingSoon(context),
                  ),
                  _ProfileAction(
                    icon: const Icon(Icons.eco_outlined),
                    title: 'Komoditas Penjualan',
                    subtitle: 'Kelola komoditas yang Anda tawarkan',
                    onTap: () => _comingSoon(context),
                  ),
                  _ProfileAction(
                    icon: const Icon(Icons.location_on_outlined),
                    title: 'Lokasi Kebun',
                    subtitle: 'Atur lokasi pengambilan hasil panen',
                    onTap: () => _comingSoon(context),
                  ),
                  _ProfileAction(
                    key: const ValueKey('connect-whatsapp-action'),
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 22),
                    title: 'Hubungkan WhatsApp',
                    subtitle: 'Kelola panen dan pesanan lewat WhatsApp',
                    onTap: _connectWhatsApp,
                    isLoading: _isOpeningWhatsApp,
                    foregroundColor: const Color(0xFF128C3E),
                  ),
                  _ProfileAction(
                    icon: const Icon(Icons.help_outline_rounded),
                    title: 'Bantuan',
                    subtitle: 'Panduan dan dukungan Panenin',
                    onTap: () => _comingSoon(context),
                  ),
                  const SizedBox(height: 8),
                  _ProfileAction(
                    key: const ValueKey('sign-out-action'),
                    icon: const Icon(Icons.logout_rounded),
                    title: 'Keluar',
                    subtitle: 'Keluar dari akun Panenin',
                    onTap: _confirmSignOut,
                    isLoading: _isSigningOut,
                    foregroundColor: const Color(0xFFB3261E),
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
    this.isLoading = false,
    this.foregroundColor = AppColors.primary,
    super.key,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLoading;
  final Color foregroundColor;

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
        enabled: !isLoading,
        leading: CircleAvatar(
          backgroundColor: foregroundColor.withValues(alpha: 0.1),
          foregroundColor: foregroundColor,
          child: icon,
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w700, color: foregroundColor),
        ),
        subtitle: Text(subtitle),
        trailing: isLoading
            ? SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foregroundColor,
                ),
              )
            : Icon(Icons.chevron_right_rounded, color: foregroundColor),
        onTap: isLoading ? null : onTap,
      ),
    );
  }
}

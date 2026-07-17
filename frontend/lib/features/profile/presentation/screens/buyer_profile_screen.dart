import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/core/constants/app_colors.dart';
import 'package:panenin/features/profile/data/buyer_profile_fixture.dart';
import 'package:panenin/shared/widgets/buyer_bottom_navigation.dart';

enum BuyerProfileViewState { loading, empty, error, success }

class BuyerProfileScreen extends StatelessWidget {
  const BuyerProfileScreen({
    this.state = BuyerProfileViewState.success,
    this.data = BuyerProfileFixture.design,
    super.key,
  });

  static const _designWidth = 428.0;
  final BuyerProfileViewState state;
  final BuyerProfileData data;

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: AppColors.profileBackground,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.profileBackground,
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(constraints.maxWidth, _designWidth);
              return Center(
                child: SizedBox(
                  width: width,
                  height: constraints.maxHeight,
                  child: Stack(
                    children: [
                      Positioned.fill(child: _body(context, width < 390)),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: BuyerBottomNavigation(
                          selected: BuyerNavigationDestination.profile,
                          onHome: () => Navigator.pushReplacementNamed(
                            context,
                            RouteNames.buyerHome,
                          ),
                          onTransactions: () => Navigator.pushReplacementNamed(
                            context,
                            RouteNames.buyerOrders,
                          ),
                          onProfile: () {},
                          onUnavailable: (label) =>
                              _message(context, '$label akan segera tersedia.'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, bool compact) => switch (state) {
    BuyerProfileViewState.loading => const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    ),
    BuyerProfileViewState.empty => _ProfileState(
      icon: Icons.person_add_alt_1_outlined,
      title: 'Profil usaha belum lengkap',
      message: 'Lengkapi data UMKM agar rekomendasi pasokan lebih sesuai.',
      action: 'Lengkapi Profil',
      onPressed: () => _message(context, 'Membuka formulir profil...'),
    ),
    BuyerProfileViewState.error => _ProfileState(
      icon: Icons.cloud_off_outlined,
      title: 'Gagal memuat profil',
      message: 'Periksa koneksi internet Anda, lalu coba lagi.',
      action: 'Coba Lagi',
      onPressed: () => _message(context, 'Mencoba memuat profil...'),
    ),
    BuyerProfileViewState.success => _ProfileContent(
      data: data,
      compact: compact,
      onAction: (message) => _message(context, message),
      onLogout: () => _confirmLogout(context),
    ),
  };

  Future<void> _confirmLogout(BuildContext context) async {
    final logout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Anda perlu masuk kembali untuk mengelola kebutuhan usaha.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (logout == true && context.mounted) {
      _message(context, 'Sesi siap diakhiri setelah autentikasi terhubung.');
    }
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.data,
    required this.compact,
    required this.onAction,
    required this.onLogout,
  });
  final BuyerProfileData data;
  final bool compact;
  final ValueChanged<String> onAction;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('buyer-profile-scroll'),
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 20,
        10,
        compact ? 16 : 20,
        122,
      ),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Profil Usaha',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            _RoundAction(
              icon: Icons.notifications_none_rounded,
              label: 'Notifikasi',
              onTap: () => onAction('Belum ada notifikasi baru.'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _IdentityCard(
          data: data,
          onEdit: () => onAction('Membuka editor profil usaha...'),
        ),
        const SizedBox(height: 14),
        const SizedBox(height: 14),
        _WhatsappCard(
          connected: data.whatsappConnected,
          phone: data.phone,
          onPressed: () => onAction('Membuka pengaturan WhatsApp...'),
        ),
        const SizedBox(height: 22),
        const _SectionTitle(
          title: 'Usaha & Pengadaan',
          subtitle: 'Informasi yang membantu Panenin mencarikan pasokan.',
        ),
        const SizedBox(height: 10),
        _SettingsCard(
          children: [
            _SettingTile(
              icon: Icons.storefront_outlined,
              title: 'Informasi usaha',
              subtitle: data.businessType,
              onTap: () => onAction('Membuka informasi usaha...'),
            ),
            _SettingTile(
              icon: Icons.location_on_outlined,
              title: 'Alamat pengiriman',
              subtitle: data.address,
              onTap: () => onAction('Membuka alamat pengiriman...'),
            ),
            _SettingTile(
              icon: Icons.eco_outlined,
              title: 'Komoditas rutin',
              subtitle: data.commodities.join(' • '),
              onTap: () => onAction('Membuka komoditas rutin...'),
              last: true,
            ),
          ],
        ),
        const SizedBox(height: 22),
        const _SectionTitle(
          title: 'Akun',
          subtitle: 'Keamanan, bantuan, dan preferensi aplikasi.',
        ),
        const SizedBox(height: 10),
        _SettingsCard(
          children: [
            _SettingTile(
              icon: Icons.person_outline,
              title: 'Data akun',
              subtitle: data.email,
              onTap: () => onAction('Membuka data akun...'),
            ),
            _SettingTile(
              icon: Icons.lock_outline,
              title: 'Keamanan akun',
              subtitle: 'Kata sandi dan perangkat',
              onTap: () => onAction('Membuka keamanan akun...'),
            ),
            _SettingTile(
              icon: Icons.help_outline,
              title: 'Pusat bantuan',
              subtitle: 'Panduan menggunakan Panenin',
              onTap: () => onAction('Membuka pusat bantuan...'),
              last: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const ValueKey('logout-button'),
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Keluar dari Akun'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            foregroundColor: AppColors.profileDanger,
            side: const BorderSide(color: AppColors.profileDangerBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Panenin 1.0.0',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.data, required this.onEdit});
  final BuyerProfileData data;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x292F6B3F),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Semantics(
          label: 'Foto profil ${data.ownerName}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              data.imagePath,
              width: 68,
              height: 68,
              fit: BoxFit.cover,
              semanticLabel: 'Foto profil ${data.ownerName}',
              errorBuilder: (context, error, stackTrace) => Container(
                width: 68,
                height: 68,
                alignment: Alignment.center,
                color: const Color(0xFFFFF3D1),
                child: Text(
                  data.initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.businessName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                data.ownerName,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 15,
                      color: Color(0xFFFFD76A),
                    ),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Buyer terverifikasi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
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
        _RoundAction(
          icon: Icons.edit_outlined,
          label: 'Edit profil',
          light: true,
          onTap: onEdit,
        ),
      ],
    ),
  );
}

// ignore: unused_element
class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.data, required this.onPressed});
  final BuyerProfileData data;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFBEB),
      border: Border.all(color: const Color(0xFFFDE7A7)),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_outlined, color: Color(0xFFA16207)),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profil pengadaan hampir siap',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tambahkan jadwal belanja rutin',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${data.completedFields}/${data.totalFields}',
              style: const TextStyle(
                color: Color(0xFFA16207),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: data.completion,
            minHeight: 7,
            backgroundColor: const Color(0xFFF5E7B7),
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onPressed,
            child: const Text('Lengkapi sekarang  →'),
          ),
        ),
      ],
    ),
  );
}

class _WhatsappCard extends StatelessWidget {
  const _WhatsappCard({
    required this.connected,
    required this.phone,
    required this.onPressed,
  });
  final bool connected;
  final String phone;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.profileSubtleBorder),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F7EC),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WhatsApp Companion',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    connected ? '$phone • Terhubung' : 'Belum terhubung',
                    style: TextStyle(
                      color: connected
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          height: 1.4,
        ),
      ),
    ],
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.profileBorder),
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(children: children),
  );
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.last = false,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool last;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.vertical(
      top: const Radius.circular(18),
      bottom: last ? const Radius.circular(18) : Radius.zero,
    ),
    child: Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFEEF1EF))),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.profileSoftSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
        ],
      ),
    ),
  );
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.light = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool light;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Material(
      color: light ? Colors.white.withValues(alpha: .15) : Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: 44,
          child: Icon(
            icon,
            size: 21,
            color: light ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    ),
  );
}

class _ProfileState extends StatelessWidget {
  const _ProfileState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onPressed,
  });
  final IconData icon;
  final String title, message;
  final String? action;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 100),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 52),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          if (action != null) ...[
            const SizedBox(height: 20),
            FilledButton(onPressed: onPressed, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}

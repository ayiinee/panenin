import 'package:flutter/material.dart';
import 'package:panenin/app/theme/app_colors.dart';
import 'package:panenin/shared/widgets/app_button.dart';

class DemandRequestCard extends StatelessWidget {
  const DemandRequestCard({
    required this.onAccept,
    required this.onReject,
    required this.onNegotiate,
    super.key,
  });

  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onNegotiate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          const _BuyerIdentity(),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(minHeight: 57),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.centerLeft,
            child: const Text(
              '"Ingin langganan Cabai Merah 10 kg tiap Selasa & Jumat..."',
              style: TextStyle(
                color: Color(0xFF1B1C1C),
                fontSize: 14,
                height: 24 / 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const SizedBox(
            height: 28,
            child: Row(
              children: [
                Icon(
                  Icons.verified_user,
                  size: 17,
                  color: AppColors.secureFund,
                ),
                SizedBox(width: 4),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'DP sudah di Dana Aman',
                      maxLines: 1,
                      style: TextStyle(
                        color: AppColors.secureFund,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          AppButton(label: 'Terima Permintaan', onPressed: onAccept),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Negosiasi',
                  variant: AppButtonVariant.accent,
                  onPressed: onNegotiate,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: AppButton(
                  label: 'Tolak',
                  variant: AppButtonVariant.danger,
                  onPressed: onReject,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BuyerIdentity extends StatelessWidget {
  const _BuyerIdentity();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipOval(
          child: Image.asset(
            'assets/images/home/buyer_avatar.png',
            width: 47,
            height: 47,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mbak Rina',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Mango Sticky Rice Sigura-Gura',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

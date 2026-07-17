import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/core/constants/app_assets.dart';
import 'package:panenin/core/constants/app_colors.dart';
import 'package:panenin/core/network/api_exception.dart';
import 'package:panenin/core/validation/input_validators.dart';
import 'package:panenin/features/auth/domain/user_role.dart';
import 'package:panenin/features/profile/data/profile_repository.dart';

typedef SaveProfileRole = Future<void> Function(UserRole role);

/// Collects the role-specific basic profile after account registration.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({
    this.role = UserRole.farmer,
    this.repository,
    this.saveRole,
    super.key,
  });

  final UserRole role;
  final ProfileRepository? repository;
  final SaveProfileRole? saveRole;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  static const _designWidth = 428.0;
  static const _designHeight = 926.0;
  static const _commodities = [
    'Cabai Merah',
    'Tomat',
    'Kentang',
    'Bawang Merah',
    'Kacang Panjang',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _organizationNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _selectedCommodities = <String>{};

  bool _acceptedTerms = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _organizationNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    return InputValidators.requiredText(
      value,
      label: 'Bagian ini',
      minLength: 2,
      maxLength: 300,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _chooseLocation() {
    FocusManager.instance.primaryFocus?.unfocus();
    _showMessage('Pemilihan lokasi di peta akan segera tersedia.');
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_acceptedTerms) {
      _showMessage('Setujui Syarat & Ketentuan untuk melanjutkan.');
      return;
    }
    if (_selectedCommodities.isEmpty) {
      _showMessage(
        widget.role == UserRole.buyer
            ? 'Pilih minimal satu kategori produk UMKM.'
            : 'Pilih minimal satu komoditas penjualan.',
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      if (widget.repository case final repository?) {
        final organizationName = _organizationNameController.text.trim();
        await repository.saveProfile(
          ProfileInput(
            name: _nameController.text.trim(),
            organizationName: organizationName.isEmpty
                ? 'Usaha ${_nameController.text.trim()}'
                : organizationName,
            role: widget.role,
            address: _addressController.text.trim(),
            commodityNames: _selectedCommodities.toList()..sort(),
          ),
        );
      } else if (widget.saveRole == null) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
      if (widget.saveRole case final saveRole?) {
        await saveRole(widget.role);
      }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage(
        error is ApiException
            ? error.message
            : 'Data diri gagal disimpan. Silakan coba lagi.',
      );
      return;
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    final destination = widget.role == UserRole.buyer
        ? RouteNames.buyerHome
        : RouteNames.homePetani;
    Navigator.pushNamedAndRemoveUntil(context, destination, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isBuyer = widget.role == UserRole.buyer;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final pageWidth = math.min(constraints.maxWidth, _designWidth);
            final pageHeight = math.max(constraints.maxHeight, _designHeight);

            return ColoredBox(
              color: Colors.white,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: pageHeight,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: pageWidth,
                      height: pageHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            top: 41,
                            child: Image.asset(
                              AppAssets.profileBackground,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                          const Positioned(
                            top: 148,
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(29),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x40000000),
                                    offset: Offset(0, -3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 221,
                            left: pageWidth < 390 ? 16 : 20,
                            right: pageWidth < 390 ? 16 : 21,
                            child: Form(
                              key: _formKey,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Silahkan Isi Data Diri Anda',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      height: 32 / 24,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Lengkapi Data Anda untuk Bergabung',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      height: 22 / 14,
                                    ),
                                  ),
                                  const SizedBox(height: 29),
                                  const Align(
                                    alignment: Alignment.centerRight,
                                    child: Icon(
                                      Icons.map_outlined,
                                      color: Colors.black,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _ProfileTextField(
                                    key: ValueKey(
                                      isBuyer
                                          ? 'buyer-name-field'
                                          : 'farmer-name-field',
                                    ),
                                    controller: _nameController,
                                    label: isBuyer
                                        ? 'Nama Pengguna'
                                        : 'Nama Petani',
                                    hint: isBuyer
                                        ? 'Masukkan nama pengguna'
                                        : 'Masukkan nama petani',
                                    validator: _required,
                                    maxLength: 80,
                                  ),
                                  const SizedBox(height: 12),
                                  _FieldLabel(
                                    isBuyer
                                        ? 'Kategori Produk UMKM'
                                        : 'Komoditas Penjualan',
                                  ),
                                  Wrap(
                                    spacing: 3,
                                    runSpacing: 4,
                                    children: _commodities.map((commodity) {
                                      final selected = _selectedCommodities
                                          .contains(commodity);
                                      return _CommodityChip(
                                        label: commodity,
                                        selected: selected,
                                        onPressed: () => setState(() {
                                          if (selected) {
                                            _selectedCommodities.remove(
                                              commodity,
                                            );
                                          } else {
                                            _selectedCommodities.add(commodity);
                                          }
                                        }),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 12),
                                  _ProfileTextField(
                                    key: ValueKey(
                                      isBuyer
                                          ? 'buyer-business-field'
                                          : 'farmer-group-field',
                                    ),
                                    controller: _organizationNameController,
                                    label: isBuyer
                                        ? 'Nama Bisnis (Opsional)'
                                        : 'Nama Kelompok Tani',
                                    hint: isBuyer
                                        ? 'Masukkan nama bisnis'
                                        : 'Masukkan nama kelompok tani',
                                    validator: isBuyer ? null : _required,
                                    maxLength: 120,
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 153,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        _ProfileTextField(
                                          key: const ValueKey('address-field'),
                                          controller: _addressController,
                                          label: 'Alamat',
                                          hint: 'Tambahkan alamatmu',
                                          validator: _required,
                                          maxLines: 3,
                                          maxLength: 300,
                                        ),
                                        Positioned(
                                          top: 112,
                                          left: 0,
                                          child: _LocationButton(
                                            onPressed: _chooseLocation,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _TermsRow(
                                    value: _acceptedTerms,
                                    onChanged: (value) =>
                                        setState(() => _acceptedTerms = value),
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    height: 54,
                                    child: ElevatedButton(
                                      key: const ValueKey(
                                        'profile-submit-button',
                                      ),
                                      onPressed: _submitting ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        elevation: 0,
                                        backgroundColor: AppColors.primary,
                                        disabledBackgroundColor: AppColors
                                            .primary
                                            .withValues(alpha: 0.65),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: _submitting
                                          ? const SizedBox.square(
                                              dimension: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Daftar Sekarang',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 42),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 20 / 12,
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.validator,
    this.maxLines = 1,
    this.maxLength = 120,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
          textInputAction: maxLines == 1
              ? TextInputAction.next
              : TextInputAction.newline,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: maxLines == 1 ? 14 : 12,
            ),
            constraints: BoxConstraints(minHeight: maxLines == 1 ? 48 : 96),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

class _CommodityChip extends StatelessWidget {
  const _CommodityChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  double get _designWidth => switch (label) {
    'Cabai Merah' => 94,
    'Tomat' => 61,
    'Kentang' => 77,
    'Bawang Merah' => 104,
    'Kacang Panjang' => 112,
    _ => 72,
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.primary : const Color(0xFFF3F4F6),
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: SizedBox(
          width: _designWidth,
          height: 30,
          child: InkWell(
            onTap: onPressed,
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationButton extends StatelessWidget {
  const _LocationButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 116,
        height: 44,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: const ValueKey('choose-location-button'),
            onTap: onPressed,
            borderRadius: BorderRadius.circular(10),
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const SizedBox(
                  width: 116,
                  height: 30,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_outlined, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      SizedBox(
                        width: 78,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Pilih di Maps',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      label: 'Saya Menyetujui Syarat & Ketentuan',
      child: InkWell(
        key: const ValueKey('terms-row'),
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 44,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  color: value ? AppColors.primary : Colors.white,
                  border: Border.all(color: Colors.black, width: 0.7),
                  borderRadius: BorderRadius.circular(4.8),
                ),
                child: value
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 3.5),
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Saya Menyetujui Syarat & Ketentuan',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10.916,
                        height: 13.645 / 10.916,
                      ),
                    ),
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

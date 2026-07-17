import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panenin/app/theme/app_colors.dart';
import 'package:panenin/features/stock/domain/stock_item.dart';

class StockFormScreen extends StatefulWidget {
  const StockFormScreen({this.item, this.capturedPhotoPath, super.key});

  final StockItem? item;
  final String? capturedPhotoPath;

  @override
  State<StockFormScreen> createState() => _StockFormScreenState();
}

class _StockFormScreenState extends State<StockFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.item?.name);
  late final _priceController = TextEditingController(
    text: widget.item?.price.toString(),
  );
  late int _quantity = widget.item?.quantity ?? 0;
  late String _unit = widget.item?.unit ?? 'Kg';
  late DateTime _harvestedAt = widget.item?.harvestedAt ?? DateTime.now();
  late final String? _photoStoragePath =
      widget.capturedPhotoPath ?? widget.item?.photoStoragePath;

  bool get _isEditing => widget.item != null;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final existing = widget.item;
    final item = StockItem(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      quantity: _quantity,
      unit: _unit,
      price: int.parse(_priceController.text),
      harvestedAt: _harvestedAt,
      shelfLifeDays: existing?.shelfLifeDays,
      reservations: existing?.reservations ?? const [],
      imagePath: existing?.imagePath,
      photoStoragePath: _photoStoragePath,
    );
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        body: Column(
          children: [
            const _FormHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  40,
                  30,
                  40,
                  28 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_photoStoragePath != null) ...[
                        _FieldLabel(text: 'Foto Produk'),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_photoStoragePath),
                            key: const ValueKey('captured-stock-photo'),
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              height: 180,
                              color: AppColors.surfaceSubtle,
                              alignment: Alignment.center,
                              child: const Text('Foto tidak dapat ditampilkan'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                      ],
                      _FieldLabel(text: 'Nama Produk'),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const ValueKey('stock-name-field'),
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration('Contoh: Cabai Merah'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Nama produk wajib diisi.'
                            : null,
                      ),
                      const SizedBox(height: 26),
                      _FieldLabel(text: 'Tanggal Panen'),
                      const SizedBox(height: 8),
                      InkWell(
                        key: const ValueKey('stock-harvest-date-field'),
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: _harvestedAt,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (selected != null) {
                            setState(() => _harvestedAt = selected);
                          }
                        },
                        borderRadius: BorderRadius.circular(9),
                        child: InputDecorator(
                          decoration: _inputDecoration('Pilih tanggal panen'),
                          child: Text(_formatDate(_harvestedAt)),
                        ),
                      ),
                      const SizedBox(height: 26),
                      _FieldLabel(text: 'Jumlah Stok'),
                      const SizedBox(height: 8),
                      _QuantityStepper(
                        quantity: _quantity,
                        onDecrease: _quantity == 0
                            ? null
                            : () => setState(() => _quantity--),
                        onIncrease: () => setState(() => _quantity++),
                      ),
                      const SizedBox(height: 26),
                      _FieldLabel(text: 'Satuan'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final unit in const [
                            'Kg',
                            'Ikat',
                            'Karung',
                          ]) ...[
                            Expanded(
                              child: _UnitButton(
                                label: unit,
                                selected: _unit == unit,
                                onTap: () => setState(() => _unit = unit),
                              ),
                            ),
                            if (unit != 'Karung') const SizedBox(width: 11),
                          ],
                        ],
                      ),
                      const SizedBox(height: 26),
                      _FieldLabel(
                        text: 'Harga Jual Per ${_unit.toLowerCase()}',
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const ValueKey('stock-price-field'),
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _inputDecoration(
                          '49.500',
                        ).copyWith(prefixText: 'Rp '),
                        validator: (value) {
                          final price = int.tryParse(value ?? '');
                          return price == null || price <= 0
                              ? 'Harga jual wajib diisi.'
                              : null;
                        },
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          key: const ValueKey('save-stock'),
                          onPressed: _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: Text(
                            _isEditing ? 'Simpan Perubahan' : 'Tambah Produk',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 165,
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
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Center(
              child: Text(
                'Isi dan Jumlah Harga',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  height: 32 / 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                key: const ValueKey('stock-form-back'),
                onPressed: () => Navigator.of(context).maybePop(),
                color: Colors.white,
                tooltip: 'Kembali ke stok saya',
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.textSecondary, width: 0.5),
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _RoundAction(
            key: const ValueKey('decrease-stock'),
            icon: Icons.remove,
            onTap: onDecrease,
          ),
          Text(
            '$quantity',
            key: const ValueKey('stock-quantity'),
            style: const TextStyle(fontSize: 32, height: 40 / 32),
          ),
          _RoundAction(
            key: const ValueKey('increase-stock'),
            icon: Icons.add,
            onTap: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap, super.key});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.textMuted,
        foregroundColor: Colors.white,
        minimumSize: const Size(44, 44),
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

class _UnitButton extends StatelessWidget {
  const _UnitButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.white,
          foregroundColor: selected ? AppColors.primary : Colors.black,
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        child: Text(label),
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: const BorderSide(color: AppColors.textSecondary, width: 0.5),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
  ),
);

String _formatDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}

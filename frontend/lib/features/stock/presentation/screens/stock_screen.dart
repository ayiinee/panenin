import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panenin/app/shell/panenin_bottom_navigation.dart';
import 'package:panenin/app/theme/app_colors.dart';
import 'package:panenin/features/stock/domain/stock_item.dart';
import 'package:panenin/features/stock/presentation/screens/stock_form_screen.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({this.initialItem, super.key});

  final StockItem? initialItem;

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  late final _items = List<StockItem>.of(demoStockItems);

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    if (item != null) _items.add(item);
  }

  int get _totalStock => _items.fold(
    0,
    (total, item) =>
        total + (item.status == StockStatus.expired ? 0 : item.quantity),
  );

  Future<void> _openForm([StockItem? current]) async {
    final result = await Navigator.of(context).push<StockItem>(
      MaterialPageRoute(builder: (_) => StockFormScreen(item: current)),
    );
    if (result == null || !mounted) return;

    setState(() {
      final index = _items.indexWhere((item) => item.id == result.id);
      if (index == -1) {
        _items.add(result);
      } else {
        _items[index] = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        extendBody: true,
        bottomNavigationBar: PaneninBottomNavigation(
          selectedIndex: 1,
          onDestinationSelected: (index) {
            if (index == 0) Navigator.of(context).maybePop();
          },
        ),
        body: Column(
          children: [
            _StockHeader(
              productCount: _items.length,
              totalStock: _totalStock,
              onAdd: _openForm,
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  92 + MediaQuery.paddingOf(context).bottom,
                ),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _StockCard(
                    key: ValueKey('stock-item-${item.id}'),
                    item: item,
                    onEdit: () => _openForm(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockHeader extends StatelessWidget {
  const _StockHeader({
    required this.productCount,
    required this.totalStock,
    required this.onAdd,
  });

  final int productCount;
  final int totalStock;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 155,
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
            child: const SafeArea(
              bottom: false,
              child: Center(
                child: Text(
                  'Stok Saya',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    height: 32 / 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 116,
            left: 16,
            right: 113,
            child: Container(
              height: 66,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 4,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ringkasan Stok',
                          style: TextStyle(
                            fontSize: 16,
                            height: 20 / 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '$productCount Produk  •  $totalStock Kg tersedia',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, height: 18 / 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 114,
            right: 19,
            child: SizedBox(
              width: 69,
              height: 69,
              child: FilledButton(
                key: const ValueKey('add-stock'),
                onPressed: onAdd,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Icon(Icons.add_rounded, size: 42),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  const _StockCard({required this.item, required this.onEdit, super.key});

  final StockItem item;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final status = item.status;
    final isExpired = status == StockStatus.expired;
    final reservedQuantity = item.reservedQuantityAt(DateTime.now());

    return Container(
      key: ValueKey('stock-card-surface-${item.id}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isExpired
            ? AppColors.danger.withValues(alpha: 0.08)
            : Colors.white,
        border: Border.all(
          color: isExpired ? AppColors.danger : const Color(0x55000000),
          width: isExpired ? 1.5 : 0.5,
        ),
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductImage(
                assetPath: item.imagePath,
                filePath: item.photoStoragePath,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 24 / 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          key: ValueKey('edit-stock-${item.id}'),
                          onPressed: onEdit,
                          tooltip: 'Edit ${item.name}',
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            foregroundColor: AppColors.primary,
                            minimumSize: const Size(40, 40),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _StockMetric(
                            label: 'Sisa Stok',
                            value: '${item.quantity}${item.unit}',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StockMetric(
                            label: 'Harga',
                            value:
                                'Rp${_formatNumber(item.price)}/${item.unit}',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StockMetric(
                            label: 'Status',
                            value: _statusLabel(status),
                            color: _statusColor(status),
                            backgroundColor: _statusBackground(status),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isExpired) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Melewati umur simpan ${item.shelfLifeDays} hari. '
                      'Tinjau stok sebelum ditawarkan.${reservedQuantity > 0 ? ' $reservedQuantity${item.unit} masih direservasi.' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.assetPath, required this.filePath});

  final String? assetPath;
  final String? filePath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: filePath != null
          ? Image.file(
              File(filePath!),
              key: const ValueKey('stock-file-photo'),
              width: 68,
              height: 68,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholder(),
            )
          : assetPath != null
          ? Image.asset(assetPath!, width: 68, height: 68, fit: BoxFit.cover)
          : _placeholder(),
    );
  }

  Widget _placeholder() => Container(
    width: 68,
    height: 68,
    color: AppColors.surfaceSubtle,
    child: const Icon(Icons.eco_outlined, color: AppColors.primary, size: 32),
  );
}

class _StockMetric extends StatelessWidget {
  const _StockMetric({
    required this.label,
    required this.value,
    this.color = Colors.black,
    this.backgroundColor = const Color(0xFFE5E5E5),
  });

  final String label;
  final String value;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          style: const TextStyle(fontSize: 11, height: 16 / 11),
        ),
        const SizedBox(height: 3),
        Container(
          height: 25,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(5),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _formatNumber(int value) {
  final digits = value.toString();
  return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
}

String _statusLabel(StockStatus status) => switch (status) {
  StockStatus.available => 'Tersedia',
  StockStatus.low => 'Hampir Habis',
  StockStatus.empty => 'Habis',
  StockStatus.expired => 'Perlu Ditinjau',
};

Color _statusColor(StockStatus status) => switch (status) {
  StockStatus.available => AppColors.primary,
  StockStatus.low => AppColors.accent,
  StockStatus.empty => AppColors.danger,
  StockStatus.expired => AppColors.danger,
};

Color _statusBackground(StockStatus status) =>
    _statusColor(status).withValues(alpha: 0.1);

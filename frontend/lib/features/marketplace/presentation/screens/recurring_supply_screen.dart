import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panenin/core/constants/app_assets.dart';
import 'package:panenin/core/constants/app_colors.dart';
import 'package:panenin/features/marketplace/data/product_detail_fixture.dart';
import 'package:panenin/features/marketplace/data/recurring_supply_fixture.dart';

enum RecurringSupplyViewState { loading, empty, error, success }

class RecurringSupplyScreen extends StatefulWidget {
  const RecurringSupplyScreen({
    this.state = RecurringSupplyViewState.success,
    this.data = RecurringSupplyFixture.demo,
    this.onRetry,
    super.key,
  });

  final RecurringSupplyViewState state;
  final RecurringSupplyData data;
  final VoidCallback? onRetry;

  static Widget fromRoute(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    return RecurringSupplyScreen(
      data: switch (arguments) {
        RecurringSupplyData data => data,
        ProductDetailData product => RecurringSupplyFixture.fromProductDetail(
          product,
        ),
        _ => RecurringSupplyFixture.demo,
      },
    );
  }

  @override
  State<RecurringSupplyScreen> createState() => _RecurringSupplyScreenState();
}

class _RecurringSupplyScreenState extends State<RecurringSupplyScreen> {
  static const _designWidth = 428.0;
  static const _dayLabels = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
  static const _dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  static const _maxQuantityDigits = 6;

  late final TextEditingController _quantityController;
  DeliveryUnit _unit = DeliveryUnit.kilogram;
  DeliveryFrequency _frequency = DeliveryFrequency.daily;
  late String _quality;
  final Set<int> _selectedDays = {0, 1, 2, 3, 4, 5, 6};

  int get _quantity => int.tryParse(_quantityController.text) ?? 0;
  int get _quantityInKilograms => _quantity * _unit.kilogramMultiplier;
  int get _estimate => _quantityInKilograms * widget.data.unitPrice;
  bool get _hasValidSchedule => switch (_frequency) {
    DeliveryFrequency.daily => _selectedDays.length == _dayLabels.length,
    DeliveryFrequency.twiceWeekly => _selectedDays.length == 2,
    DeliveryFrequency.weekly => _selectedDays.length == 1,
  };
  bool get _isValid => _quantity > 0 && _hasValidSchedule;

  String get _scheduleSummary => switch (_frequency) {
    DeliveryFrequency.daily => 'Setiap hari',
    DeliveryFrequency.twiceWeekly => '2 hari per minggu',
    DeliveryFrequency.weekly => '1 hari per minggu',
  };

  String get _scheduleHint => switch (_frequency) {
    DeliveryFrequency.daily => 'Pengiriman dilakukan setiap hari',
    DeliveryFrequency.twiceWeekly => 'Pilih tepat 2 hari pengiriman',
    DeliveryFrequency.weekly => 'Pilih tepat 1 hari pengiriman',
  };

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '10');
    _quality = widget.data.initialQuality;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  String _rupiah(int value) {
    final digits = value.toString();
    final formatted = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'Rp $formatted';
  }

  Future<void> _confirmPurchase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pasokan Rutin'),
        content: Text(
          '${widget.data.commodityName}, $_quantity ${_unit.label}\n'
          '$_scheduleSummary\n'
          '$_quality\n\n'
          'Estimasi per kirim: ${_rupiah(_estimate)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Pasokan rutin berhasil dikonfirmasi.')),
      );
  }

  void _showRetryFeedback() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Mencoba memuat ulang pasokan...')),
      );
  }

  void _setFrequency(DeliveryFrequency frequency) {
    setState(() {
      _frequency = frequency;
      final days = _selectedDays.toList()..sort();
      _selectedDays
        ..clear()
        ..addAll(switch (frequency) {
          DeliveryFrequency.daily => List<int>.generate(
            _dayLabels.length,
            (index) => index,
          ),
          DeliveryFrequency.twiceWeekly => [
            ...days.take(2),
            if (days.length < 2) ...[0, 1].where((day) => !days.contains(day)),
          ].take(2),
          DeliveryFrequency.weekly => [days.firstOrNull ?? 0],
        });
    });
  }

  void _toggleDay(int index) {
    if (_frequency == DeliveryFrequency.daily) {
      _showMessage('Pengiriman harian berlaku untuk semua hari.');
      return;
    }
    setState(() {
      if (_frequency == DeliveryFrequency.weekly) {
        _selectedDays
          ..clear()
          ..add(index);
        return;
      }
      if (_selectedDays.contains(index)) {
        _selectedDays.remove(index);
      } else if (_selectedDays.length < 2) {
        _selectedDays.add(index);
      }
    });
    if (_frequency == DeliveryFrequency.twiceWeekly &&
        _selectedDays.length == 2 &&
        !_selectedDays.contains(index)) {
      _showMessage('Pilih maksimal 2 hari untuk frekuensi ini.');
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
                color: const Color(0xFFF7F7F7),
                child: Center(
                  child: SizedBox(
                    width: width,
                    height: constraints.maxHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(onBack: () => Navigator.maybePop(context)),
                        Expanded(child: _buildBody()),
                        if (widget.state == RecurringSupplyViewState.success)
                          _BottomAction(
                            estimate: _rupiah(_estimate),
                            enabled: _isValid,
                            onPressed: _confirmPurchase,
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

  Widget _buildBody() {
    return switch (widget.state) {
      RecurringSupplyViewState.loading => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      RecurringSupplyViewState.empty => _StateView(
        icon: Icons.inventory_2_outlined,
        title: 'Pasokan belum tersedia',
        message: 'Produk ini belum dapat dijadwalkan sebagai pasokan rutin.',
        action: 'Kembali',
        onPressed: () => Navigator.maybePop(context),
      ),
      RecurringSupplyViewState.error => _StateView(
        icon: Icons.wifi_off_rounded,
        title: 'Gagal memuat pasokan',
        message: 'Periksa koneksi internet Anda, lalu coba lagi.',
        action: 'Coba Lagi',
        onPressed: widget.onRetry ?? _showRetryFeedback,
      ),
      RecurringSupplyViewState.success => ListView(
        key: const ValueKey('recurring-supply-scroll'),
        padding: const EdgeInsets.only(top: 18),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SupplierCard(data: widget.data),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 17, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _FieldLabel('Jumlah Per Pengiriman'),
                const SizedBox(height: 8),
                _QuantityAndUnit(
                  controller: _quantityController,
                  selectedUnit: _unit,
                  onQuantityChanged: (_) => setState(() {}),
                  onUnitChanged: (unit) => setState(() => _unit = unit),
                ),
                const SizedBox(height: 17),
                const _FieldLabel('Frekuensi Kirim'),
                const SizedBox(height: 7),
                _FrequencySelector(
                  selected: _frequency,
                  onChanged: _setFrequency,
                ),
                const SizedBox(height: 16),
                const _FieldLabel('Jadwal Kirim'),
                const SizedBox(height: 12),
                _DaySelector(
                  labels: _dayLabels,
                  names: _dayNames,
                  selectedDays: _selectedDays,
                  onToggle: _toggleDay,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Text(
                    _scheduleHint,
                    style: TextStyle(
                      color: Color(0xFF40493D),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      height: 16 / 12,
                    ),
                  ),
                ),
                const SizedBox(height: 17),
                const _FieldLabel('Kualitas'),
                const SizedBox(height: 8),
                Semantics(
                  container: true,
                  label: 'Kualitas produk',
                  child: DropdownButtonFormField<String>(
                    key: const ValueKey('quality-dropdown'),
                    isExpanded: true,
                    initialValue: _quality,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFFBF9F8),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 17,
                        vertical: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFBFCABA)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFBFCABA)),
                      ),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: widget.data.qualityOptions
                        .map(
                          (quality) => DropdownMenuItem(
                            value: quality,
                            child: Text(quality),
                          ),
                        )
                        .toList(),
                    onChanged: (quality) {
                      if (quality != null) setState(() => _quality = quality);
                    },
                  ),
                ),
              ],
            ),
          ),
          _PriceDetails(
            commodity: widget.data.commodityName,
            unitPrice: _rupiah(widget.data.unitPrice),
            quantity: '$_quantityInKilograms kg',
            estimate: _rupiah(_estimate),
          ),
        ],
      ),
    };
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'Atur Pasokan Rutin',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 24 / 16,
            ),
          ),
          Positioned(
            left: 4,
            child: SizedBox.square(
              dimension: 48,
              child: IconButton(
                key: const ValueKey('recurring-supply-back'),
                tooltip: 'Kembali',
                onPressed: onBack,
                color: Colors.white,
                icon: const Icon(Icons.arrow_back),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({required this.data});

  final RecurringSupplyData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 98,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              data.supplierImage,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PEMASOK',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    height: 16 / 12,
                  ),
                ),
                Text(
                  data.supplierName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 24 / 18,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      size: 13,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        data.itemDescription,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 16 / 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: Colors.black,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _QuantityAndUnit extends StatelessWidget {
  const _QuantityAndUnit({
    required this.controller,
    required this.selectedUnit,
    required this.onQuantityChanged,
    required this.onUnitChanged,
  });

  final TextEditingController controller;
  final DeliveryUnit selectedUnit;
  final ValueChanged<String> onQuantityChanged;
  final ValueChanged<DeliveryUnit> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final row = SizedBox(
          height: 44,
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.shopping_bag_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      Expanded(
                        child: Semantics(
                          container: true,
                          label: 'Jumlah per pengiriman',
                          textField: true,
                          child: TextField(
                            key: const ValueKey('recurring-quantity-field'),
                            controller: controller,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(
                                _RecurringSupplyScreenState._maxQuantityDigits,
                              ),
                            ],
                            onChanged: onQuantityChanged,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              for (final unit in DeliveryUnit.values)
                Expanded(
                  flex: unit == DeliveryUnit.quintal ? 3 : 2,
                  child: Semantics(
                    container: true,
                    button: true,
                    selected: selectedUnit == unit,
                    label: 'Satuan ${unit.label}',
                    child: InkWell(
                      key: ValueKey('delivery-unit-${unit.name}'),
                      onTap: () => onUnitChanged(unit),
                      borderRadius: BorderRadius.circular(8),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            unit.label,
                            maxLines: 1,
                            style: TextStyle(
                              color: selectedUnit == unit
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: selectedUnit == unit
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
        if (constraints.maxWidth >= 358) return row;
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: SizedBox(width: 358, child: row),
        );
      },
    );
  }
}

class _FrequencySelector extends StatelessWidget {
  const _FrequencySelector({required this.selected, required this.onChanged});

  final DeliveryFrequency selected;
  final ValueChanged<DeliveryFrequency> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF0F766E)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: DeliveryFrequency.values
            .map(
              (frequency) => Expanded(
                child: Semantics(
                  container: true,
                  button: true,
                  selected: selected == frequency,
                  label: frequency.label,
                  child: InkWell(
                    key: ValueKey('delivery-frequency-${frequency.name}'),
                    onTap: () => onChanged(frequency),
                    borderRadius: BorderRadius.circular(8),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: selected == frequency
                            ? AppColors.accent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            frequency.label,
                            style: TextStyle(
                              color: selected == frequency
                                  ? Colors.black
                                  : AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: selected == frequency
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.labels,
    required this.names,
    required this.selectedDays,
    required this.onToggle,
  });

  final List<String> labels;
  final List<String> names;
  final Set<int> selectedDays;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final chips = List.generate(
      labels.length,
      (index) => Semantics(
        container: true,
        button: true,
        selected: selectedDays.contains(index),
        label: names[index],
        child: InkWell(
          key: ValueKey('delivery-day-$index'),
          onTap: () => onToggle(index),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selectedDays.contains(index)
                  ? AppColors.accent
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBFCABA)),
            ),
            child: Center(
              child: Text(
                labels[index],
                style: TextStyle(
                  color: selectedDays.contains(index)
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: selectedDays.contains(index)
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 358) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: chips,
            ),
          );
        }
        return SingleChildScrollView(
          key: const ValueKey('delivery-day-scroll'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < chips.length; index++) ...[
                chips[index],
                if (index != chips.length - 1) const SizedBox(width: 11),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PriceDetails extends StatelessWidget {
  const _PriceDetails({
    required this.commodity,
    required this.unitPrice,
    required this.quantity,
    required this.estimate,
  });

  final String commodity;
  final String unitPrice;
  final String quantity;
  final String estimate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 23, 20, 0),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.recurringSupplyPriceBackground),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, -4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Rincian Harga',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 17),
          Container(
            padding: const EdgeInsets.fromLTRB(17, 15, 15, 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _PriceRow(
                  label: 'Harga $commodity',
                  value: '$unitPrice / kg',
                  boldValue: true,
                ),
                const SizedBox(height: 10),
                _PriceRow(label: 'Jumlah per pengiriman', value: quantity),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE6DDD8)),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimasi per kirim',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 7),
                          Text(
                            'Harga mengikuti listing pemasok saat ini',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      estimate,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 28 / 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.boldValue = false,
  });

  final String label;
  final String value;
  final bool boldValue;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 12,
          fontWeight: boldValue ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    ],
  );
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.estimate,
    required this.enabled,
    required this.onPressed,
  });

  final String estimate;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFBFCABA))),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            offset: Offset(0, -3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estimasi per Kirim',
                      style: TextStyle(
                        color: Color(0xFF40493D),
                        fontSize: 12,
                        height: 18 / 12,
                      ),
                    ),
                    Text(
                      estimate,
                      key: const ValueKey('recurring-supply-estimate'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        height: 32 / 24,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gpp_good_rounded, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Dana Aman',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              key: const ValueKey('recurring-supply-submit'),
              onPressed: enabled ? onPressed : null,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Beli Sekarang',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
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
            SizedBox(
              height: 48,
              child: ElevatedButton(onPressed: onPressed, child: Text(action)),
            ),
          ],
        ),
      ),
    );
  }
}

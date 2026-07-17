import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/core/constants/app_colors.dart';
import 'package:panenin/core/validation/input_validators.dart';
import 'package:panenin/features/marketplace/data/product_detail_fixture.dart';
import 'package:panenin/features/marketplace/data/recurring_supply_fixture.dart';

enum NegotiationChatViewState { loading, empty, error, success }

enum NegotiationIntent { price, supplyContract }

class NegotiationChatRouteArguments {
  const NegotiationChatRouteArguments({
    required this.product,
    required this.intent,
  });

  final ProductDetailData product;
  final NegotiationIntent intent;
}

class NegotiationChatScreen extends StatefulWidget {
  const NegotiationChatScreen({
    this.state = NegotiationChatViewState.success,
    this.product = ProductDetailFixture.design,
    this.intent = NegotiationIntent.supplyContract,
    super.key,
  });

  final NegotiationChatViewState state;
  final ProductDetailData product;
  final NegotiationIntent intent;

  static Widget fromRoute(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    return switch (arguments) {
      NegotiationChatRouteArguments arguments => NegotiationChatScreen(
        product: arguments.product,
        intent: arguments.intent,
      ),
      ProductDetailData product => NegotiationChatScreen(product: product),
      _ => const NegotiationChatScreen(),
    };
  }

  @override
  State<NegotiationChatScreen> createState() => _NegotiationChatScreenState();
}

class _NegotiationChatScreenState extends State<NegotiationChatScreen> {
  static const _buyerBubble = Color(0xFFEAF4EC);
  static const _buyerText = Color(0xFF245430);
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<String> _messages = [];
  bool _agreed = false;
  late int _buyerPrice;
  late int _sellerPrice;
  int _attemptsLeft = 2;
  String? _messageError;

  @override
  void initState() {
    super.initState();
    final listingPrice =
        int.tryParse(widget.product.price.replaceAll(RegExp(r'[^0-9]'), '')) ??
        RecurringSupplyFixture.demo.unitPrice;
    _sellerPrice = ((listingPrice * .95) / 500).round() * 500;
    if (_sellerPrice <= 0) _sellerPrice = listingPrice;
    _buyerPrice = ((listingPrice * .9) / 500).round() * 500;
    if (_buyerPrice <= 0) _buyerPrice = listingPrice;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _rupiah(int value) =>
      'Rp${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    final error = InputValidators.chatMessage(message);
    if (error != null) {
      setState(() => _messageError = error);
      return;
    }
    setState(() {
      _messages.add(message);
      _messageController.clear();
      _messageError = null;
    });
    _scrollToBottom();
  }

  Future<void> _negotiateAgain() async {
    final controller = TextEditingController(text: _buyerPrice.toString());
    String? errorText;
    final price = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ajukan harga baru'),
          content: TextField(
            key: const ValueKey('negotiation-price-field'),
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
            onChanged: (_) {
              if (errorText != null) {
                setDialogState(() => errorText = null);
              }
            },
            decoration: InputDecoration(
              labelText: 'Harga per kg',
              prefixText: 'Rp ',
              errorText: errorText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value == null || value <= 0) {
                  setDialogState(() {
                    errorText = 'Masukkan harga lebih dari Rp0.';
                  });
                  return;
                }
                if (value >= _sellerPrice) {
                  setDialogState(() {
                    errorText =
                        'Ajuan harus di bawah ${_rupiah(_sellerPrice)}/kg.';
                  });
                  return;
                }
                Navigator.pop(context, value);
              },
              child: const Text('Kirim Ajuan'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (price == null || price <= 0 || !mounted) return;
    setState(() {
      _buyerPrice = price;
      _attemptsLeft = math.max(0, _attemptsLeft - 1);
      _messages.add('Saya ajukan ${_rupiah(price)}/kg. Apakah bisa, Pak?');
    });
    _scrollToBottom();
  }

  void _agree() {
    setState(() => _agreed = true);
    _scrollToBottom();
  }

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacementNamed(
      context,
      RouteNames.productDetail,
      arguments: ProductDetailRouteArguments(
        name: widget.product.name,
        price: widget.product.price,
        image: widget.product.image,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => Center(
              child: SizedBox(
                width: math.min(428, constraints.maxWidth),
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    _ChatHeader(product: widget.product, onBack: _goBack),
                    Expanded(child: _buildState()),
                    if (widget.state == NegotiationChatViewState.success)
                      _Composer(
                        controller: _messageController,
                        onSend: _sendMessage,
                        errorText: _messageError,
                        onChanged: (value) {
                          if (_messageError == null) return;
                          setState(
                            () => _messageError = InputValidators.chatMessage(
                              value,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildState() => switch (widget.state) {
    NegotiationChatViewState.loading => const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    ),
    NegotiationChatViewState.empty => const _StateView(
      icon: Icons.forum_outlined,
      title: 'Belum ada percakapan',
      message: 'Mulai negosiasi dari detail produk pemasok.',
    ),
    NegotiationChatViewState.error => const _StateView(
      icon: Icons.wifi_off_rounded,
      title: 'Percakapan gagal dimuat',
      message: 'Periksa koneksi, lalu buka kembali halaman ini.',
    ),
    NegotiationChatViewState.success => ListView(
      key: const ValueKey('negotiation-chat-scroll'),
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: _Bubble(
            color: _buyerBubble,
            text: widget.intent == NegotiationIntent.supplyContract
                ? 'Halo Pak, saya ingin mengajukan pasokan rutin dengan detail berikut:'
                : 'Halo Pak, saya ingin menegosiasikan harga untuk pembelian berikut:',
            isBuyer: true,
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: _DetailCard(
            color: _buyerBubble,
            foreground: _buyerText,
            rows: [
              MapEntry('Komoditas', widget.product.name),
              const MapEntry('Kualitas', 'Grade B (Standard)'),
              const MapEntry('Jumlah', '10 kg / kirim'),
              if (widget.intent == NegotiationIntent.supplyContract) ...[
                const MapEntry('Frekuensi', '2x seminggu'),
                const MapEntry('Jadwal', 'Senin, Kamis'),
              ],
              MapEntry('Harga ajuan', '${_rupiah(_buyerPrice)}/kg'),
              MapEntry('Estimasi', _rupiah(_buyerPrice * 10)),
              MapEntry(
                'Catatan',
                widget.intent == NegotiationIntent.supplyContract
                    ? 'Mohon pasokan rutin untuk 2 minggu.'
                    : 'Mohon pertimbangkan harga yang saya ajukan.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CircleAvatar(
              radius: 17,
              backgroundImage: AssetImage(widget.product.supplierImage),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: _Bubble(
                color: Colors.white,
                text: 'Halo Kak, saya review dulu ya.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 42),
          child: _CounterOfferCard(
            buyerPrice: _buyerPrice,
            sellerPrice: _sellerPrice,
            attemptsLeft: _attemptsLeft,
            onAgree: _agreed ? null : _agree,
            onNegotiate: _agreed || _attemptsLeft == 0 ? null : _negotiateAgain,
          ),
        ),
        for (final message in _messages) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: _Bubble(color: _buyerBubble, text: message, isBuyer: true),
          ),
        ],
        if (_agreed) ...[
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: _DealCard(
              product: widget.product,
              sellerPrice: _sellerPrice,
              isSupplyContract:
                  widget.intent == NegotiationIntent.supplyContract,
              onContinue: () => Navigator.pushNamed(
                context,
                RouteNames.recurringSupply,
                arguments: RecurringSupplyFixture.fromProductDetail(
                  widget.product,
                  unitPrice: _sellerPrice,
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  };
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.product, required this.onBack});
  final ProductDetailData product;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Container(
    height: 68,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: const BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
    ),
    child: Row(
      children: [
        IconButton(
          key: const ValueKey('negotiation-back'),
          tooltip: 'Kembali',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        CircleAvatar(backgroundImage: AssetImage(product.supplierImage)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            product.supplierName,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.color,
    required this.text,
    this.isBuyer = false,
  });
  final Color color;
  final String text;
  final bool isBuyer;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 300),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(12),
        topRight: const Radius.circular(12),
        bottomLeft: Radius.circular(isBuyer ? 12 : 0),
        bottomRight: Radius.circular(isBuyer ? 0 : 12),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 5,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Text(
      text,
      style: TextStyle(
        color: isBuyer
            ? _NegotiationChatScreenState._buyerText
            : AppColors.textSecondary,
        fontSize: 14,
        height: 1.35,
      ),
    ),
  );
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.color,
    required this.foreground,
    required this.rows,
  });
  final Color color;
  final Color foreground;
  final List<MapEntry<String, String>> rows;

  @override
  Widget build(BuildContext context) => Container(
    width: 310,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(14),
        topRight: Radius.circular(14),
        bottomLeft: Radius.circular(14),
      ),
    ),
    child: Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: Color(0xFFB8D6BF)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    rows[i].key,
                    style: const TextStyle(
                      color: Color(0xFF4F6F57),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Text(
                    rows[i].value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 14,
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

class _CounterOfferCard extends StatelessWidget {
  const _CounterOfferCard({
    required this.buyerPrice,
    required this.sellerPrice,
    required this.attemptsLeft,
    required this.onAgree,
    required this.onNegotiate,
  });
  final int buyerPrice;
  final int sellerPrice;
  final int attemptsLeft;
  final VoidCallback? onAgree;
  final VoidCallback? onNegotiate;
  String _rupiah(int value) =>
      'Rp${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x24000000),
          blurRadius: 7,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      children: [
        const Row(
          children: [
            Icon(Icons.balance_rounded, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Balasan Nego dari Pemasok',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ],
        ),
        const Divider(height: 18),
        _OfferRow('Harga buyer', '${_rupiah(buyerPrice)}/kg', muted: true),
        _OfferRow('Harga seller', '${_rupiah(sellerPrice)}/kg', strong: true),
        _OfferRow('Estimasi baru', _rupiah(sellerPrice * 10), strong: true),
        _OfferRow(
          'Catatan',
          'Harga terbaik dari pemasok adalah ${_rupiah(sellerPrice)}/kg.',
        ),
        _OfferRow('Sisa nego', '$attemptsLeft dari 3'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                key: const ValueKey('agree-offer'),
                onPressed: onAgree,
                icon: const Icon(Icons.check_circle, size: 16),
                label: const Text('Setuju'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('negotiate-again'),
                onPressed: onNegotiate,
                icon: const Icon(Icons.forum_outlined, size: 16),
                label: const Text('Nego Lagi'),
              ),
            ),
          ],
        ),
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            '19:34',
            style: TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ),
      ],
    ),
  );
}

class _OfferRow extends StatelessWidget {
  const _OfferRow(
    this.label,
    this.value, {
    this.strong = false,
    this.muted = false,
  });
  final String label;
  final String value;
  final bool strong;
  final bool muted;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: muted
                  ? const Color(0xFF9CA3AF)
                  : strong
                  ? AppColors.primary
                  : AppColors.textSecondary,
              decoration: muted ? TextDecoration.lineThrough : null,
              fontSize: 14,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DealCard extends StatelessWidget {
  const _DealCard({
    required this.product,
    required this.sellerPrice,
    required this.isSupplyContract,
    required this.onContinue,
  });
  final ProductDetailData product;
  final int sellerPrice;
  final bool isSupplyContract;
  final VoidCallback onContinue;

  String _rupiah(int value) =>
      'Rp${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';

  @override
  Widget build(BuildContext context) => Container(
    width: 322,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF4EC),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      children: [
        const Row(
          children: [
            Icon(Icons.handshake_outlined, color: Color(0xFF245430)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Harga Disepakati',
                style: TextStyle(
                  color: Color(0xFF245430),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _DealBadge(),
          ],
        ),
        const Divider(color: Color(0xFFB8D6BF)),
        _DealRow('Komoditas', product.name),
        const _DealRow('Kualitas', 'Grade B (Standard)'),
        const _DealRow('Jumlah', '10 kg / kirim'),
        if (isSupplyContract) ...[
          const _DealRow('Jadwal', 'Senin, Kamis'),
          const _DealRow('Durasi awal', '2 minggu'),
        ],
        _DealRow('Harga final', '${_rupiah(sellerPrice)}/kg', strong: true),
        _DealRow(
          'Estimasi',
          '${_rupiah(sellerPrice * 10)} / kirim',
          strong: true,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            key: const ValueKey('continue-contract'),
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.textPrimary,
            ),
            icon: const Icon(Icons.description_outlined, size: 18),
            label: const Text(
              'Lanjut Buat Kontrak',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            '19:38',
            style: TextStyle(color: Color(0xFF4F6F57), fontSize: 10),
          ),
        ),
      ],
    ),
  );
}

class _DealBadge extends StatelessWidget {
  const _DealBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF2F6B3F),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      children: [
        Icon(Icons.check_circle, color: Colors.white, size: 11),
        SizedBox(width: 4),
        Text(
          'Deal',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _DealRow extends StatelessWidget {
  const _DealRow(this.label, this.value, {this.strong = false});
  final String label;
  final String value;
  final bool strong;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 5),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0xFFB8D6BF))),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Color(0xFF4F6F57),
              fontSize: 14,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Color(0xFF245430),
              fontSize: 14,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.errorText,
    required this.onChanged,
  });
  final TextEditingController controller;
  final VoidCallback onSend;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Material(
        color: Colors.white,
        elevation: 5,
        borderRadius: BorderRadius.circular(30),
        child: TextField(
          key: const ValueKey('chat-message-field'),
          controller: controller,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => onSend(),
          onChanged: onChanged,
          inputFormatters: [LengthLimitingTextInputFormatter(500)],
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Ketik pesanmu...',
            errorText: errorText,
            contentPadding: const EdgeInsets.only(
              left: 20,
              top: 15,
              bottom: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.all(5),
              child: IconButton(
                key: const ValueKey('send-chat-message'),
                tooltip: 'Kirim pesan',
                onPressed: onSend,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.send_rounded),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _StateView extends StatelessWidget {
  const _StateView({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 48),
          const SizedBox(height: 12),
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
        ],
      ),
    ),
  );
}

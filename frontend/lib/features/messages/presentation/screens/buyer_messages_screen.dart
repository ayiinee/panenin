import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panenin/app/router/route_names.dart';
import 'package:panenin/core/constants/app_colors.dart';
import 'package:panenin/features/marketplace/presentation/screens/negotiation_chat_screen.dart';
import 'package:panenin/features/messages/data/buyer_messages_fixture.dart';
import 'package:panenin/shared/widgets/buyer_bottom_navigation.dart';

enum BuyerMessagesViewState { loading, empty, error, success }

class BuyerMessagesScreen extends StatefulWidget {
  const BuyerMessagesScreen({
    this.state = BuyerMessagesViewState.success,
    this.conversations = BuyerMessagesFixture.conversations,
    super.key,
  });

  final BuyerMessagesViewState state;
  final List<BuyerConversation> conversations;

  @override
  State<BuyerMessagesScreen> createState() => _BuyerMessagesScreenState();
}

class _BuyerMessagesScreenState extends State<BuyerMessagesScreen> {
  static const _maxWidth = 428.0;
  final _searchController = TextEditingController();
  final _readConversations = <int>{};
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<int, BuyerConversation>> get _filteredConversations {
    final query = _query.trim().toLowerCase();
    return widget.conversations.indexed
        .where((entry) {
          if (query.isEmpty) return true;
          final conversation = entry.$2;
          return conversation.farmerName.toLowerCase().contains(query) ||
              conversation.farmName.toLowerCase().contains(query) ||
              conversation.preview.toLowerCase().contains(query) ||
              conversation.commodity.toLowerCase().contains(query);
        })
        .map((entry) => MapEntry(entry.$1, entry.$2))
        .toList();
  }

  int get _unreadTotal => widget.conversations.indexed.fold(
    0,
    (total, entry) =>
        total +
        (_readConversations.contains(entry.$1) ? 0 : entry.$2.unreadCount),
  );

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  void _openConversation(int index, BuyerConversation conversation) {
    setState(() => _readConversations.add(index));
    Navigator.pushNamed(
      context,
      RouteNames.negotiationChat,
      arguments: NegotiationChatRouteArguments(
        product: conversation.product,
        intent: NegotiationIntent.supplyContract,
      ),
    );
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
              final width = math.min(constraints.maxWidth, _maxWidth);
              return Center(
                child: SizedBox(
                  width: width,
                  height: constraints.maxHeight,
                  child: Stack(
                    children: [
                      Positioned.fill(child: _body(width < 390)),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: BuyerBottomNavigation(
                          selected: BuyerNavigationDestination.messages,
                          onHome: () => Navigator.pushReplacementNamed(
                            context,
                            RouteNames.buyerHome,
                          ),
                          onMessages: () {},
                          onTransactions: () => Navigator.pushReplacementNamed(
                            context,
                            RouteNames.buyerOrders,
                          ),
                          onProfile: () => Navigator.pushReplacementNamed(
                            context,
                            RouteNames.buyerProfile,
                          ),
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

  Widget _body(bool compact) {
    final horizontalPadding = compact ? 16.0 : 20.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MessagesHeader(unreadTotal: _unreadTotal),
        Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            8,
            horizontalPadding,
            14,
          ),
          child: TextField(
            key: const ValueKey('messages-search-field'),
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari petani atau komoditas',
              prefixIcon: const Icon(Icons.search_rounded, size: 21),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      key: const ValueKey('clear-messages-search'),
                      tooltip: 'Hapus pencarian',
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.profileBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.profileBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        Expanded(child: _content(horizontalPadding)),
      ],
    );
  }

  Widget _content(double horizontalPadding) => switch (widget.state) {
    BuyerMessagesViewState.loading => const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    ),
    BuyerMessagesViewState.empty => const _MessagesState(
      icon: Icons.forum_outlined,
      title: 'Belum ada percakapan',
      message: 'Hubungi petani dari detail produk untuk memulai percakapan.',
    ),
    BuyerMessagesViewState.error => _MessagesState(
      icon: Icons.wifi_off_rounded,
      title: 'Pesan gagal dimuat',
      message: 'Periksa koneksi internet Anda, lalu coba lagi.',
      action: 'Coba Lagi',
      onPressed: () => _showMessage('Mencoba memuat ulang pesan...'),
    ),
    BuyerMessagesViewState.success when widget.conversations.isEmpty =>
      const _MessagesState(
        icon: Icons.forum_outlined,
        title: 'Belum ada percakapan',
        message: 'Hubungi petani dari detail produk untuk memulai percakapan.',
      ),
    BuyerMessagesViewState.success when _filteredConversations.isEmpty =>
      _MessagesState(
        icon: Icons.search_off_rounded,
        title: 'Percakapan tidak ditemukan',
        message: 'Coba nama petani, kelompok tani, atau komoditas lain.',
        action: 'Hapus Pencarian',
        onPressed: _clearSearch,
      ),
    BuyerMessagesViewState.success => ListView.separated(
      key: const ValueKey('buyer-messages-list'),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        122,
      ),
      itemCount: _filteredConversations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = _filteredConversations[index];
        return _ConversationCard(
          conversation: entry.value,
          unreadCount: _readConversations.contains(entry.key)
              ? 0
              : entry.value.unreadCount,
          onTap: () => _openConversation(entry.key, entry.value),
        );
      },
    ),
  };
}

class _MessagesHeader extends StatelessWidget {
  const _MessagesHeader({required this.unreadTotal});

  final int unreadTotal;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pesan',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Jaga pasokan tetap lancar bersama petani.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
        if (unreadTotal > 0)
          Semantics(
            label: '$unreadTotal pesan belum dibaca',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$unreadTotal baru',
                style: const TextStyle(
                  color: Color(0xFF7A5200),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.conversation,
    required this.unreadCount,
    required this.onTap,
  });

  final BuyerConversation conversation;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label:
        'Percakapan dengan ${conversation.farmerName}, ${conversation.commodity}'
        '${unreadCount > 0 ? ', $unreadCount pesan belum dibaca' : ''}',
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(
              color: unreadCount > 0
                  ? AppColors.profileSubtleBorder
                  : AppColors.profileBorder,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x09000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FarmerAvatar(conversation: conversation),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.farmerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          conversation.timeLabel,
                          style: TextStyle(
                            color: unreadCount > 0
                                ? AppColors.primary
                                : AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      conversation.farmName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      conversation.preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unreadCount > 0
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: unreadCount > 0
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.profileSoftSurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              conversation.commodity,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (unreadCount > 0)
                          Container(
                            key: ValueKey('unread-${conversation.farmerName}'),
                            constraints: const BoxConstraints(
                              minWidth: 22,
                              minHeight: 22,
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
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
        ),
      ),
    ),
  );
}

class _FarmerAvatar extends StatelessWidget {
  const _FarmerAvatar({required this.conversation});

  final BuyerConversation conversation;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.profileSoftSurface,
          shape: BoxShape.circle,
        ),
        child: conversation.avatar == null
            ? Text(
                conversation.initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              )
            : ClipOval(
                child: Image.asset(
                  conversation.avatar!,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  semanticLabel: 'Foto ${conversation.farmerName}',
                  errorBuilder: (_, _, _) => Center(
                    child: Text(
                      conversation.initials,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
      ),
      if (conversation.isOnline)
        Positioned(
          right: 0,
          bottom: 1,
          child: Semantics(
            label: 'Sedang aktif',
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ),
    ],
  );
}

class _MessagesState extends StatelessWidget {
  const _MessagesState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 120),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.profileSoftSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 18),
            FilledButton(onPressed: onPressed, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}

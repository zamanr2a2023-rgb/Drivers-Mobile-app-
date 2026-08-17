import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/constants/app_colors.dart';
import 'package:yjeek_driver/core/constants/app_sizes.dart';
import 'package:yjeek_driver/core/utils/app_helpers.dart';
import 'package:yjeek_driver/core/utils/date_formatter.dart';
import 'package:yjeek_driver/core/widgets/app_loader.dart';
import 'package:yjeek_driver/core/widgets/custom_app_bar.dart';
import 'package:yjeek_driver/features/chat/model/chat_conversation_model.dart';
import 'package:yjeek_driver/features/chat/model/quick_reply_model.dart';
import 'package:yjeek_driver/features/chat/provider/chat_provider.dart';

class DispatchChatScreen extends StatefulWidget {
  const DispatchChatScreen({super.key});

  @override
  State<DispatchChatScreen> createState() => _DispatchChatScreenState();
}

class _DispatchChatScreenState extends State<DispatchChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadChats();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openChat(ChatConversationModel chat) async {
    await context.read<ChatProvider>().openChat(chat);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final provider = context.read<ChatProvider>();
    final sent = await provider.sendMessage(text);
    if (!mounted) return;

    if (sent) {
      _messageController.clear();
      _scrollToBottom();
      return;
    }

    AppHelpers.showSnackBar(
      context,
      provider.sendMessageError ?? 'Failed to send message',
      isError: true,
    );
  }

  Future<void> _sendQuickReply(QuickReplyModel reply) async {
    final provider = context.read<ChatProvider>();
    final sent = await provider.sendQuickReply(reply);
    if (!mounted) return;

    if (sent) {
      _scrollToBottom();
      return;
    }

    AppHelpers.showSnackBar(
      context,
      provider.sendMessageError ?? 'Failed to send message',
      isError: true,
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final selected = provider.selectedChat;

    return PopScope(
      canPop: selected == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.read<ChatProvider>().closeChat();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: selected?.title ?? 'Dispatch Chat',
        ),
        body: selected == null
            ? _ChatListBody(
                isLoading: provider.isLoading,
                chats: provider.chats,
                error: provider.chatsError,
                onRetry: () => context.read<ChatProvider>().loadChats(),
                onOpen: _openChat,
              )
            : _ChatThreadBody(
                provider: provider,
                scrollController: _scrollController,
                messageController: _messageController,
                onSend: _sendMessage,
                onQuickReply: _sendQuickReply,
                onRetry: () => context.read<ChatProvider>().openChat(selected),
              ),
      ),
    );
  }
}

class _ChatListBody extends StatelessWidget {
  const _ChatListBody({
    required this.isLoading,
    required this.chats,
    required this.error,
    required this.onRetry,
    required this.onOpen,
  });

  final bool isLoading;
  final List<ChatConversationModel> chats;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<ChatConversationModel> onOpen;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const AppLoader();

    if (error != null && chats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textLight),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (chats.isEmpty) {
      return const Center(
        child: Text(
          'No chats yet',
          style: TextStyle(color: AppColors.textLight),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRetry(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        itemCount: chats.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppSizes.paddingSm),
        itemBuilder: (context, index) {
          final chat = chats[index];
          final at = chat.displayAt;
          return Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => onOpen(chat),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.12),
                      child: Icon(
                        chat.isDispatch
                            ? Icons.support_agent_rounded
                            : Icons.person_outline_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chat.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (chat.orderNumber.trim().isNotEmpty)
                            Text(
                              chat.orderNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            chat.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (at != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        DateFormatter.formatRelative(at.toLocal()),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChatThreadBody extends StatelessWidget {
  const _ChatThreadBody({
    required this.provider,
    required this.scrollController,
    required this.messageController,
    required this.onSend,
    required this.onQuickReply,
    this.onRetry,
  });

  final ChatProvider provider;
  final ScrollController scrollController;
  final TextEditingController messageController;
  final VoidCallback onSend;
  final ValueChanged<QuickReplyModel> onQuickReply;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final error = provider.conversationError;

    Widget messagesArea;
    if (provider.isLoadingConversation) {
      messagesArea = const AppLoader();
    } else if (error != null && provider.messages.isEmpty) {
      messagesArea = Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textLight),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ],
          ),
        ),
      );
    } else {
      messagesArea = RefreshIndicator(
        onRefresh: () async {
          await onRetry?.call();
        },
        child: ListView.builder(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          itemCount: provider.messages.length,
          itemBuilder: (context, index) {
            final msg = provider.messages[index];
            return Align(
              alignment:
                  msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSizes.paddingSm),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: msg.isMe ? AppColors.primary : AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: msg.isMe
                      ? null
                      : Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!msg.isMe)
                      Text(
                        msg.sender,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    Text(
                      msg.message,
                      style: TextStyle(
                        color:
                            msg.isMe ? AppColors.white : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormatter.formatTime(msg.createdAt.toLocal()),
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            msg.isMe ? AppColors.white70 : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return Column(
      children: [
        Expanded(child: messagesArea),
        if (provider.isLoadingQuickReplies)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (provider.quickReplies.isNotEmpty)
          _QuickRepliesBar(
            replies: provider.quickReplies,
            onTap: provider.isSendingMessage ? null : onQuickReply,
          ),
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingSm),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(top: BorderSide(color: AppColors.cardBorder)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    enabled: !provider.isSendingMessage,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: provider.isSendingMessage ? null : (_) => onSend(),
                  ),
                ),
                const SizedBox(width: AppSizes.paddingSm),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: provider.isSendingMessage
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: AppColors.white,
                            size: 20,
                          ),
                    onPressed:
                        provider.isSendingMessage ? null : onSend,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickRepliesBar extends StatelessWidget {
  const _QuickRepliesBar({
    required this.replies,
    this.onTap,
  });

  final List<QuickReplyModel> replies;
  final ValueChanged<QuickReplyModel>? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final reply in replies) ...[
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(reply.label),
                  backgroundColor: AppColors.white,
                  side: const BorderSide(color: AppColors.cardBorder),
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  onPressed:
                      onTap == null ? null : () => onTap!(reply),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

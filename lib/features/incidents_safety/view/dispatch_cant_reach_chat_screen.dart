import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/utils/app_helpers.dart';
import 'package:yjeek_driver/core/widgets/app_loader.dart';
import 'package:yjeek_driver/features/chat/model/chat_conversation_model.dart';
import 'package:yjeek_driver/features/chat/model/chat_message_model.dart';
import 'package:yjeek_driver/features/chat/model/quick_reply_model.dart';
import 'package:yjeek_driver/features/chat/provider/chat_provider.dart';
import 'package:yjeek_driver/features/incidents_safety/view/incident_ui.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';

/// DR1b-Chat · Dispatch — live thread via `/drivers/chat` APIs.
class DispatchCantReachChatScreen extends StatefulWidget {
  const DispatchCantReachChatScreen({
    super.key,
    this.args = const IncidentContextArgs(),
  });

  final IncidentContextArgs args;

  @override
  State<DispatchCantReachChatScreen> createState() =>
      _DispatchCantReachChatScreenState();
}

class _DispatchCantReachChatScreenState
    extends State<DispatchCantReachChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  ChatProvider? _chat;
  int _messageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openDispatchThread());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chat = context.read<ChatProvider>();
  }

  @override
  void dispose() {
    _chat?.closeChat();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? _resolveJobId() {
    final fromArgs = widget.args.orderId.trim();
    if (fromArgs.isNotEmpty) return fromArgs;

    final orders = context.read<OrderProvider>();
    final detailId = orders.currentJobDetail?.id.trim();
    if (detailId != null && detailId.isNotEmpty) return detailId;

    if (orders.instantActiveJobs.isNotEmpty) {
      final activeId = orders.instantActiveJobs.first.id.trim();
      if (activeId.isNotEmpty) return activeId;
    }
    return null;
  }

  Future<void> _openDispatchThread() async {
    final provider = context.read<ChatProvider>();
    final jobId = _resolveJobId();

    if (jobId != null) {
      await provider.openDispatchChat(orderId: jobId);
    } else {
      await provider.loadChats();
      if (!mounted) return;
      ChatConversationModel? dispatch;
      for (final chat in provider.chats) {
        if (chat.isDispatch) {
          dispatch = chat;
          break;
        }
      }
      if (dispatch != null) {
        await provider.openChat(dispatch);
      } else if (provider.chats.isNotEmpty) {
        await provider.openChat(provider.chats.first);
      }
    }

    if (!mounted) return;
    await provider.loadQuickReplies();
    _scrollToBottom();
  }

  Future<void> _retryThread() async {
    await _openDispatchThread();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty) return;

    final provider = context.read<ChatProvider>();
    if (provider.isSendingMessage || provider.selectedChat == null) {
      if (provider.selectedChat == null && mounted) {
        AppHelpers.showSnackBar(
          context,
          provider.conversationError ?? 'Chat is not ready yet',
          isError: true,
        );
      }
      return;
    }

    final sent = await provider.sendMessage(text);
    if (!mounted) return;

    if (sent) {
      _controller.clear();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final count = provider.messages.length;
    if (count > _messageCount) {
      _messageCount = count;
      _scrollToBottom();
    } else {
      _messageCount = count;
    }

    return Scaffold(
      backgroundColor: IncidentColors.screenBg,
      body: SafeArea(
        child: Column(
          children: [
            IncidentHeader(
              title: 'Dispatch chat',
              subtitle: widget.args.dropoffSubtitle,
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: IncidentColors.white,
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: IncidentColors.headerGreen,
                    child: Icon(Icons.headset_mic, size: 14, color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dispatch · usually replies in ~30 sec',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: IncidentColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildMessagesArea(provider)),
            if (provider.quickReplies.isNotEmpty)
              _QuickRepliesBar(
                replies: provider.quickReplies,
                onTap: _send,
              ),
            _buildComposer(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesArea(ChatProvider provider) {
    if (provider.isLoadingConversation) {
      return const AppLoader();
    }

    final error = provider.conversationError;
    if (error != null && provider.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: IncidentColors.textMuted),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _retryThread, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (provider.messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet',
          style: TextStyle(color: IncidentColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: provider.messages.length,
      itemBuilder: (context, index) {
        final msg = provider.messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMessage(msg),
        );
      },
    );
  }

  Widget _buildMessage(ChatMessageModel msg) {
    final role = msg.senderRole?.toUpperCase() ?? '';
    if (role == 'SYSTEM') {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFDDE5DD),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            msg.message,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5B6B58),
            ),
          ),
        ),
      );
    }

    if (msg.isMe) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: IncidentColors.headerGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            msg.message,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 14,
          backgroundColor: IncidentColors.headerGreen,
          child: Icon(Icons.support_agent, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: IncidentColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE3E8E0)),
            ),
            child: Text(
              msg.message,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF25302B),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComposer(ChatProvider provider) {
    final disabled = provider.selectedChat == null || provider.isSendingMessage;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      color: IncidentColors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F5F1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                enabled: !disabled,
                decoration: const InputDecoration(
                  hintText: 'Message dispatch…',
                  hintStyle: TextStyle(color: Color(0xFF9AA09B), fontSize: 14),
                  border: InputBorder.none,
                ),
                onSubmitted: disabled ? null : (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: IncidentColors.headerGreen,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: disabled ? null : () => _send(),
              child: SizedBox(
                width: 42,
                height: 42,
                child: provider.isSendingMessage
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickRepliesBar extends StatelessWidget {
  const _QuickRepliesBar({
    required this.replies,
    required this.onTap,
  });

  final List<QuickReplyModel> replies;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      color: IncidentColors.white,
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: replies
            .map(
              (reply) => IncidentChip(
                label: reply.body,
                selected: false,
                onTap: () => onTap(reply.body),
              ),
            )
            .toList(),
      ),
    );
  }
}

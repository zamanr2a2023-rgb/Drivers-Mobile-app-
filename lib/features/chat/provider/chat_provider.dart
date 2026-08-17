import 'package:flutter/foundation.dart';
import 'package:yjeek_driver/features/chat/model/chat_conversation_model.dart';
import 'package:yjeek_driver/features/chat/model/chat_message_model.dart';
import 'package:yjeek_driver/features/chat/model/quick_reply_model.dart';
import 'package:yjeek_driver/features/chat/service/chat_service.dart';
import 'package:yjeek_driver/services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({ChatService? chatService})
      : _service = chatService ?? ChatService();

  final ChatService _service;

  bool _isLoading = false;
  bool _isLoadingConversation = false;
  bool _isLoadingQuickReplies = false;
  bool _isSendingMessage = false;
  List<ChatConversationModel> _chats = [];
  ChatConversationModel? _selectedChat;
  List<ChatMessageModel> _messages = [];
  List<QuickReplyModel> _quickReplies = [];
  String? _chatsError;
  String? _conversationError;
  String? _quickRepliesError;
  String? _sendMessageError;

  bool get isLoading => _isLoading;
  bool get isLoadingConversation => _isLoadingConversation;
  bool get isLoadingQuickReplies => _isLoadingQuickReplies;
  bool get isSendingMessage => _isSendingMessage;
  List<ChatConversationModel> get chats => _chats;
  ChatConversationModel? get selectedChat => _selectedChat;
  List<ChatMessageModel> get messages => _messages;
  List<QuickReplyModel> get quickReplies => _quickReplies;
  String? get chatsError => _chatsError;
  String? get conversationError => _conversationError;
  String? get quickRepliesError => _quickRepliesError;
  String? get sendMessageError => _sendMessageError;

  /// GET /drivers/chat
  Future<void> loadChats() async {
    _isLoading = true;
    _chatsError = null;
    notifyListeners();

    try {
      _chats = await _service.getChats();
    } on ApiException catch (e) {
      _chats = [];
      _chatsError = e.message;
    } catch (_) {
      _chats = [];
      _chatsError = 'Failed to load chats';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// GET /drivers/chat/orders/{orderId}?peer=dispatch
  /// GET /drivers/chat/orders/{orderId}?peer=customer
  Future<void> openChat(ChatConversationModel chat) async {
    _selectedChat = chat;
    _messages = [];
    _conversationError = null;
    _isLoadingConversation = true;
    notifyListeners();

    try {
      final orderId = chat.orderId.trim();
      final peer = chat.peer.trim().isEmpty
          ? (chat.isDispatch ? 'dispatch' : 'customer')
          : chat.peer.trim();

      if (orderId.isNotEmpty) {
        final opened = await _service.openOrderChat(
          orderId: orderId,
          peer: peer,
        );
        _selectedChat = opened.conversation;
        _messages = opened.messages;
        _markConversationRead(opened.conversation.conversationId);
      } else {
        _messages = await _service.getConversationMessages(chat);
        _markConversationRead(chat.conversationId);
      }
    } on ApiException catch (e) {
      _messages = [];
      _conversationError = e.message;
    } catch (_) {
      _messages = [];
      _conversationError = 'Failed to load conversation';
    } finally {
      _isLoadingConversation = false;
      notifyListeners();
    }

    final peer = chat.peer.trim().isEmpty ? 'dispatch' : chat.peer.trim();
    await loadQuickReplies(peers: [peer]);
  }

  /// POST /drivers/chat/{conversationId}/read
  Future<void> _markConversationRead(String conversationId) async {
    try {
      await _service.markConversationRead(conversationId);
    } catch (_) {
      // Opening the thread should not fail if mark-read fails.
    }
  }

  void closeChat() {
    _selectedChat = null;
    _messages = [];
    _quickReplies = [];
    _conversationError = null;
    _isLoadingConversation = false;
    _isSendingMessage = false;
    _sendMessageError = null;
    notifyListeners();
  }

  /// GET /drivers/chat/quick-replies?peer=dispatch
  /// GET /drivers/chat/quick-replies?peer=customer
  Future<void> loadQuickReplies({
    List<String> peers = const ['dispatch', 'customer'],
  }) async {
    _isLoadingQuickReplies = true;
    _quickRepliesError = null;
    notifyListeners();

    try {
      final results = await Future.wait(
        peers.map((peer) => _loadPeerReplies(peer)),
      );
      _quickReplies = results.expand((replies) => replies).toList();
      if (_quickReplies.isEmpty && _quickRepliesError == null) {
        _quickRepliesError = 'Failed to load quick replies';
      }
    } catch (_) {
      _quickReplies = [];
      _quickRepliesError = 'Failed to load quick replies';
    } finally {
      _isLoadingQuickReplies = false;
      notifyListeners();
    }
  }

  Future<List<QuickReplyModel>> _loadPeerReplies(String peer) async {
    try {
      return await _service.getQuickReplies(peer: peer);
    } on ApiException catch (e) {
      _quickRepliesError ??= e.message;
      return const [];
    } catch (_) {
      _quickRepliesError ??= 'Failed to load quick replies';
      return const [];
    }
  }

  /// POST /drivers/chat/orders/{orderId}/messages
  Future<bool> sendMessage(String text) async {
    final conversation = _selectedChat;
    final body = text.trim();
    if (conversation == null || body.isEmpty || _isSendingMessage) {
      return false;
    }

    _isSendingMessage = true;
    _sendMessageError = null;
    notifyListeners();

    try {
      final orderId = conversation.orderId.trim();
      final message = orderId.isNotEmpty
          ? await _service.sendOrderMessage(
              orderId: orderId,
              body: body,
              peer: conversation.isDispatch ? 'dispatch' : null,
              conversationTitle: conversation.title,
            )
          : await _service.sendMessage(
              conversationId: conversation.conversationId,
              body: body,
              conversationTitle: conversation.title,
            );
      _messages = [..._messages, message];
      return true;
    } on ApiException catch (e) {
      _sendMessageError = e.message;
      return false;
    } catch (_) {
      _sendMessageError = 'Failed to send message';
      return false;
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  /// POST /drivers/chat/{conversationId}/messages
  Future<bool> sendQuickReply(QuickReplyModel reply) async {
    final body = reply.body.trim();
    if (body.isEmpty) return false;
    return sendMessage(body);
  }
}

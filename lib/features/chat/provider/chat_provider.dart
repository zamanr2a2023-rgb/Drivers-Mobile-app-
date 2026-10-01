import 'dart:async';

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
  Timer? _messagePollTimer;
  bool _isRefreshingMessages = false;

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

  /// GET /drivers/chat?peer=dispatch&limit=50
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
  Future<void> openDispatchChat({required String orderId}) async {
    _stopMessagePolling();
    final id = orderId.trim();
    if (id.isEmpty) {
      _conversationError = 'Order id is required';
      _messages = [];
      notifyListeners();
      return;
    }

    _selectedChat = ChatConversationModel(
      id: '',
      conversationId: '',
      orderId: id,
      orderNumber: '',
      orderStatus: '',
      type: 'DISPATCH',
      peer: 'dispatch',
      customerName: '',
      createdAt: DateTime.now(),
    );
    _messages = [];
    _conversationError = null;
    _isLoadingConversation = true;
    notifyListeners();

    try {
      final opened = await _service.getOrCreateDispatchChat(id);
      _selectedChat = opened.conversation;
      _messages = opened.messages;
    } on ApiException catch (e) {
      _messages = [];
      _conversationError = e.message;
    } catch (_) {
      _messages = [];
      _conversationError = 'Failed to open chat';
    } finally {
      _isLoadingConversation = false;
      notifyListeners();
    }

    await loadQuickReplies();
    await _markConversationRead(_selectedChat?.conversationId);
    if (_conversationError == null) {
      _startMessagePolling();
    }
  }

  /// GET /drivers/chat/{conversationId}/messages
  Future<void> openChat(ChatConversationModel chat) async {
    _stopMessagePolling();
    _selectedChat = chat;
    _messages = [];
    _conversationError = null;
    _isLoadingConversation = true;
    notifyListeners();

    try {
      final conversationId = chat.conversationId.trim();
      if (conversationId.isNotEmpty) {
        _messages = await _service.getConversationMessages(chat);
      } else if (chat.orderId.trim().isNotEmpty) {
        final opened = await _service.getOrCreateDispatchChat(
          chat.orderId.trim(),
        );
        _selectedChat = opened.conversation;
        _messages = opened.messages;
      } else {
        throw ApiException('Conversation id is required');
      }
    } on ApiException catch (e) {
      _messages = [];
      _conversationError = e.message;
    } catch (_) {
      _messages = [];
      _conversationError = 'Failed to load messages';
    } finally {
      _isLoadingConversation = false;
      notifyListeners();
    }

    await loadQuickReplies();
    await _markConversationRead(_selectedChat?.conversationId);
    if (_conversationError == null) {
      _startMessagePolling();
    }
  }

  /// POST /drivers/chat/{conversationId}/read
  Future<void> _markConversationRead(String? conversationId) async {
    final id = conversationId?.trim() ?? '';
    if (id.isEmpty || _conversationError != null) return;

    try {
      final result = await _service.markConversationRead(id);
      if (!result.read) return;
      _applyRead(result.conversationId);
    } catch (_) {
      // Opening the thread should not fail if mark-read fails.
    }
  }

  void _applyRead(String conversationId) {
    _chats = [
      for (final chat in _chats)
        chat.conversationId == conversationId
            ? chat.copyWith(isRead: true)
            : chat,
    ];
    final selected = _selectedChat;
    if (selected != null && selected.conversationId == conversationId) {
      _selectedChat = selected.copyWith(isRead: true);
    }
    notifyListeners();
  }

  void closeChat() {
    _stopMessagePolling();
    _selectedChat = null;
    _messages = [];
    _quickReplies = [];
    _conversationError = null;
    _quickRepliesError = null;
    _isLoadingConversation = false;
    _isLoadingQuickReplies = false;
    _isSendingMessage = false;
    _sendMessageError = null;
    notifyListeners();
  }

  void _startMessagePolling() {
    _stopMessagePolling();
    if (_selectedChat == null || _conversationError != null) return;
    if (_selectedChat!.conversationId.trim().isEmpty) return;

    _messagePollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => refreshMessages(),
    );
  }

  void _stopMessagePolling() {
    _messagePollTimer?.cancel();
    _messagePollTimer = null;
  }

  /// GET /drivers/chat/{conversationId}/messages (silent refresh)
  Future<bool> refreshMessages() async {
    final chat = _selectedChat;
    if (chat == null ||
        _isRefreshingMessages ||
        _isSendingMessage ||
        _isLoadingConversation) {
      return false;
    }

    final conversationId = chat.conversationId.trim();
    if (conversationId.isEmpty) return false;

    _isRefreshingMessages = true;
    var hasNew = false;
    try {
      final latest = await _service.getConversationMessages(chat);
      if (_selectedChat?.conversationId != conversationId) return false;

      if (!_sameMessageIds(latest, _messages)) {
        hasNew = latest.length > _messages.length;
        _messages = latest;
        notifyListeners();
        if (hasNew) {
          _markConversationRead(conversationId);
        }
      }
    } catch (_) {
      // Keep the open thread; the next poll retries.
    } finally {
      _isRefreshingMessages = false;
    }
    return hasNew;
  }

  bool _sameMessageIds(
    List<ChatMessageModel> next,
    List<ChatMessageModel> current,
  ) {
    if (next.length != current.length) return false;
    for (var i = 0; i < next.length; i++) {
      if (next[i].id != current[i].id) return false;
    }
    return true;
  }

  /// GET /drivers/chat/quick-replies?peer=dispatch
  Future<void> loadQuickReplies() async {
    _isLoadingQuickReplies = true;
    _quickRepliesError = null;
    notifyListeners();

    try {
      _quickReplies = await _service.getQuickReplies(peer: 'dispatch');
    } on ApiException catch (e) {
      _quickReplies = [];
      _quickRepliesError = e.message;
    } catch (_) {
      _quickReplies = [];
      _quickRepliesError = 'Failed to load quick replies';
    } finally {
      _isLoadingQuickReplies = false;
      notifyListeners();
    }
  }

  /// POST /drivers/chat/{conversationId}/messages
  /// Falls back to POST /drivers/chat/orders/{orderId}/messages
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
      final message = await _sendDispatchMessage(
        conversation: conversation,
        body: body,
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

  Future<ChatMessageModel> _sendDispatchMessage({
    required ChatConversationModel conversation,
    required String body,
  }) async {
    final conversationId = conversation.conversationId.trim();
    final orderId = conversation.orderId.trim();
    final title = conversation.title;

    if (conversationId.isNotEmpty) {
      try {
        return await _service.sendMessage(
          conversationId: conversationId,
          body: body,
          conversationTitle: title,
        );
      } on ApiException catch (e) {
        if (orderId.isEmpty) rethrow;
        final message = e.message.toLowerCase();
        final retryWithOrder = e.statusCode == 404 ||
            e.code?.toUpperCase() == 'NOT_FOUND' ||
            message.contains('not found');
        if (!retryWithOrder) rethrow;
      }
    }

    if (orderId.isEmpty) {
      throw ApiException('Conversation id is required');
    }

    return _service.sendOrderMessage(
      orderId: orderId,
      body: body,
      peer: 'dispatch',
      conversationTitle: title,
    );
  }

  /// POST /drivers/chat/{conversationId}/messages
  Future<bool> sendQuickReply(QuickReplyModel reply) async {
    final body = reply.body.trim();
    if (body.isEmpty) return false;
    return sendMessage(body);
  }
}

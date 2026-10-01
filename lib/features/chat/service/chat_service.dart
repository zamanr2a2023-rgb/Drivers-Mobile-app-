import 'package:yjeek_driver/core/constants/api_endpoints.dart';
import 'package:yjeek_driver/features/chat/model/chat_conversation_model.dart';
import 'package:yjeek_driver/features/chat/model/chat_message_model.dart';
import 'package:yjeek_driver/features/chat/model/quick_reply_model.dart';
import 'package:yjeek_driver/services/api_service.dart';

class ChatService {
  ChatService({ApiService? apiService})
      : _api = apiService ?? ApiService.instance;

  final ApiService _api;

  /// GET /drivers/chat?peer=dispatch&limit=50
  Future<List<ChatConversationModel>> getChats() async {
    final response = await _api.get(ApiEndpoints.driverChatsInbox());

    if (response['success'] != true) {
      throw ApiException(_failureMessage(response, 'Failed to load chats'));
    }

    final data = response['data'];
    if (data is! Map) {
      throw ApiException('Invalid response from server');
    }

    final itemsRaw = data['items'];
    if (itemsRaw is! List) {
      return const [];
    }

    return itemsRaw
        .whereType<Map>()
        .map(
          (item) => ChatConversationModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((chat) => chat.conversationId.isNotEmpty)
        .toList();
  }

  /// GET /drivers/chat/{conversationId}/messages
  Future<List<ChatMessageModel>> getConversationMessages(
    ChatConversationModel conversation,
  ) async {
    final id = conversation.conversationId.trim();
    if (id.isEmpty) {
      throw ApiException('Conversation id is required');
    }

    final response =
        await _api.get(ApiEndpoints.chatConversationMessages(id));

    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to load messages'),
      );
    }

    final title = conversation.title;
    final data = response['data'];
    if (data == null) {
      return const [];
    }
    return _parseMessages(data, title);
  }

  /// GET /drivers/chat/orders/{orderId}?peer=dispatch
  Future<OpenedOrderChat> getOrCreateDispatchChat(String orderId) {
    return openOrderChat(orderId: orderId, peer: 'dispatch');
  }

  /// GET /drivers/chat/orders/{orderId}?peer=dispatch
  Future<OpenedOrderChat> openOrderChat({
    required String orderId,
    String peer = 'dispatch',
  }) async {
    final id = orderId.trim();
    if (id.isEmpty) {
      throw ApiException('Order id is required');
    }

    final response = await _api.get(
      ApiEndpoints.chatOrder(id, peer: peer),
    );

    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to open chat'),
      );
    }

    final data = response['data'];
    if (data is! Map) {
      throw ApiException('Invalid response from server');
    }

    final json = Map<String, dynamic>.from(data);
    final conversation = ChatConversationModel.fromJson(json);
    if (conversation.conversationId.isEmpty) {
      throw ApiException('Invalid response from server');
    }

    return OpenedOrderChat(
      conversation: conversation,
      messages: _parseMessages(json, conversation.title),
    );
  }

  List<ChatMessageModel> _parseMessages(dynamic data, String title) {
    final List messagesRaw;
    if (data is List) {
      messagesRaw = data;
    } else if (data is Map) {
      final nested = data['messages'] ?? data['items'];
      messagesRaw = nested is List ? nested : const [];
    } else {
      return const [];
    }

    return messagesRaw
        .whereType<Map>()
        .map(
          (item) => ChatMessageModel.fromJson(
            Map<String, dynamic>.from(item),
            conversationTitle: title,
          ),
        )
        .where((message) => message.id.isNotEmpty && message.message.isNotEmpty)
        .toList();
  }

  /// POST /drivers/chat/{conversationId}/messages
  Future<ChatMessageModel> sendMessage({
    required String conversationId,
    required String body,
    String conversationTitle = 'Dispatch',
  }) async {
    final id = conversationId.trim();
    if (id.isEmpty) {
      throw ApiException('Conversation id is required');
    }

    final text = body.trim();
    if (text.isEmpty) {
      throw ApiException('Message is required');
    }

    final response = await _api.post(
      ApiEndpoints.chatConversationMessages(id),
      body: {'body': text},
    );

    return _sentMessageFromResponse(
      response,
      conversationTitle: conversationTitle,
      fallbackBody: text,
    );
  }

  /// POST /drivers/chat/orders/{orderId}/messages
  /// Body: { "body": "...", "peer": "dispatch" }
  Future<ChatMessageModel> sendOrderMessage({
    required String orderId,
    required String body,
    String peer = 'dispatch',
    String conversationTitle = 'Dispatch',
  }) async {
    final id = orderId.trim();
    if (id.isEmpty) {
      throw ApiException('Order id is required');
    }

    final text = body.trim();
    if (text.isEmpty) {
      throw ApiException('Message is required');
    }

    final response = await _api.post(
      ApiEndpoints.chatOrderMessages(id),
      body: {
        'body': text,
        'peer': peer.trim().isEmpty ? 'dispatch' : peer.trim(),
      },
    );

    return _sentMessageFromResponse(
      response,
      conversationTitle: conversationTitle,
      fallbackBody: text,
    );
  }

  ChatMessageModel _sentMessageFromResponse(
    Map<String, dynamic> response, {
    required String conversationTitle,
    String fallbackBody = '',
  }) {
    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to send message'),
      );
    }

    final data = response['data'];
    Map<String, dynamic>? json;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final nested = map['message'];
      if (nested is Map && map['body'] == null && map['id'] == null) {
        json = Map<String, dynamic>.from(nested);
      } else {
        json = map;
      }
    }

    if (json == null && fallbackBody.isEmpty) {
      throw ApiException('Invalid response from server');
    }

    final parsed = ChatMessageModel.fromJson(
      json ?? const {},
      conversationTitle: conversationTitle,
    );
    if (parsed.message.isNotEmpty) return parsed;

    if (fallbackBody.isEmpty) {
      throw ApiException('Invalid response from server');
    }

    return ChatMessageModel(
      id: parsed.id.isNotEmpty
          ? parsed.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      message: fallbackBody,
      sender: 'Me',
      createdAt: parsed.createdAt,
      isMe: true,
      senderRole: 'DRIVER',
    );
  }

  /// POST /drivers/chat/{conversationId}/read
  Future<ChatReadModel> markConversationRead(String conversationId) async {
    final id = conversationId.trim();
    if (id.isEmpty) {
      throw ApiException('Conversation id is required');
    }

    final response = await _api.post(ApiEndpoints.chatConversationRead(id));

    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to mark chat as read'),
      );
    }

    final data = response['data'];
    if (data is! Map) {
      throw ApiException('Invalid response from server');
    }

    final result = ChatReadModel.fromJson(Map<String, dynamic>.from(data));
    if (result.conversationId.isEmpty) {
      throw ApiException('Invalid response from server');
    }

    return result;
  }

  /// GET /drivers/chat/quick-replies?peer=dispatch
  Future<List<QuickReplyModel>> getQuickReplies({
    String peer = 'dispatch',
  }) async {
    final response = await _api.get(ApiEndpoints.chatQuickReplies(peer: peer));

    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to load quick replies'),
      );
    }

    final data = response['data'];
    if (data is! Map) {
      throw ApiException('Invalid response from server');
    }

    final repliesRaw = data['replies'];
    if (repliesRaw is! List) {
      return const [];
    }

    return repliesRaw
        .whereType<Map>()
        .map((item) => QuickReplyModel.fromJson(Map<String, dynamic>.from(item)))
        .where((reply) => reply.id.isNotEmpty && reply.body.isNotEmpty)
        .toList();
  }

  String _failureMessage(Map<String, dynamic> response, String fallback) {
    final message = response['message']?.toString();
    if (message != null && message.trim().isNotEmpty) return message.trim();

    final error = response['error'];
    if (error is Map) {
      final nested = error['message']?.toString();
      if (nested != null && nested.trim().isNotEmpty) return nested.trim();
    }

    return fallback;
  }
}

class OpenedOrderChat {
  const OpenedOrderChat({
    required this.conversation,
    required this.messages,
  });

  final ChatConversationModel conversation;
  final List<ChatMessageModel> messages;
}

import 'package:yjeek_driver/core/constants/api_endpoints.dart';
import 'package:yjeek_driver/features/chat/model/chat_conversation_model.dart';
import 'package:yjeek_driver/features/chat/model/chat_message_model.dart';
import 'package:yjeek_driver/features/chat/model/quick_reply_model.dart';
import 'package:yjeek_driver/services/api_service.dart';

class ChatService {
  ChatService({ApiService? apiService})
      : _api = apiService ?? ApiService.instance;

  final ApiService _api;

  /// GET /drivers/chat
  Future<List<ChatConversationModel>> getChats() async {
    final response = await _api.get(ApiEndpoints.driverChats);

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
    return _parseMessages(data, title);
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
    );
  }

  /// POST /drivers/chat/orders/{orderId}/messages
  Future<ChatMessageModel> sendOrderMessage({
    required String orderId,
    required String body,
    String? peer,
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

    final payload = <String, dynamic>{'body': text};
    final peerValue = peer?.trim() ?? '';
    if (peerValue.isNotEmpty) {
      payload['peer'] = peerValue;
    }

    final response = await _api.post(
      ApiEndpoints.chatOrderMessages(id),
      body: payload,
    );

    return _sentMessageFromResponse(
      response,
      conversationTitle: conversationTitle,
    );
  }

  ChatMessageModel _sentMessageFromResponse(
    Map<String, dynamic> response, {
    required String conversationTitle,
  }) {
    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to send message'),
      );
    }

    final data = response['data'];
    if (data is! Map) {
      throw ApiException('Invalid response from server');
    }

    return ChatMessageModel.fromJson(
      Map<String, dynamic>.from(data),
      conversationTitle: conversationTitle,
    );
  }

  /// POST /drivers/chat/{conversationId}/read
  Future<void> markConversationRead(String conversationId) async {
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
  }

  /// GET /drivers/chat/quick-replies?peer=dispatch
  /// GET /drivers/chat/quick-replies?peer=customer
  Future<List<QuickReplyModel>> getQuickReplies({
    required String peer,
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

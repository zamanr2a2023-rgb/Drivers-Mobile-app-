import 'package:yjeek_driver/core/constants/api_endpoints.dart';
import 'package:yjeek_driver/features/chat/model/chat_message_model.dart';
import 'package:yjeek_driver/features/chat/model/quick_reply_model.dart';
import 'package:yjeek_driver/services/api_service.dart';

class ChatService {
  ChatService({ApiService? apiService})
      : _api = apiService ?? ApiService.instance;

  final ApiService _api;

  Future<List<ChatMessageModel>> getMessages() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    return [
      ChatMessageModel(
        id: '1',
        message: 'Hi, you have a new order assigned.',
        sender: 'Dispatch',
        createdAt: now.subtract(const Duration(minutes: 10)),
      ),
      ChatMessageModel(
        id: '2',
        message: 'On my way to pickup.',
        sender: 'Me',
        createdAt: now.subtract(const Duration(minutes: 8)),
        isMe: true,
      ),
      ChatMessageModel(
        id: '3',
        message: 'Great! Customer is waiting.',
        sender: 'Dispatch',
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
    ];
  }

  Future<ChatMessageModel> sendMessage(String message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      sender: 'Me',
      createdAt: DateTime.now(),
      isMe: true,
    );
  }

  /// GET /drivers/chat/quick-replies?peer=customer
  Future<List<QuickReplyModel>> getQuickReplies({
    String peer = 'customer',
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

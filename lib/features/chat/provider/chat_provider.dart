import 'package:flutter/foundation.dart';
import 'package:yjeek_driver/features/chat/model/chat_message_model.dart';
import 'package:yjeek_driver/features/chat/model/quick_reply_model.dart';
import 'package:yjeek_driver/features/chat/service/chat_service.dart';
import 'package:yjeek_driver/services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({ChatService? chatService})
      : _service = chatService ?? ChatService();

  final ChatService _service;

  bool _isLoading = false;
  bool _isLoadingQuickReplies = false;
  List<ChatMessageModel> _messages = [];
  List<QuickReplyModel> _quickReplies = [];
  String? _quickRepliesError;

  bool get isLoading => _isLoading;
  bool get isLoadingQuickReplies => _isLoadingQuickReplies;
  List<ChatMessageModel> get messages => _messages;
  List<QuickReplyModel> get quickReplies => _quickReplies;
  String? get quickRepliesError => _quickRepliesError;

  Future<void> loadMessages() async {
    _isLoading = true;
    notifyListeners();
    _messages = await _service.getMessages();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadQuickReplies({String peer = 'customer'}) async {
    _isLoadingQuickReplies = true;
    _quickRepliesError = null;
    notifyListeners();

    try {
      _quickReplies = await _service.getQuickReplies(peer: peer);
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

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final message = await _service.sendMessage(text.trim());
    _messages = [..._messages, message];
    notifyListeners();
  }

  Future<void> sendQuickReply(QuickReplyModel reply) async {
    final body = reply.body.trim();
    if (body.isEmpty) return;
    await sendMessage(body);
  }
}

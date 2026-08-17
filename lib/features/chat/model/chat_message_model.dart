class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.message,
    required this.sender,
    required this.createdAt,
    this.isMe = false,
    this.senderRole,
  });

  final String id;
  final String message;
  final String sender;
  final DateTime createdAt;
  final bool isMe;
  final String? senderRole;

  factory ChatMessageModel.fromJson(
    Map<String, dynamic> json, {
    String conversationTitle = 'Dispatch',
  }) {
    final role = json['senderRole']?.toString().toUpperCase() ?? '';
    final isMe = role == 'DRIVER';
    final String sender;
    if (isMe) {
      sender = 'Me';
    } else if (role == 'DISPATCH') {
      sender = 'Dispatch';
    } else if (role == 'SYSTEM') {
      sender = 'System';
    } else {
      sender = conversationTitle;
    }

    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      message: json['body']?.toString() ?? json['message']?.toString() ?? '',
      sender: sender,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      isMe: isMe,
      senderRole: role.isEmpty ? null : role,
    );
  }
}

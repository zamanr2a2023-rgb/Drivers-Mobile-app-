class ChatConversationModel {
  const ChatConversationModel({
    required this.id,
    required this.conversationId,
    required this.orderId,
    required this.orderNumber,
    required this.orderStatus,
    required this.type,
    required this.peer,
    required this.customerName,
    required this.createdAt,
    this.customerId,
    this.lastMessage,
    this.lastMessageAt,
  });

  final String id;
  final String conversationId;
  final String orderId;
  final String orderNumber;
  final String orderStatus;
  final String type;
  final String peer;
  final String customerName;
  final String? customerId;
  final ChatLastMessageModel? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  bool get isDispatch => peer.toLowerCase() == 'dispatch';

  String get title {
    if (isDispatch) return 'Dispatch';
    return customerName.trim().isNotEmpty ? customerName.trim() : 'Customer';
  }

  String get subtitle {
    final body = lastMessage?.body.trim() ?? '';
    if (body.isNotEmpty) return body;
    return orderNumber.trim().isNotEmpty ? orderNumber : 'No messages yet';
  }

  DateTime? get displayAt => lastMessageAt ?? lastMessage?.createdAt;

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    final customerRaw = json['customer'];
    final customer = customerRaw is Map
        ? Map<String, dynamic>.from(customerRaw)
        : <String, dynamic>{};
    final lastRaw = json['lastMessage'];

    return ChatConversationModel(
      id: json['id']?.toString() ?? json['conversationId']?.toString() ?? '',
      conversationId:
          json['conversationId']?.toString() ?? json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      orderStatus: json['orderStatus']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      peer: json['peer']?.toString() ?? '',
      customerId: customer['id']?.toString(),
      customerName: customer['name']?.toString() ?? '',
      lastMessage: lastRaw is Map
          ? ChatLastMessageModel.fromJson(Map<String, dynamic>.from(lastRaw))
          : null,
      lastMessageAt: _parseDate(json['lastMessageAt']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class ChatLastMessageModel {
  const ChatLastMessageModel({
    required this.body,
    required this.senderRole,
    required this.createdAt,
  });

  final String body;
  final String senderRole;
  final DateTime createdAt;

  bool get isFromDriver => senderRole.toUpperCase() == 'DRIVER';

  factory ChatLastMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatLastMessageModel(
      body: json['body']?.toString() ?? '',
      senderRole: json['senderRole']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

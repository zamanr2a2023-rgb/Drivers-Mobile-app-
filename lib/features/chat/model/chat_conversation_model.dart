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
    this.channel = '',
    this.vendorName = '',
    this.jobId = '',
    this.lifecycleStatus = '',
    this.closeReason,
    this.closedAt,
    this.customerId,
    this.lastMessage,
    this.lastMessageAt,
    this.updatedAt,
    this.isRead = false,
  });

  final String id;
  final String conversationId;
  final String orderId;
  final String orderNumber;
  final String orderStatus;
  final String type;
  final String peer;
  final String channel;
  final String vendorName;
  final String jobId;
  final String lifecycleStatus;
  final String? closeReason;
  final DateTime? closedAt;
  final String customerName;
  final String? customerId;
  final ChatLastMessageModel? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime? updatedAt;
  final DateTime createdAt;
  final bool isRead;

  bool get isDispatch {
    final p = peer.toLowerCase();
    final t = type.toUpperCase();
    return p == 'dispatch' || t == 'DISPATCH';
  }

  String get title {
    if (isDispatch) return 'Dispatch';
    return customerName.trim().isNotEmpty ? customerName.trim() : 'Customer';
  }

  String get subtitle {
    final body = lastMessage?.body.trim() ?? '';
    if (body.isNotEmpty) return body;
    return orderNumber.trim().isNotEmpty ? orderNumber : 'No messages yet';
  }

  DateTime? get displayAt =>
      lastMessageAt ?? lastMessage?.createdAt ?? updatedAt;

  ChatConversationModel copyWith({bool? isRead}) {
    return ChatConversationModel(
      id: id,
      conversationId: conversationId,
      orderId: orderId,
      orderNumber: orderNumber,
      orderStatus: orderStatus,
      type: type,
      peer: peer,
      customerName: customerName,
      createdAt: createdAt,
      channel: channel,
      vendorName: vendorName,
      jobId: jobId,
      lifecycleStatus: lifecycleStatus,
      closeReason: closeReason,
      closedAt: closedAt,
      customerId: customerId,
      lastMessage: lastMessage,
      lastMessageAt: lastMessageAt,
      updatedAt: updatedAt,
      isRead: isRead ?? this.isRead,
    );
  }

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    final customerRaw = json['customer'];
    final customer = customerRaw is Map
        ? Map<String, dynamic>.from(customerRaw)
        : <String, dynamic>{};
    final lifecycleRaw = json['lifecycle'];
    final lifecycle = lifecycleRaw is Map
        ? Map<String, dynamic>.from(lifecycleRaw)
        : <String, dynamic>{};
    final lastRaw = json['lastMessage'];
    ChatLastMessageModel? lastMessage = lastRaw is Map
        ? ChatLastMessageModel.fromJson(Map<String, dynamic>.from(lastRaw))
        : null;

    final messagesRaw = json['messages'];
    if (lastMessage == null && messagesRaw is List && messagesRaw.isNotEmpty) {
      final lastItem = messagesRaw.last;
      if (lastItem is Map) {
        lastMessage = ChatLastMessageModel.fromJson(
          Map<String, dynamic>.from(lastItem),
        );
      }
    }

    return ChatConversationModel(
      id: json['id']?.toString() ?? json['conversationId']?.toString() ?? '',
      conversationId:
          json['conversationId']?.toString() ?? json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      orderStatus: json['orderStatus']?.toString() ??
          json['jobStatus']?.toString() ??
          lifecycle['status']?.toString() ??
          '',
      type: json['type']?.toString() ?? '',
      peer: json['peer']?.toString() ?? '',
      channel: json['channel']?.toString() ?? '',
      vendorName: json['vendorName']?.toString() ?? '',
      jobId: json['jobId']?.toString() ?? '',
      lifecycleStatus: lifecycle['status']?.toString() ?? '',
      closeReason: lifecycle['closeReason']?.toString(),
      closedAt: _parseDate(lifecycle['closedAt']),
      customerId: customer['id']?.toString(),
      customerName: customer['name']?.toString() ?? '',
      lastMessage: lastMessage,
      lastMessageAt:
          _parseDate(json['lastMessageAt']) ?? lastMessage?.createdAt,
      updatedAt: _parseDate(json['updatedAt']),
      createdAt: _parseDate(json['createdAt']) ??
          lastMessage?.createdAt ??
          DateTime.now(),
      isRead: json['read'] == true,
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

class ChatReadModel {
  const ChatReadModel({
    required this.conversationId,
    required this.read,
  });

  final String conversationId;
  final bool read;

  factory ChatReadModel.fromJson(Map<String, dynamic> json) {
    return ChatReadModel(
      conversationId: json['conversationId']?.toString() ?? '',
      read: json['read'] == true,
    );
  }
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.createdAt,
    this.timeLabel,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime? createdAt;
  final String? timeLabel;
  final bool isRead;

  String get displayTime {
    final label = timeLabel?.trim();
    if (label != null && label.isNotEmpty) return label;

    final at = createdAt;
    if (at == null) return '';

    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${at.day}/${at.month}';
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      type: type,
      createdAt: createdAt,
      timeLabel: timeLabel,
      isRead: isRead ?? this.isRead,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ??
          json['message']?.toString() ??
          json['description']?.toString() ??
          '',
      type: json['type']?.toString() ?? '',
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
      timeLabel: json['timeAgo']?.toString() ?? json['time']?.toString(),
      isRead: json['isRead'] == true ||
          json['read'] == true ||
          json['is_read'] == true,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class NotificationsListData {
  const NotificationsListData({
    required this.today,
    required this.earlier,
    required this.unreadCount,
  });

  final List<NotificationModel> today;
  final List<NotificationModel> earlier;
  final int unreadCount;

  factory NotificationsListData.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map) {
      throw const FormatException('Invalid notifications response');
    }
    final map = Map<String, dynamic>.from(data);

    return NotificationsListData(
      today: _parseList(map['today']),
      earlier: _parseList(map['earlier']),
      unreadCount: _asInt(map['unreadCount']),
    );
  }

  static List<NotificationModel> _parseList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => NotificationModel.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class QuickReplyModel {
  const QuickReplyModel({
    required this.id,
    required this.label,
    required this.body,
  });

  final String id;
  final String label;
  final String body;

  factory QuickReplyModel.fromJson(Map<String, dynamic> json) {
    final body = json['body']?.toString().trim() ?? '';
    final label = json['label']?.toString().trim() ?? '';
    return QuickReplyModel(
      id: json['id']?.toString() ?? '',
      label: label.isNotEmpty ? label : body,
      body: body,
    );
  }
}

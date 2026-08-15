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
    return QuickReplyModel(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
    );
  }
}

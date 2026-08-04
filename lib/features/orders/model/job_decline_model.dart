/// Response from `POST /drivers/jobs/:jobId/decline`.
class JobDeclineResult {
  const JobDeclineResult({required this.message});

  final String message;

  factory JobDeclineResult.fromJson(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map) {
      throw const FormatException('Invalid decline response');
    }
    final map = Map<String, dynamic>.from(data);
    final message = map['message']?.toString().trim() ?? '';
    return JobDeclineResult(
      message: message.isNotEmpty ? message : 'Delivery request declined',
    );
  }
}

/// Response from `POST /drivers/jobs/:jobId/confirm-return`.
class JobConfirmReturnResult {
  const JobConfirmReturnResult({
    required this.message,
    required this.earningsAdded,
    required this.ratingProtected,
    required this.refundStatus,
  });

  final String message;
  final double earningsAdded;
  final bool ratingProtected;
  final String refundStatus;

  factory JobConfirmReturnResult.fromJson(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map) {
      throw const FormatException('Invalid confirm-return response');
    }
    final map = Map<String, dynamic>.from(data);
    return JobConfirmReturnResult(
      message: map['message']?.toString().trim().isNotEmpty == true
          ? map['message'].toString().trim()
          : 'Order returned to vendor',
      earningsAdded: _asDouble(map['earningsAdded']),
      ratingProtected: map['ratingProtected'] == true,
      refundStatus: map['refundStatus']?.toString() ?? '',
    );
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

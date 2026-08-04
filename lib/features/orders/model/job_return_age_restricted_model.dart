import 'package:yjeek_driver/features/orders/model/job_detail_model.dart';

/// Response from `POST /drivers/jobs/:jobId/return-age-restricted`.
class JobReturnAgeRestrictedResult {
  const JobReturnAgeRestrictedResult({
    required this.message,
    required this.ratingProtected,
    required this.earningsProtected,
    this.job,
  });

  final String message;
  final bool ratingProtected;
  final bool earningsProtected;
  final JobDetailModel? job;

  factory JobReturnAgeRestrictedResult.fromJson(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map) {
      throw const FormatException('Invalid return-age-restricted response');
    }
    final map = Map<String, dynamic>.from(data);
    final jobRaw = map['job'];

    return JobReturnAgeRestrictedResult(
      message: map['message']?.toString().trim().isNotEmpty == true
          ? map['message'].toString().trim()
          : 'Return started. Keep the order sealed and return it to the vendor.',
      ratingProtected: map['ratingProtected'] == true,
      earningsProtected: map['earningsProtected'] == true,
      job: jobRaw is Map
          ? JobDetailModel.fromJson(Map<String, dynamic>.from(jobRaw))
          : null,
    );
  }
}

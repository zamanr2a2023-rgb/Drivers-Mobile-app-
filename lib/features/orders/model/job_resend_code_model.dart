/// Response from `POST /drivers/jobs/:jobId/resend-code`.
class JobResendCodeResult {
  const JobResendCodeResult({
    required this.message,
    required this.codeReissued,
  });

  final String message;
  final bool codeReissued;

  factory JobResendCodeResult.fromJson(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map) {
      throw const FormatException('Invalid resend-code response');
    }
    final map = Map<String, dynamic>.from(data);
    return JobResendCodeResult(
      message: map['message']?.toString().trim().isNotEmpty == true
          ? map['message'].toString().trim()
          : 'A new one-time code was sent to the customer',
      codeReissued: map['codeReissued'] == true,
    );
  }
}

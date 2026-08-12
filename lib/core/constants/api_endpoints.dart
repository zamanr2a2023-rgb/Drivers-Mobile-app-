/// Central place for API base URL and endpoint paths.
class ApiEndpoints {
  ApiEndpoints._();

   static const String baseUrl = 'http://103.208.183.248:3000/api/v1';
 //static const String baseUrl = 'https://api.yjeektech.com/api/v1'; 
 //static const String baseUrl = "https://api.yjeektech.com/api/v1/health"; 

  // Auth
  static const String sendOtp = '/drivers/auth/send-otp';
  static const String verifyOtp = '/drivers/auth/verify-otp';
  static const String resendOtp = '/drivers/auth/resend-otp';

  // Home
  static const String home = '/drivers/home';
  static const String goOnline = '/drivers/go-online';
  static const String goOffline = '/drivers/go-offline';
  static const String driverStatus = '/drivers/status';
  static const String driverLocation = '/drivers/location';
  static const String autoAccept = '/drivers/settings/auto-accept';
  static const String driverSos = '/drivers/sos';

  // Earnings
  static const String earnings = '/drivers/earnings';
  static const String earningsTransactions = '/drivers/earnings/transactions';

  static String earningsByPeriod(String period) => _query(
        '/drivers/earnings',
        {'period': period},
      );

  static String get earningsDaily => earningsByPeriod('daily');
  static String get earningsWeekly => earningsByPeriod('weekly');
  static String get earningsMonthly => earningsByPeriod('monthly');

  // Profile / Account
  static const String driverProfile = '/drivers/profile';
  static const String accountPersonal = '/drivers/account/personal';
  static const String accountAvatar = '/drivers/account/avatar';
  static const String accountLanguage = '/drivers/account/language';
  static const String accountLogout = '/drivers/account/logout';

  // Content / localization (shared backend catalog)
  static const String contentLanguages = '/content/languages';
  static const String contentTranslations = '/content/translations';

  static String contentTranslationsFor(String lang) =>
      '$contentTranslations?lang=${Uri.encodeQueryComponent(lang.trim().toLowerCase())}';

  static const String accountPhoneSendOtp = '/drivers/account/phone/send-otp';
  static const String accountPhoneVerify = '/drivers/account/phone/verify';
  static const String accountVehicle = '/drivers/account/vehicle';
  static const String accountDocuments = '/drivers/account/documents';

  static String accountDocument(String type) =>
      '/drivers/account/documents/${_seg(type)}';

  /// Upload categories: address-photos | avatars | documents | delivery-proofs | vehicle-photos
  static String uploads({required String category}) => _query(
        '/uploads',
        {'category': category},
      );

  // Performance
  static const String performance = '/drivers/performance';

  // Notifications
  static const String notifications = '/drivers/notifications';
  static const String notificationsReadAll = '/drivers/notifications/read-all';

  static String notificationRead(String notificationId) =>
      '/drivers/notifications/${_seg(notificationId)}/read';

  // Jobs
  static const String jobOffers = '/drivers/jobs/offers';
  static const String jobActive = '/drivers/jobs/active';

  static String jobById(String jobId) => _job(jobId);
  static String jobAccept(String jobId) => _job(jobId, 'accept');
  static String jobDecline(String jobId) => _job(jobId, 'decline');
  static String jobRelease(String jobId) => _job(jobId, 'release');
  static String jobSos(String jobId) => _job(jobId, 'sos');
  static String jobArriveCustomer(String jobId) =>
      _job(jobId, 'arrive-customer');
  static String jobArrivePickup(String jobId) => _job(jobId, 'arrive-pickup');
  static String jobComplete(String jobId) => _job(jobId, 'complete');
  static String jobContactAttempts(String jobId) =>
      _job(jobId, 'contact-attempts');
  static String jobReport(String jobId) => _job(jobId, 'report');
  static String jobReportWait(String jobId) => _job(jobId, 'report-wait');
  static String jobUnableToDeliver(String jobId) =>
      _job(jobId, 'unable-to-deliver');
  static String jobConfirmOrder(String jobId) => _job(jobId, 'confirm-order');
  static String jobConfirmPickup(String jobId) => _job(jobId, 'confirm-pickup');
  static String jobResendCode(String jobId) => _job(jobId, 'resend-code');
  static String jobReturnAgeRestricted(String jobId) =>
      _job(jobId, 'return-age-restricted');
  static String jobReturn(String jobId) => _job(jobId, 'return');
  static String jobConfirmReturn(String jobId) => _job(jobId, 'confirm-return');

  static String jobsHistory({
    String type = 'all',
    bool includeCancelled = true,
    int limit = 20,
  }) =>
      _query('/drivers/jobs/history', {
        'type': type,
        'includeCancelled': '$includeCancelled',
        'limit': '$limit',
      });

  /// Instant: section=active|completed.
  /// Scheduled: section=new|require_confirmation|on_track|completed.
  static String jobsBoard({
    required String type,
    required String section,
    int limit = 20,
  }) =>
      _query('/drivers/jobs/board', {
        'type': type,
        'section': section,
        'limit': '$limit',
      });

  /// `/drivers/jobs/{jobId}` or `/drivers/jobs/{jobId}/{action}`
  static String _job(String jobId, [String? action]) {
    final id = _seg(jobId);
    if (action == null || action.isEmpty) return '/drivers/jobs/$id';
    return '/drivers/jobs/$id/$action';
  }

  static String _seg(String value) => Uri.encodeComponent(value.trim());

  static String _query(String path, Map<String, String> params) {
    return Uri(path: path, queryParameters: params).toString();
  }
}
// language update by init package and ntennt 
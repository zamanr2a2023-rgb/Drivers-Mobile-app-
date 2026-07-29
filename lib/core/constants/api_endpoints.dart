/// Central place for API base URL and endpoint paths.
class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'http://192.168.10.251:3000/api/v1';

  // Auth
  static const String sendOtp = '/drivers/auth/send-otp';
  static const String verifyOtp = '/drivers/auth/verify-otp';
  static const String resendOtp = '/drivers/auth/resend-otp';

  // Home
  static const String home = '/drivers/home';
  static const String goOnline = '/drivers/go-online';
  static const String goOffline = '/drivers/go-offline';
  static const String driverStatus = '/drivers/status';
  static const String autoAccept = '/drivers/settings/auto-accept';

  // Earnings
  static const String earnings = '/drivers/earnings';
  static const String earningsDaily = '/drivers/earnings?period=daily';
  static const String earningsWeekly = '/drivers/earnings?period=weekly';
  static const String earningsMonthly = '/drivers/earnings?period=monthly';
  static const String earningsTransactions = '/drivers/earnings/transactions';

  // Profile / Account
  static const String driverProfile = '/drivers/profile';
  static const String accountPersonal = '/drivers/account/personal';
  static const String accountAvatar = '/drivers/account/avatar';

  /// Upload categories: address-photos | avatars | documents | delivery-proofs | vehicle-photos
  static String uploads({required String category}) =>
      '/uploads?category=$category';

  // Performance
  static const String performance = '/drivers/performance';

  // Notifications
  static const String notifications = '/drivers/notifications';
  static const String notificationsReadAll = '/drivers/notifications/read-all';

  static String notificationRead(String notificationId) =>
      '/drivers/notifications/$notificationId/read';

  // Jobs
  static const String jobOffers = '/drivers/jobs/offers';
  static const String jobActive = '/drivers/jobs/active';
  static String jobsHistory({
    String type = 'all',
    bool includeCancelled = true,
    int limit = 20,
  }) =>
      '/drivers/jobs/history?type=$type&includeCancelled=$includeCancelled&limit=$limit';

  /// Instant: section=active|completed.
  /// Scheduled: section=new|require_confirmation|on_track|completed.
  static String jobsBoard({
    required String type,
    required String section,
    int limit = 20,
  }) =>
      '/drivers/jobs/board?type=$type&section=$section&limit=$limit';
}

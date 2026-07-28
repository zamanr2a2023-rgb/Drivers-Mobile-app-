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
  static const String goOffline = '/drivers/go-offline';
  static const String driverStatus = '/drivers/status';
  static const String autoAccept = '/drivers/settings/auto-accept';

  // Notifications
  static const String notifications = '/drivers/notifications';
  static const String notificationsReadAll = '/drivers/notifications/read-all';

  static String notificationRead(String notificationId) =>
      '/drivers/notifications/$notificationId/read';

  // Jobs
  static const String jobOffers = '/drivers/jobs/offers';
}

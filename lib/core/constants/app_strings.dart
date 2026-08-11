import 'package:yjeek_driver/l10n/l10n.dart';

class AppStrings {
  AppStrings._();

  static String get appName => L10n.tr('Yjeek Driver');
  static String get splashTagline => L10n.tr('Deliver with confidence');
  static String get loginTitle => L10n.tr('Welcome Driver');
  static String get loginSubtitle =>
      L10n.tr('Enter your phone number to continue');
  static String get otpTitle => L10n.tr('Verify OTP');
  static String get otpSubtitle =>
      L10n.tr('Enter the 6-digit code sent to your phone');
  static String get accountNotRegistered => L10n.tr('Account Not Registered');
  static String get contactSupport => L10n.tr('Contact Support');
  static String get backToLogin => L10n.tr('Back to Login');
  static String get driverHome => L10n.tr('Driver Home');
  static String get goOnline => L10n.tr('Go Online');
  static String get goOffline => L10n.tr('Go Offline');
  static String get viewOrders => L10n.tr('View Orders');
  static String get safetyHelp => L10n.tr('Safety Help');
  static String get logout => L10n.tr('Logout');
  static String get save => L10n.tr('Save');
  static String get submit => L10n.tr('Submit');
  static String get confirm => L10n.tr('Confirm');
  static String get cancel => L10n.tr('Cancel');
  static String get accept => L10n.tr('Accept');
  static String get reject => L10n.tr('Reject');
  static String get send => L10n.tr('Send');
  static String get requestPayout => L10n.tr('Request Payout');
  static String get privacyPolicy => L10n.tr('Privacy Policy');
}

import 'package:flutter/foundation.dart';
import 'package:yjeek_driver/features/auth/model/account_not_registered_exception.dart';
import 'package:yjeek_driver/features/auth/model/driver_model.dart';
import 'package:yjeek_driver/features/auth/model/send_otp_result.dart';
import 'package:yjeek_driver/features/auth/model/verify_otp_result.dart';
import 'package:yjeek_driver/features/auth/service/auth_service.dart';
import 'package:yjeek_driver/services/api_service.dart';
import 'package:yjeek_driver/services/push_notification_service.dart';

class AuthProvider extends ChangeNotifier {
  Future<void>? _restoreFuture;

  AuthProvider() {
    _restoreFuture = _restoreSession();
  }

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _phone;
  String? _countryCode;
  int? _expiresInSeconds;
  DriverModel? _driver;
  AuthUserModel? _user;
  String? _accessToken;
  String? _refreshToken;
  String? _error;

  bool get isLoading => _isLoading;
  String? get phone => _phone;
  String? get countryCode => _countryCode;
  int? get expiresInSeconds => _expiresInSeconds;
  DriverModel? get driver => _driver;
  AuthUserModel? get user => _user;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get error => _error;
  bool get isAuthenticated =>
      _accessToken != null && _accessToken!.isNotEmpty && _user != null;

  /// Ensures stored token/user are loaded (safe to call multiple times).
  Future<void> restoreSession() => _restoreFuture ??= _restoreSession();

  Future<void> _restoreSession() async {
    await _authService.restoreSession();
    final storedUser = await _authService.loadStoredUser();
    final token = ApiService.instance.accessToken;
    if (storedUser == null || token == null || token.isEmpty) return;

    _user = storedUser;
    _driver = _authService.toDriverModel(storedUser);
    _accessToken = token;
    _refreshToken = await _authService.loadRefreshToken();
    notifyListeners();
    PushNotificationService.instance.syncToken();
  }

  Future<SendOtpResult?> sendOtp({
    required String phone,
    required String countryCode,
  }) async {
    return _sendOrResendOtp(
      phone: phone,
      countryCode: countryCode,
      request: () => _authService.sendOtp(
        phone: phone,
        countryCode: countryCode,
      ),
      failureMessage: 'Failed to send OTP',
    );
  }

  Future<SendOtpResult?> resendOtp({
    required String phone,
    required String countryCode,
  }) async {
    return _sendOrResendOtp(
      phone: phone,
      countryCode: countryCode,
      request: () => _authService.resendOtp(
        phone: phone,
        countryCode: countryCode,
      ),
      failureMessage: 'Failed to resend OTP',
    );
  }

  Future<SendOtpResult?> _sendOrResendOtp({
    required String phone,
    required String countryCode,
    required Future<SendOtpResult> Function() request,
    required String failureMessage,
  }) async {
    _isLoading = true;
    _error = null;
    _phone = phone;
    _countryCode = countryCode;
    notifyListeners();

    try {
      final result = await request();
      _expiresInSeconds = result.expiresInSeconds;
      _isLoading = false;
      notifyListeners();
      return result;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (_) {
      _error = failureMessage;
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Returns [VerifyOtpResult] on success.
  /// Throws [AccountNotRegisteredException] when account is not registered.
  /// Returns `null` on invalid OTP / other failures (see [error]).
  Future<VerifyOtpResult?> verifyOtp({
    required String phone,
    required String countryCode,
    required String code,
  }) async {
    _isLoading = true;
    _error = null;
    _phone = phone;
    _countryCode = countryCode;
    notifyListeners();

    try {
      final result = await _authService.verifyOtp(
        phone: phone,
        countryCode: countryCode,
        code: code,
      );
      _user = result.user;
      _driver = _authService.toDriverModel(result.user);
      _accessToken = result.accessToken;
      _refreshToken = result.refreshToken;
      _isLoading = false;
      notifyListeners();
      PushNotificationService.instance.syncToken();
      return result;
    } on AccountNotRegisteredException {
      _isLoading = false;
      notifyListeners();
      rethrow;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (_) {
      _error = 'Verification failed';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> logout() async {
    await PushNotificationService.instance.unregisterCurrentToken();
    try {
      await _authService.logoutAccount();
    } catch (_) {
      // Still clear local session so the user can leave the account.
    }
    await _authService.clearSession();
    _driver = null;
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    _phone = null;
    _countryCode = null;
    _expiresInSeconds = null;
    _error = null;
    _restoreFuture = null;
    notifyListeners();
  }

  /// Updates in-memory tokens after account phone change (or similar flows).
  void applyTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    notifyListeners();
  }
}

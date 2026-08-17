import 'dart:convert';

import 'package:yjeek_driver/core/constants/api_endpoints.dart';
import 'package:yjeek_driver/core/constants/storage_keys.dart';
import 'package:yjeek_driver/features/auth/model/account_not_registered_exception.dart';
import 'package:yjeek_driver/features/auth/model/driver_model.dart';
import 'package:yjeek_driver/features/auth/model/send_otp_result.dart';
import 'package:yjeek_driver/features/auth/model/verify_otp_result.dart';
import 'package:yjeek_driver/services/api_service.dart';
import 'package:yjeek_driver/services/storage_service.dart';

class AuthService {
  AuthService({
    ApiService? apiService,
    StorageService? storage,
  })  : _api = apiService ?? ApiService.instance,
        _storage = storage;

  final ApiService _api;
  StorageService? _storage;

  Future<StorageService> _getStorage() async {
    return _storage ??= await StorageService.getInstance();
  }

  Future<SendOtpResult> sendOtp({
    required String phone,
    required String countryCode,
  }) async {
    return _requestOtp(
      endpoint: ApiEndpoints.sendOtp,
      phone: phone,
      countryCode: countryCode,
      failureMessage: 'Failed to send OTP',
    );
  }

  Future<SendOtpResult> resendOtp({
    required String phone,
    required String countryCode,
  }) async {
    return _requestOtp(
      endpoint: ApiEndpoints.resendOtp,
      phone: phone,
      countryCode: countryCode,
      failureMessage: 'Failed to resend OTP',
    );
  }

  Future<SendOtpResult> _requestOtp({
    required String endpoint,
    required String phone,
    required String countryCode,
    required String failureMessage,
  }) async {
    final response = await _api.post(
      endpoint,
      body: {
        'phone': phone,
        'countryCode': countryCode,
      },
    );

    if (response['success'] != true) {
      final message = response['message']?.toString();
      throw ApiException(
        (message != null && message.trim().isNotEmpty)
            ? message.trim()
            : failureMessage,
      );
    }

    try {
      // [SendOtpResult.devCode] is never displayed or logged.
      return SendOtpResult.fromJson(response);
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  Future<VerifyOtpResult> verifyOtp({
    required String phone,
    required String countryCode,
    required String code,
  }) async {
    late final Map<String, dynamic> response;
    try {
      response = await _api.post(
        ApiEndpoints.verifyOtp,
        body: {
          'phone': phone,
          'countryCode': countryCode,
          'code': code,
        },
      );
    } on ApiException catch (e) {
      if (_isNotRegisteredError(e.message, e.statusCode, e.code)) {
        throw AccountNotRegisteredException(e.message);
      }
      rethrow;
    }

    if (response['success'] != true) {
      final message = response['message']?.toString() ?? 'Verification failed';
      if (_isNotRegisteredError(message, null, response['code']?.toString())) {
        throw AccountNotRegisteredException(message);
      }
      throw ApiException(message);
    }

    try {
      final result = VerifyOtpResult.fromJson(response);
      await _persistSession(result);
      return result;
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  Future<void> _persistSession(VerifyOtpResult result) async {
    final storage = await _getStorage();
    await storage.saveString(StorageKeys.accessToken, result.accessToken);
    await storage.saveString(StorageKeys.refreshToken, result.refreshToken);
    await storage.saveString(
      StorageKeys.authUser,
      jsonEncode(result.user.toJson()),
    );
    _api.setAccessToken(result.accessToken);
  }

  Future<void> restoreSession() async {
    final storage = await _getStorage();
    final token = storage.getString(StorageKeys.accessToken);
    _api.setAccessToken(token);
  }

  Future<String?> loadRefreshToken() async {
    final storage = await _getStorage();
    return storage.getString(StorageKeys.refreshToken);
  }

  Future<AuthUserModel?> loadStoredUser() async {
    final storage = await _getStorage();
    final raw = storage.getString(StorageKeys.authUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AuthUserModel.fromJson(decoded);
      }
      if (decoded is Map) {
        return AuthUserModel.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> clearSession() async {
    final storage = await _getStorage();
    await storage.remove(StorageKeys.accessToken);
    await storage.remove(StorageKeys.refreshToken);
    await storage.remove(StorageKeys.authUser);
    _api.clearAccessToken();
  }

  /// Revokes the current JWT on the server. Safe to call before clearing local session.
  Future<void> logoutAccount() async {
    final response = await _api.post(ApiEndpoints.accountLogout);
    if (response['success'] != true) {
      final message = response['message']?.toString().trim();
      throw ApiException(
        (message != null && message.isNotEmpty) ? message : 'Failed to log out',
      );
    }
  }

  DriverModel toDriverModel(AuthUserModel user) {
    final profile = user.driverProfile;
    final name = user.displayName;
    final phone = '${user.countryCode}${user.phone}';
    return DriverModel(
      id: user.id,
      name: name,
      phone: phone,
      email: user.email,
      rating: profile?.averageRating ?? 0,
      isOnline: profile?.status.toUpperCase() == 'ONLINE',
    );
  }

  bool _isNotRegisteredError(String message, int? statusCode, String? code) {
    final normalizedCode = (code ?? '').toUpperCase();
    if (normalizedCode.contains('NOT_REGISTERED') ||
        normalizedCode.contains('ACCOUNT_NOT_FOUND') ||
        normalizedCode.contains('DRIVER_NOT_FOUND') ||
        normalizedCode.contains('USER_NOT_FOUND')) {
      return true;
    }

    final normalized = message.toLowerCase();
    final looksUnregistered = normalized.contains('not registered') ||
        normalized.contains('number not registered') ||
        normalized.contains('account does not exist') ||
        normalized.contains('no driver account') ||
        normalized.contains('driver not found') ||
        normalized.contains('user not found');

    if (looksUnregistered) return true;

    // Only treat 404 as unregistered when the message also hints at account/user.
    if (statusCode == 404) {
      return normalized.contains('account') ||
          normalized.contains('driver') ||
          normalized.contains('user') ||
          normalized.contains('phone') ||
          normalized.contains('registered');
    }

    return false;
  }
}

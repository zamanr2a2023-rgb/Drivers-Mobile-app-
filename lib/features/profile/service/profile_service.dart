import 'dart:typed_data';

import 'package:yjeek_driver/core/constants/api_endpoints.dart';
import 'package:yjeek_driver/core/constants/storage_keys.dart';
import 'package:yjeek_driver/features/auth/model/send_otp_result.dart';
import 'package:yjeek_driver/features/profile/model/account_documents_model.dart';
import 'package:yjeek_driver/features/profile/model/driver_profile_model.dart';
import 'package:yjeek_driver/features/profile/model/driver_vehicle_model.dart';
import 'package:yjeek_driver/features/profile/model/personal_account_model.dart';
import 'package:yjeek_driver/features/profile/model/phone_change_verify_result.dart';
import 'package:yjeek_driver/features/profile/model/profile_model.dart';
import 'package:yjeek_driver/services/api_service.dart';
import 'package:yjeek_driver/services/storage_service.dart';

class ProfileService {
  ProfileService({ApiService? apiService})
      : _api = apiService ?? ApiService.instance;

  final ApiService _api;

  Future<DriverProfileModel> getDriverProfile() async {
    final response = await _api.get(ApiEndpoints.driverProfile);

    if (response['success'] != true) {
      final message = response['message']?.toString().trim();
      throw ApiException(
        (message != null && message.isNotEmpty)
            ? message
            : 'Failed to load profile',
      );
    }

    final data = response['data'];
    if (data is! Map) {
      throw ApiException('Invalid response from server');
    }

    try {
      return DriverProfileModel.fromJson(Map<String, dynamic>.from(data));
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  Future<PersonalAccountModel> getPersonalAccount() async {
    final response = await _api.get(ApiEndpoints.accountPersonal);

    if (response['success'] != true) {
      final message = response['message']?.toString().trim();
      throw ApiException(
        (message != null && message.isNotEmpty)
            ? message
            : 'Failed to load personal account',
      );
    }

    final data = response['data'];
    if (data is! Map) {
      throw ApiException('Invalid response from server');
    }

    try {
      return PersonalAccountModel.fromJson(Map<String, dynamic>.from(data));
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  Future<PersonalAccountModel> updatePersonalAccount({
    required String firstName,
    required String lastName,
    required String email,
    String? dateOfBirth,
    String? gender,
  }) async {
    final body = <String, dynamic>{
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': email.trim(),
      'dateOfBirth': dateOfBirth,
      'gender': gender,
    };

    final response = await _api.patch(
      ApiEndpoints.accountPersonal,
      body: body,
    );

    if (response['success'] != true) {
      final message = response['message']?.toString().trim();
      throw ApiException(
        (message != null && message.isNotEmpty)
            ? message
            : 'Failed to update personal info',
      );
    }

    final data = response['data'];
    if (data is! Map) {
      throw ApiException('Invalid response from server');
    }

    try {
      return PersonalAccountModel.fromJson(Map<String, dynamic>.from(data));
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  /// Uploads a profile photo, then updates account avatar with the returned URL.
  Future<String> updateAvatar({
    required List<int> bytes,
    String filename = 'avatar.jpg',
    String contentType = 'image/jpeg',
  }) async {
    final uploadResponse = await _api.postMultipart(
      ApiEndpoints.uploads(category: 'avatars'),
      fieldName: 'file',
      bytes: Uint8List.fromList(bytes),
      filename: filename,
      contentType: contentType,
    );

    if (uploadResponse['success'] != true) {
      final message = uploadResponse['message']?.toString().trim();
      throw ApiException(
        (message != null && message.isNotEmpty)
            ? message
            : 'Failed to upload avatar',
      );
    }

    final uploadData = uploadResponse['data'];
    if (uploadData is! Map) {
      throw ApiException('Invalid response from server');
    }

    final uploadedUrl = uploadData['url']?.toString().trim() ?? '';
    if (uploadedUrl.isEmpty) {
      throw ApiException('Invalid response from server');
    }

    final response = await _api.patch(
      ApiEndpoints.accountAvatar,
      body: {'avatarUrl': uploadedUrl},
    );

    if (response['success'] != true) {
      final message = response['message']?.toString().trim();
      throw ApiException(
        (message != null && message.isNotEmpty)
            ? message
            : 'Failed to update avatar',
      );
    }

    final data = response['data'];
    if (data is! Map) {
      throw ApiException('Invalid response from server');
    }

    final avatarUrl = data['avatarUrl']?.toString().trim() ?? '';
    if (avatarUrl.isEmpty) {
      throw ApiException('Invalid response from server');
    }
    return avatarUrl;
  }

  /// Updates the driver's preferred language. Returns the saved language code.
  Future<String> updateLanguage(String language) async {
    final code = language.trim().toLowerCase();
    if (code.isEmpty) {
      throw ApiException('Language is required');
    }

    final response = await _api.patch(
      ApiEndpoints.accountLanguage,
      body: {'language': code},
    );

    if (response['success'] != true) {
      final message = response['message']?.toString().trim();
      throw ApiException(
        (message != null && message.isNotEmpty)
            ? message
            : 'Failed to update language',
      );
    }

    final data = response['data'];
    if (data is Map) {
      final saved = data['language']?.toString().trim();
      if (saved != null && saved.isNotEmpty) return saved;
    }

    return code;
  }

  /// Ends the server session. No request body.
  Future<void> logoutAccount() async {
    final response = await _api.post(ApiEndpoints.accountLogout);

    if (response['success'] != true) {
      final message = response['message']?.toString().trim();
      throw ApiException(
        (message != null && message.isNotEmpty)
            ? message
            : 'Failed to log out',
      );
    }
  }

  /// Sends OTP to a new phone number for account phone change.
  Future<SendOtpResult> sendPhoneChangeOtp({
    required String phone,
    required String countryCode,
  }) {
    return _requestPhoneChangeOtp(
      phone: phone,
      countryCode: countryCode,
      failureMessage: 'Failed to send OTP',
    );
  }

  /// Resends OTP for account phone change using the same send-otp API.
  Future<SendOtpResult> resendPhoneChangeOtp({
    required String phone,
    required String countryCode,
  }) {
    return _requestPhoneChangeOtp(
      phone: phone,
      countryCode: countryCode,
      failureMessage: 'Failed to resend OTP',
    );
  }

  Future<SendOtpResult> _requestPhoneChangeOtp({
    required String phone,
    required String countryCode,
    required String failureMessage,
  }) async {
    final response = await _api.post(
      ApiEndpoints.accountPhoneSendOtp,
      body: {
        'phone': phone.trim(),
        'countryCode': countryCode.trim(),
      },
    );

    if (response['success'] != true) {
      final message = response['message']?.toString().trim();
      throw ApiException(
        (message != null && message.isNotEmpty)
            ? message
            : failureMessage,
      );
    }

    try {
      return SendOtpResult.fromJson(response);
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  /// Verifies OTP and updates the account phone number.
  /// Persists the new access/refresh tokens from the response.
  Future<PhoneChangeVerifyResult> verifyPhoneChange({
    required String phone,
    required String countryCode,
    required String code,
  }) async {
    final response = await _api.post(
      ApiEndpoints.accountPhoneVerify,
      body: {
        'phone': phone.trim(),
        'countryCode': countryCode.trim(),
        'code': code.trim(),
      },
    );

    if (response['success'] != true) {
      final message = response['message']?.toString().trim();
      throw ApiException(
        (message != null && message.isNotEmpty)
            ? message
            : 'Failed to verify phone number',
      );
    }

    late final PhoneChangeVerifyResult result;
    try {
      result = PhoneChangeVerifyResult.fromJson(response);
    } on FormatException {
      throw ApiException('Invalid response from server');
    }

    final storage = await StorageService.getInstance();
    await storage.saveString(StorageKeys.accessToken, result.accessToken);
    await storage.saveString(StorageKeys.refreshToken, result.refreshToken);
    _api.setAccessToken(result.accessToken);

    return result;
  }

  Future<DriverVehicleModel> getVehicle() async {
    final response = await _api.get(ApiEndpoints.accountVehicle);

    if (response['success'] != true) {
      final message = response['message']?.toString().trim();
      throw ApiException(
        (message != null && message.isNotEmpty)
            ? message
            : 'Failed to load vehicle',
      );
    }

    final data = response['data'];
    if (data is! Map) {
      throw ApiException('Invalid response from server');
    }

    try {
      return DriverVehicleModel.fromJson(Map<String, dynamic>.from(data));
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  /// Uploads a file and returns its public URL.
  Future<String> uploadFile({
    required List<int> bytes,
    required String category,
    String filename = 'photo.jpg',
    String contentType = 'image/jpeg',
  }) async {
    final response = await _api.postMultipart(
      ApiEndpoints.uploads(category: category),
      fieldName: 'file',
      bytes: Uint8List.fromList(bytes),
      filename: filename,
      contentType: contentType,
    );

    if (response['success'] != true) {
      final message = response['message']?.toString().trim();
      throw ApiException(
        (message != null && message.isNotEmpty)
            ? message
            : 'Failed to upload file',
      );
    }

    final data = response['data'];
    if (data is! Map) {
      throw ApiException('Invalid response from server');
    }

    final url = data['url']?.toString().trim() ?? '';
    if (url.isEmpty) {
      throw ApiException('Invalid response from server');
    }
    return url;
  }

  /// Creates or updates the driver vehicle profile.
  Future<DriverVehicleModel> upsertVehicle({
    required String vehicleType,
    required String plateNumber,
    String? make,
    String? model,
    String? color,
    int? year,
    String? frontPhotoUrl,
    String? backPhotoUrl,
    String? sidePhotoUrl,
    String? interiorPhotoUrl,
    String? insuranceExpiryDate,
  }) async {
    final body = <String, dynamic>{
      'vehicleType': vehicleType.trim().toUpperCase(),
      'plateNumber': plateNumber.trim(),
      if (make != null && make.trim().isNotEmpty) 'make': make.trim(),
      if (model != null && model.trim().isNotEmpty) 'model': model.trim(),
      if (color != null && color.trim().isNotEmpty) 'color': color.trim(),
      if (year != null) 'year': year,
      if (frontPhotoUrl != null && frontPhotoUrl.trim().isNotEmpty)
        'frontPhotoUrl': frontPhotoUrl.trim(),
      if (backPhotoUrl != null && backPhotoUrl.trim().isNotEmpty)
        'backPhotoUrl': backPhotoUrl.trim(),
      if (sidePhotoUrl != null && sidePhotoUrl.trim().isNotEmpty)
        'sidePhotoUrl': sidePhotoUrl.trim(),
      if (interiorPhotoUrl != null && interiorPhotoUrl.trim().isNotEmpty)
        'interiorPhotoUrl': interiorPhotoUrl.trim(),
      if (insuranceExpiryDate != null && insuranceExpiryDate.trim().isNotEmpty)
        'insuranceExpiryDate': insuranceExpiryDate.trim(),
    };

    final response = await _api.put(
      ApiEndpoints.accountVehicle,
      body: body,
    );

    if (response['success'] != true) {
      final message = response['message']?.toString().trim();
      throw ApiException(
        (message != null && message.isNotEmpty)
            ? message
            : 'Failed to save vehicle',
      );
    }

    final data = response['data'];
    if (data is! Map) {
      throw ApiException('Invalid response from server');
    }

    try {
      return DriverVehicleModel.fromJson(Map<String, dynamic>.from(data));
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  Future<AccountDocumentsModel> getDocuments() async {
    final response = await _api.get(ApiEndpoints.accountDocuments);

    if (response['success'] != true) {
      final message = response['message']?.toString().trim();
      throw ApiException(
        (message != null && message.isNotEmpty)
            ? message
            : 'Failed to load documents',
      );
    }

    try {
      return AccountDocumentsModel.fromJson(response);
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  /// Creates or updates a single account document by type (e.g. CPR_FRONT).
  Future<AccountDocumentModel> upsertAccountDocument({
    required String type,
    required String imageUrl,
    String? documentNumber,
    String? expiryDate,
    String? nationality,
  }) async {
    final body = <String, dynamic>{
      'imageUrl': imageUrl.trim(),
    };

    final number = documentNumber?.trim();
    if (number != null && number.isNotEmpty) {
      body['documentNumber'] = number;
    }

    final expiry = expiryDate?.trim();
    if (expiry != null && expiry.isNotEmpty) {
      body['expiryDate'] = expiry;
    }

    final nation = nationality?.trim();
    if (nation != null && nation.isNotEmpty) {
      body['nationality'] = nation;
    }

    final response = await _api.put(
      ApiEndpoints.accountDocument(type),
      body: body,
    );

    if (response['success'] != true) {
      final message = response['message']?.toString().trim();
      throw ApiException(
        (message != null && message.isNotEmpty)
            ? message
            : 'Failed to save document',
      );
    }

    final data = response['data'];
    if (data is! Map) {
      throw ApiException('Invalid response from server');
    }

    try {
      return AccountDocumentModel.fromJson(Map<String, dynamic>.from(data));
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  Future<ProfileModel> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const ProfileModel(
      name: 'John Driver',
      phone: '+1234567890',
      email: 'john.driver@yjeek.com',
      vehicleType: 'Motorcycle',
      plateNumber: 'ABC-1234',
      licenseNumber: 'DL-987654',
      licenseStatus: 'Verified',
      rating: 4.8,
    );
  }

  Future<bool> updateProfile(ProfileModel profile) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}

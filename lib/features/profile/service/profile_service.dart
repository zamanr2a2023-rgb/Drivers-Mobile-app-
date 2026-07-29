import 'dart:typed_data';

import 'package:yjeek_driver/core/constants/api_endpoints.dart';
import 'package:yjeek_driver/features/profile/model/driver_profile_model.dart';
import 'package:yjeek_driver/features/profile/model/personal_account_model.dart';
import 'package:yjeek_driver/features/profile/model/profile_model.dart';
import 'package:yjeek_driver/services/api_service.dart';

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

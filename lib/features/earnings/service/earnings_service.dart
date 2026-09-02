import 'package:yjeek_driver/core/constants/api_endpoints.dart';
import 'package:yjeek_driver/features/dashboard/model/ui_banner_model.dart';
import 'package:yjeek_driver/features/earnings/model/earning_model.dart';
import 'package:yjeek_driver/services/api_service.dart';

class EarningsService {
  EarningsService({ApiService? apiService})
      : _api = apiService ?? ApiService.instance;

  final ApiService _api;

  Future<HomeUiBannersModel> getEarningsBanners() async {
    final response = await _api.get(ApiEndpoints.publicBannersEarnings);
    if (response['success'] != true) {
      final message = response['message']?.toString().trim();
      throw ApiException(
        (message != null && message.isNotEmpty)
            ? message
            : 'Failed to load banners',
      );
    }

    try {
      return HomeUiBannersModel.fromJson(response);
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  Future<List<EarningModel>> getTransactions() async {
    final response = await _api.get(ApiEndpoints.earningsTransactions);

    if (response['success'] != true) {
      final message = response['message']?.toString().trim();
      throw ApiException(
        (message != null && message.isNotEmpty)
            ? message
            : 'Failed to load transactions',
      );
    }

    final data = response['data'];
    if (data is! List) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => EarningModel.fromJson(e))
        .toList();
  }

  Future<Map<String, double>> getEarningsSummary() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return {
      'totalBalance': 342.50,
      'today': 45.25,
      'weekly': 198.75,
      'monthly': 1245.00,
    };
  }
}

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
    Future<double> totalFor(String period) async {
      try {
        final response = await _api.get(ApiEndpoints.earningsByPeriod(period));
        if (response['success'] != true) return 0;
        final data = response['data'];
        if (data is! Map) return 0;
        final summary = data['summary'];
        if (summary is! Map) return 0;
        final value = summary['totalEarnings'];
        if (value is num) return value.toDouble();
        return double.tryParse(value?.toString() ?? '') ?? 0;
      } catch (_) {
        return 0;
      }
    }

    Future<double> availableBalance() async {
      try {
        final response = await _api.get(ApiEndpoints.earningsDaily);
        if (response['success'] != true) return 0;
        final data = response['data'];
        if (data is! Map) return 0;
        final wallet = data['wallet'];
        if (wallet is! Map) return 0;
        final value = wallet['available'] ??
            wallet['balance'] ??
            wallet['availableBalance'];
        if (value is num) return value.toDouble();
        return double.tryParse(value?.toString() ?? '') ?? 0;
      } catch (_) {
        return 0;
      }
    }

    final results = await Future.wait([
      availableBalance(),
      totalFor('daily'),
      totalFor('weekly'),
      totalFor('monthly'),
    ]);

    return {
      'totalBalance': results[0],
      'today': results[1],
      'weekly': results[2],
      'monthly': results[3],
    };
  }
}

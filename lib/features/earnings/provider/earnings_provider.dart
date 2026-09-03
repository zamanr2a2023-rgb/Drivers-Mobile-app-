import 'package:flutter/foundation.dart';
import 'package:yjeek_driver/features/dashboard/model/ui_banner_model.dart';
import 'package:yjeek_driver/features/earnings/model/earning_model.dart';
import 'package:yjeek_driver/features/earnings/service/earnings_service.dart';
import 'package:yjeek_driver/services/api_service.dart';

class EarningsProvider extends ChangeNotifier {
  EarningsProvider({EarningsService? service})
      : _service = service ?? EarningsService();

  final EarningsService _service;

  bool _isLoading = false;
  List<EarningModel> _transactions = [];
  double _totalBalance = 0;
  double _todayEarning = 0;
  double _weeklyEarning = 0;
  double _monthlyEarning = 0;
  bool _earningsBannersLoading = false;
  String? _earningsBannersError;
  HomeUiBannersModel? _earningsBanners;

  bool get isLoading => _isLoading;
  List<EarningModel> get transactions => _transactions;
  double get totalBalance => _totalBalance;
  double get todayEarning => _todayEarning;
  double get weeklyEarning => _weeklyEarning;
  double get monthlyEarning => _monthlyEarning;
  bool get earningsBannersLoading => _earningsBannersLoading;
  String? get earningsBannersError => _earningsBannersError;

  List<UiBannerModel> earningsBannersFor(String placementKey) =>
      _earningsBanners?.forPlacement(placementKey) ?? const [];

  Future<void> loadEarningsBanners() async {
    _earningsBannersLoading = true;
    _earningsBannersError = null;
    notifyListeners();

    try {
      _earningsBanners = await _service.getEarningsBanners();
    } on ApiException catch (e) {
      _earningsBannersError = e.message;
    } catch (_) {
      _earningsBannersError = 'Failed to load banners';
    } finally {
      _earningsBannersLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEarnings() async {
    _isLoading = true;
    notifyListeners();
    final summary = await _service.getEarningsSummary();
    _totalBalance = summary['totalBalance'] ?? 0;
    _todayEarning = summary['today'] ?? 0;
    _weeklyEarning = summary['weekly'] ?? 0;
    _monthlyEarning = summary['monthly'] ?? 0;
    _transactions = await _service.getTransactions();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> requestPayout(double amount) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    _totalBalance -= amount;
    _isLoading = false;
    notifyListeners();
    return true;
  }
}

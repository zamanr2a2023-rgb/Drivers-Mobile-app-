import 'package:flutter/foundation.dart';
import 'package:yjeek_driver/features/orders/model/job_board_model.dart';
import 'package:yjeek_driver/features/orders/model/job_offer_model.dart';
import 'package:yjeek_driver/features/orders/model/order_model.dart';
import 'package:yjeek_driver/features/orders/service/order_service.dart';
import 'package:yjeek_driver/services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider({OrderService? orderService})
      : _orderService = orderService ?? OrderService();

  final OrderService _orderService;

  bool _isLoading = false;
  bool _isLoadingOffers = false;
  bool _isLoadingInstantBoard = false;
  bool _isLoadingScheduledNewBoard = false;
  List<OrderModel> _orders = [];
  List<JobOfferModel> _offers = const [];
  List<JobsBoardJob> _instantActiveJobs = const [];
  List<JobsBoardJob> _instantCompletedJobs = const [];
  List<JobsBoardJob> _scheduledNewJobs = const [];
  JobsBoardCounts _instantCounts = const JobsBoardCounts();
  JobsBoardCounts _scheduledCounts = const JobsBoardCounts();
  OrderModel? _currentOrder;
  OrderModel? _newRequest;
  JobOfferModel? _currentOffer;
  String? _offersError;
  String? _instantBoardError;
  String? _scheduledNewBoardError;
  String _filter = 'Active';
  int _deliveryStep = 0;

  static const List<String> deliverySteps = [
    'Go to pickup',
    'Picked up',
    'Go to drop-off',
    'Delivered',
  ];

  bool get isLoading => _isLoading;
  bool get isLoadingOffers => _isLoadingOffers;
  bool get isLoadingInstantBoard => _isLoadingInstantBoard;
  bool get isLoadingScheduledNewBoard => _isLoadingScheduledNewBoard;
  List<OrderModel> get orders => _orders;
  List<JobOfferModel> get offers => _offers;
  List<JobsBoardJob> get instantActiveJobs => _instantActiveJobs;
  List<JobsBoardJob> get instantCompletedJobs => _instantCompletedJobs;
  List<JobsBoardJob> get scheduledNewJobs => _scheduledNewJobs;
  JobsBoardCounts get instantCounts => _instantCounts;
  JobsBoardCounts get scheduledCounts => _scheduledCounts;
  int get scheduledNewCount => _scheduledNewJobs.length;
  OrderModel? get currentOrder => _currentOrder;
  OrderModel? get newRequest => _newRequest;
  JobOfferModel? get currentOffer => _currentOffer;
  String? get offersError => _offersError;
  String? get instantBoardError => _instantBoardError;
  String? get scheduledNewBoardError => _scheduledNewBoardError;
  String get filter => _filter;
  int get deliveryStep => _deliveryStep;
  String get currentStepLabel =>
      deliverySteps[_deliveryStep.clamp(0, deliverySteps.length - 1)];

  List<OrderModel> get filteredOrders {
    if (_filter == 'All') return _orders;
    return _orders
        .where((o) => o.status.toLowerCase() == _filter.toLowerCase())
        .toList();
  }

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();
    _orders = await _orderService.getOrders();
    _isLoading = false;
    notifyListeners();
  }

  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }

  Future<void> loadJobOffers() async {
    _isLoadingOffers = true;
    _offersError = null;
    notifyListeners();

    try {
      final offers = await _orderService.getJobOffers();
      _offers = offers;
      _currentOffer = offers.isNotEmpty ? offers.first : null;
      _newRequest = _currentOffer == null
          ? null
          : OrderModel(
              id: _currentOffer!.id,
              pickupAddress: _currentOffer!.pickupSubtitle,
              dropoffAddress: _currentOffer!.dropoffSubtitle,
              customerName: _currentOffer!.customerName,
              vendorName: _currentOffer!.vendorName,
              status: _currentOffer!.status,
              price: _currentOffer!.driverEarnings,
              distance: _currentOffer!.distanceKm,
              createdAt: DateTime.now(),
              paymentStatus: _currentOffer!.paymentMethod,
            );
    } on ApiException catch (e) {
      _offersError = e.message;
      _offers = const [];
      _currentOffer = null;
      _newRequest = null;
    } catch (_) {
      _offersError = 'Failed to load job offers';
      _offers = const [];
      _currentOffer = null;
      _newRequest = null;
    } finally {
      _isLoadingOffers = false;
      notifyListeners();
    }
  }

  Future<void> loadInstantJobsBoard() async {
    _isLoadingInstantBoard = true;
    _instantBoardError = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _orderService.getActiveJob(),
        _orderService.getJobsHistory(
          type: 'all',
          includeCancelled: true,
        ),
      ]);

      final activeJob = results[0] as JobsBoardJob?;
      final history = results[1] as JobsHistoryData;

      _instantActiveJobs =
          activeJob == null ? const [] : <JobsBoardJob>[activeJob];
      _instantCompletedJobs = history.jobs;
      _instantCounts = JobsBoardCounts(
        active: activeJob == null ? 0 : 1,
        completed: history.count,
      );
    } on ApiException catch (e) {
      _instantBoardError = e.message;
      _instantActiveJobs = const [];
      _instantCompletedJobs = const [];
      _instantCounts = const JobsBoardCounts();
    } catch (_) {
      _instantBoardError = 'Failed to load orders';
      _instantActiveJobs = const [];
      _instantCompletedJobs = const [];
      _instantCounts = const JobsBoardCounts();
    } finally {
      _isLoadingInstantBoard = false;
      notifyListeners();
    }
  }

  Future<void> loadScheduledNewJobsBoard() async {
    _isLoadingScheduledNewBoard = true;
    _scheduledNewBoardError = null;
    notifyListeners();

    try {
      final data = await _orderService.getJobsBoard(
        type: 'scheduled',
        section: 'new',
      );
      _scheduledNewJobs = data.jobs;
      _scheduledCounts = data.counts;
    } on ApiException catch (e) {
      _scheduledNewBoardError = e.message;
      _scheduledNewJobs = const [];
      _scheduledCounts = const JobsBoardCounts();
    } catch (_) {
      _scheduledNewBoardError = 'Failed to load scheduled orders';
      _scheduledNewJobs = const [];
      _scheduledCounts = const JobsBoardCounts();
    } finally {
      _isLoadingScheduledNewBoard = false;
      notifyListeners();
    }
  }

  void removeScheduledNewJob(String jobId) {
    final id = jobId.trim();
    if (id.isEmpty) return;
    _scheduledNewJobs = _scheduledNewJobs
        .where((job) => job.id != id && job.displayOrderId != id)
        .toList(growable: false);
    notifyListeners();
  }

  Future<void> loadNewRequest() async {
    await loadJobOffers();
  }

  Future<void> loadOrderById(String id) async {
    _isLoading = true;
    notifyListeners();
    _currentOrder = await _orderService.getOrderById(id);
    _isLoading = false;
    notifyListeners();
  }

  void acceptOrder() {
    if (_newRequest != null) {
      _currentOrder = _newRequest!.copyWith(status: 'Accepted');
      _deliveryStep = 0;
      notifyListeners();
    }
  }

  void rejectOrder() {
    _newRequest = null;
    _currentOffer = null;
    notifyListeners();
  }

  void advanceDeliveryStep() {
    if (_deliveryStep < deliverySteps.length - 1) {
      _deliveryStep++;
      notifyListeners();
    }
  }

  void resetDelivery() {
    _deliveryStep = 0;
    _currentOrder = null;
    _currentOffer = null;
    _newRequest = null;
    notifyListeners();
  }
}

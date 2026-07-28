import 'package:flutter/foundation.dart';
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
  List<OrderModel> _orders = [];
  List<JobOfferModel> _offers = const [];
  OrderModel? _currentOrder;
  OrderModel? _newRequest;
  JobOfferModel? _currentOffer;
  String? _offersError;
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
  List<OrderModel> get orders => _orders;
  List<JobOfferModel> get offers => _offers;
  OrderModel? get currentOrder => _currentOrder;
  OrderModel? get newRequest => _newRequest;
  JobOfferModel? get currentOffer => _currentOffer;
  String? get offersError => _offersError;
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

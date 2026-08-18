import 'package:flutter/foundation.dart';
import 'package:yjeek_driver/features/orders/service/order_service.dart';
import 'package:yjeek_driver/features/scheduled_orders/model/scheduled_order_model.dart';
import 'package:yjeek_driver/features/scheduled_orders/service/scheduled_order_service.dart';
import 'package:yjeek_driver/services/api_service.dart';

class ScheduledOrderProvider extends ChangeNotifier {
  ScheduledOrderProvider({
    ScheduledOrderService? service,
    OrderService? orderService,
  })  : _service = service ?? ScheduledOrderService(),
        _orderService = orderService ?? OrderService();

  final ScheduledOrderService _service;
  final OrderService _orderService;

  bool _isLoading = false;
  bool _isStarting = false;
  List<ScheduledOrderModel> _scheduledOrders = [];
  ScheduledOrderModel? _selectedOrder;
  bool _ageVerified = false;
  String? _error;
  String? _startError;

  bool get isLoading => _isLoading;
  bool get isStarting => _isStarting;
  List<ScheduledOrderModel> get orders => _scheduledOrders;
  ScheduledOrderModel? get selectedOrder => _selectedOrder;
  bool get ageVerified => _ageVerified;
  String? get error => _error;
  String? get startError => _startError;

  Future<void> loadOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _scheduledOrders = await _service.getScheduledOrders();
    } on ApiException catch (e) {
      _scheduledOrders = [];
      _error = e.message;
    } catch (_) {
      _scheduledOrders = [];
      _error = 'Failed to load scheduled orders';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectOrder(ScheduledOrderModel order) {
    _selectedOrder = order;
    _startError = null;
    notifyListeners();
  }

  /// Accepts / confirms a scheduled job before entering the delivery flow.
  Future<bool> startOrder(ScheduledOrderModel order) async {
    _isStarting = true;
    _startError = null;
    notifyListeners();

    try {
      switch (order.section) {
        case 'new':
          await _orderService.acceptJob(order.jobId);
          break;
        case 'require_confirmation':
          await _orderService.confirmOrder(order.jobId);
          break;
        case 'on_track':
          break;
        default:
          break;
      }
      return true;
    } on ApiException catch (e) {
      _startError = e.message;
      return false;
    } catch (_) {
      _startError = 'Failed to start order';
      return false;
    } finally {
      _isStarting = false;
      notifyListeners();
    }
  }

  void confirmAgeVerification() {
    _ageVerified = true;
    notifyListeners();
  }

  void resetAgeVerification() {
    _ageVerified = false;
    notifyListeners();
  }
}

import 'package:yjeek_driver/core/constants/api_endpoints.dart';
import 'package:yjeek_driver/features/orders/model/job_offer_model.dart';
import 'package:yjeek_driver/features/orders/model/order_model.dart';
import 'package:yjeek_driver/services/api_service.dart';

class OrderService {
  OrderService({ApiService? apiService})
      : _api = apiService ?? ApiService.instance;

  final ApiService _api;

  Future<List<JobOfferModel>> getJobOffers() async {
    final response = await _api.get(ApiEndpoints.jobOffers);

    if (response['success'] != true) {
      final message = response['message']?.toString();
      throw ApiException(
        (message != null && message.trim().isNotEmpty)
            ? message.trim()
            : 'Failed to load job offers',
      );
    }

    try {
      return JobOfferModel.listFromResponse(response);
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  Future<List<OrderModel>> getOrders() async {
    await Future.delayed(const Duration(milliseconds: 800));
    final now = DateTime.now();
    return [
      OrderModel(
        id: '#ORD-1001',
        pickupAddress: 'Burger Palace, 45 Food Street',
        dropoffAddress: '12 Oak Avenue, Apt 3B',
        customerName: 'Sarah Ahmed',
        vendorName: 'Burger Palace',
        status: 'Active',
        price: 12.50,
        distance: 3.2,
        createdAt: now.subtract(const Duration(minutes: 15)),
        items: ['Classic Burger', 'Fries', 'Coke'],
        paymentStatus: 'Paid',
        deliveryNotes: 'Ring doorbell twice',
      ),
      OrderModel(
        id: '#ORD-1002',
        pickupAddress: 'Fresh Mart, 78 Market Road',
        dropoffAddress: '99 Pine Street',
        customerName: 'Mike Johnson',
        vendorName: 'Fresh Mart',
        status: 'Scheduled',
        price: 18.00,
        distance: 5.1,
        createdAt: now.subtract(const Duration(hours: 1)),
        items: ['Groceries Bag x2'],
        paymentStatus: 'Paid',
      ),
      OrderModel(
        id: '#ORD-1003',
        pickupAddress: 'Pizza Hub, 22 Center Plaza',
        dropoffAddress: '5 Elm Drive',
        customerName: 'Lisa Chen',
        vendorName: 'Pizza Hub',
        status: 'Completed',
        price: 9.75,
        distance: 2.4,
        createdAt: now.subtract(const Duration(hours: 3)),
        items: ['Margherita Pizza'],
        paymentStatus: 'Paid',
      ),
      OrderModel(
        id: '#ORD-1004',
        pickupAddress: 'Wine & Spirits, 10 Valley Road',
        dropoffAddress: '33 Hill View',
        customerName: 'Tom Wilson',
        vendorName: 'Wine & Spirits',
        status: 'Cancelled',
        price: 15.00,
        distance: 4.0,
        createdAt: now.subtract(const Duration(days: 1)),
        isRestricted: true,
        items: ['Red Wine Bottle'],
        paymentStatus: 'Refunded',
      ),
    ];
  }

  Future<OrderModel?> getOrderById(String id) async {
    final orders = await getOrders();
    try {
      return orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return orders.isNotEmpty ? orders.first : null;
    }
  }

  Future<OrderModel> getNewRequest() async {
    final offers = await getJobOffers();
    if (offers.isEmpty) {
      throw ApiException('No delivery offers available');
    }
    return _toOrderModel(offers.first);
  }

  OrderModel _toOrderModel(JobOfferModel offer) {
    return OrderModel(
      id: offer.id,
      pickupAddress: offer.pickupSubtitle,
      dropoffAddress: offer.dropoffSubtitle,
      customerName: offer.customerName,
      vendorName: offer.vendorName,
      status: offer.status,
      price: offer.driverEarnings,
      distance: offer.distanceKm,
      createdAt: DateTime.now(),
      paymentStatus: offer.paymentMethod,
    );
  }
}

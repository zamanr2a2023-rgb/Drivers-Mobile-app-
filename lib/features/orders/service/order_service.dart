import 'dart:typed_data';

import 'package:yjeek_driver/core/constants/api_endpoints.dart';
import 'package:yjeek_driver/features/orders/model/contact_attempts_model.dart';
import 'package:yjeek_driver/features/orders/model/job_board_model.dart';
import 'package:yjeek_driver/features/orders/model/job_complete_model.dart';
import 'package:yjeek_driver/features/orders/model/job_detail_model.dart';
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

  Future<JobsBoardData> getJobsBoard({
    required String type,
    required String section,
    int limit = 20,
  }) async {
    final response = await _api.get(
      ApiEndpoints.jobsBoard(type: type, section: section, limit: limit),
    );

    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to load orders board'),
      );
    }

    try {
      return JobsBoardData.fromJson(response);
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  Future<JobsHistoryData> getJobsHistory({
    String type = 'all',
    bool includeCancelled = true,
    int limit = 20,
  }) async {
    final response = await _api.get(
      ApiEndpoints.jobsHistory(
        type: type,
        includeCancelled: includeCancelled,
        limit: limit,
      ),
    );

    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to load jobs history'),
      );
    }

    try {
      return JobsHistoryData.fromJson(response);
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  /// Current active job for the driver, or `null` when none.
  Future<JobsBoardJob?> getActiveJob() async {
    final response = await _api.get(ApiEndpoints.jobActive);

    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to load active job'),
      );
    }

    final data = response['data'];
    if (data == null) return null;

    if (data is! Map) {
      throw ApiException('Invalid response from server');
    }

    try {
      return JobsBoardJob.fromJson(Map<String, dynamic>.from(data));
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  /// Full job detail for `GET /drivers/jobs/:jobId`.
  Future<JobDetailModel> getJobById(String jobId) async {
    final id = jobId.trim();
    if (id.isEmpty) {
      throw ApiException('Job id is required');
    }

    final response = await _api.get(ApiEndpoints.jobById(id));

    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to load job details'),
      );
    }

    final data = response['data'];
    if (data is! Map) {
      throw ApiException('Invalid response from server');
    }

    try {
      return JobDetailModel.fromJson(Map<String, dynamic>.from(data));
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  /// Marks the driver as arrived at the customer.
  Future<JobDetailModel> arriveAtCustomer(String jobId) async {
    final id = jobId.trim();
    if (id.isEmpty) {
      throw ApiException('Job id is required');
    }

    final response = await _api.post(ApiEndpoints.jobArriveCustomer(id));

    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to mark arrived at customer'),
      );
    }

    final data = response['data'];
    if (data is! Map) {
      throw ApiException('Invalid response from server');
    }

    try {
      return JobDetailModel.fromJson(Map<String, dynamic>.from(data));
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  /// Uploads a delivery proof photo and returns its public URL.
  Future<String> uploadDeliveryProof({
    required Uint8List bytes,
    String filename = 'delivery-proof.jpg',
  }) async {
    final response = await _api.postMultipart(
      ApiEndpoints.uploads(category: 'delivery-proofs'),
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
      contentType: 'image/jpeg',
    );

    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to upload delivery photo'),
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

  /// Completes the job with proof of delivery.
  Future<JobCompleteResult> completeJob({
    required String jobId,
    required String deliveryPhotoUrl,
    required bool cashCollected,
  }) async {
    final id = jobId.trim();
    if (id.isEmpty) {
      throw ApiException('Job id is required');
    }

    final photoUrl = deliveryPhotoUrl.trim();
    if (photoUrl.isEmpty) {
      throw ApiException('Delivery photo is required');
    }

    final response = await _api.post(
      ApiEndpoints.jobComplete(id),
      body: {
        'deliveryPhotoUrl': photoUrl,
        'cashCollected': cashCollected,
      },
    );

    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to complete delivery'),
      );
    }

    try {
      return JobCompleteResult.fromJson(response);
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  /// Logs a contact attempt (e.g. CALL) for unable-to-deliver rules.
  Future<ContactAttemptsResult> logContactAttempt({
    required String jobId,
    String type = 'CALL',
  }) async {
    final id = jobId.trim();
    if (id.isEmpty) {
      throw ApiException('Job id is required');
    }

    final response = await _api.post(
      ApiEndpoints.jobContactAttempts(id),
      body: {'type': type.trim().isEmpty ? 'CALL' : type.trim().toUpperCase()},
    );

    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to log contact attempt'),
      );
    }

    try {
      return ContactAttemptsResult.fromJson(response);
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  String _failureMessage(Map<String, dynamic> response, String fallback) {
    final message = response['message']?.toString();
    if (message != null && message.trim().isNotEmpty) return message.trim();

    final error = response['error'];
    if (error is Map) {
      final nested = error['message']?.toString();
      if (nested != null && nested.trim().isNotEmpty) return nested.trim();
    }

    return fallback;
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

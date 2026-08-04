import 'dart:typed_data';

import 'package:yjeek_driver/core/constants/api_endpoints.dart';
import 'package:yjeek_driver/features/orders/model/contact_attempts_model.dart';
import 'package:yjeek_driver/features/orders/model/job_board_model.dart';
import 'package:yjeek_driver/features/orders/model/job_complete_model.dart';
import 'package:yjeek_driver/features/orders/model/job_decline_model.dart';
import 'package:yjeek_driver/features/orders/model/job_detail_model.dart';
import 'package:yjeek_driver/features/orders/model/job_offer_model.dart';
import 'package:yjeek_driver/features/orders/model/job_report_model.dart';
import 'package:yjeek_driver/features/orders/model/job_report_wait_model.dart';
import 'package:yjeek_driver/features/orders/model/job_resend_code_model.dart';
import 'package:yjeek_driver/features/orders/model/job_confirm_return_model.dart';
import 'package:yjeek_driver/features/orders/model/job_return_age_restricted_model.dart';
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

  /// Marks the driver as arrived at the pickup / vendor.
  Future<JobDetailModel> arriveAtPickup(String jobId) async {
    final id = jobId.trim();
    if (id.isEmpty) {
      throw ApiException('Job id is required');
    }

    final response = await _api.post(ApiEndpoints.jobArrivePickup(id));

    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to mark arrived at pickup'),
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

  /// Confirms pickup with proof photo URL.
  Future<JobDetailModel> confirmPickup({
    required String jobId,
    required String pickupPhotoUrl,
  }) async {
    final id = jobId.trim();
    if (id.isEmpty) {
      throw ApiException('Job id is required');
    }

    final photoUrl = pickupPhotoUrl.trim();
    if (photoUrl.isEmpty) {
      throw ApiException('Pickup photo is required');
    }

    final response = await _api.post(
      ApiEndpoints.jobConfirmPickup(id),
      body: {'pickupPhotoUrl': photoUrl},
    );

    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to confirm pickup'),
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

  /// Confirms a scheduled job (double-confirm).
  Future<JobDetailModel> confirmOrder(String jobId) async {
    final id = jobId.trim();
    if (id.isEmpty) {
      throw ApiException('Job id is required');
    }

    final response = await _api.post(ApiEndpoints.jobConfirmOrder(id));

    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to confirm order'),
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

  /// Accepts a job offer.
  Future<JobDetailModel> acceptJob(String jobId) async {
    final id = jobId.trim();
    if (id.isEmpty) {
      throw ApiException('Job id is required');
    }

    final response = await _api.post(ApiEndpoints.jobAccept(id));

    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to accept job'),
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

  /// Declines a job offer.
  Future<JobDeclineResult> declineJob({
    required String jobId,
    required String reason,
    String note = '',
  }) async {
    final id = jobId.trim();
    if (id.isEmpty) {
      throw ApiException('Job id is required');
    }

    final reasonCode = reason.trim();
    if (reasonCode.isEmpty) {
      throw ApiException('Decline reason is required');
    }

    final response = await _api.post(
      ApiEndpoints.jobDecline(id),
      body: {
        'reason': reasonCode,
        'note': note.trim(),
      },
    );

    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to decline job'),
      );
    }

    try {
      return JobDeclineResult.fromJson(response);
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  /// Uploads a delivery proof photo and returns its public URL.
  Future<String> uploadDeliveryProof({
    required Uint8List bytes,
    String filename = 'delivery-proof.jpg',
  }) async {
    final uploaded = await _uploadFile(
      category: 'delivery-proofs',
      bytes: bytes,
      filename: filename,
      failureMessage: 'Failed to upload delivery photo',
    );
    return uploaded.url;
  }

  /// Uploads age-verification evidence and returns upload id (+ url).
  Future<({String id, String url})> uploadAgeVerificationProof({
    required Uint8List bytes,
    String filename = 'age-verification.jpg',
  }) async {
    return _uploadFile(
      category: 'documents',
      bytes: bytes,
      filename: filename,
      failureMessage: 'Failed to upload age verification photo',
    );
  }

  Future<({String id, String url})> _uploadFile({
    required String category,
    required Uint8List bytes,
    required String filename,
    required String failureMessage,
  }) async {
    final response = await _api.postMultipart(
      ApiEndpoints.uploads(category: category),
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
      contentType: 'image/jpeg',
    );

    if (response['success'] != true) {
      throw ApiException(_failureMessage(response, failureMessage));
    }

    final data = response['data'];
    if (data is! Map) {
      throw ApiException('Invalid response from server');
    }

    final map = Map<String, dynamic>.from(data);
    final url = map['url']?.toString().trim() ?? '';
    final id = map['id']?.toString().trim().isNotEmpty == true
        ? map['id'].toString().trim()
        : map['uploadId']?.toString().trim().isNotEmpty == true
            ? map['uploadId'].toString().trim()
            : map['secureUploadId']?.toString().trim().isNotEmpty == true
                ? map['secureUploadId'].toString().trim()
                : url;

    if (id.isEmpty || url.isEmpty) {
      throw ApiException('Invalid response from server');
    }
    return (id: id, url: url);
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

  /// Completes an age-restricted delivery (`/complete` + ageVerification).
  Future<JobCompleteResult> completeAgeRestrictedJob({
    required String jobId,
    required String deliveryPhotoUrl,
    required String secureUploadId,
    bool nameMatches = true,
    bool photoMatches = true,
    bool verified18OrOlder = true,
  }) async {
    final id = jobId.trim();
    if (id.isEmpty) {
      throw ApiException('Job id is required');
    }

    final photoUrl = deliveryPhotoUrl.trim();
    if (photoUrl.isEmpty) {
      throw ApiException('Delivery photo is required');
    }

    final uploadId = secureUploadId.trim();
    if (uploadId.isEmpty) {
      throw ApiException('Age verification upload is required');
    }

    final response = await _api.post(
      ApiEndpoints.jobComplete(id),
      body: {
        'deliveryPhotoUrl': photoUrl,
        'ageVerification': {
          'secureUploadId': uploadId,
          'nameMatches': nameMatches,
          'photoMatches': photoMatches,
          'verified18OrOlder': verified18OrOlder,
        },
      },
    );

    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to complete age-restricted delivery'),
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

  /// Reports a job issue to Yjeek Ops (e.g. VENDOR_NOT_READY, DAMAGED_AT_PICKUP).
  Future<JobReportResult> reportJobIssue({
    required String jobId,
    required String reason,
    required String note,
    String? damageType,
    String? photoUrl,
    bool? declineItems,
  }) async {
    final id = jobId.trim();
    if (id.isEmpty) {
      throw ApiException('Job id is required');
    }

    final reasonCode = reason.trim().isEmpty ? 'VENDOR_NOT_READY' : reason.trim();
    final noteText = note.trim().isEmpty ? 'Issue reported by driver' : note.trim();

    final body = <String, dynamic>{
      'reason': reasonCode,
      'note': noteText,
    };
    if (damageType != null && damageType.trim().isNotEmpty) {
      body['damageType'] = damageType.trim();
    }
    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      body['photoUrl'] = photoUrl.trim();
    }
    if (declineItems != null) {
      body['declineItems'] = declineItems;
    }

    final response = await _api.post(
      ApiEndpoints.jobReport(id),
      body: body,
    );

    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to report issue'),
      );
    }

    try {
      return JobReportResult.fromJson(response);
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  /// Reports wait at vendor so RPI excludes the wait time.
  Future<JobReportWaitResult> reportWaitAtVendor(String jobId) async {
    final id = jobId.trim();
    if (id.isEmpty) {
      throw ApiException('Job id is required');
    }

    final response = await _api.post(ApiEndpoints.jobReportWait(id));

    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to report wait'),
      );
    }

    try {
      return JobReportWaitResult.fromJson(response);
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  /// Marks the job as unable to deliver after required contact attempts.
  Future<JobReportResult> markUnableToDeliver({
    required String jobId,
    required String note,
  }) async {
    final id = jobId.trim();
    if (id.isEmpty) {
      throw ApiException('Job id is required');
    }

    final noteText = note.trim().isEmpty
        ? 'Customer not answering after 2 calls'
        : note.trim();

    final response = await _api.post(
      ApiEndpoints.jobUnableToDeliver(id),
      body: {'note': noteText},
    );

    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to mark unable to deliver'),
      );
    }

    try {
      return JobReportResult.fromJson(response);
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

  /// Starts an age-restricted return to vendor.
  Future<JobReturnAgeRestrictedResult> returnAgeRestricted({
    required String jobId,
    required String reason,
    required String returnPhotoUrl,
    required String note,
  }) {
    final id = jobId.trim();
    return _startJobReturn(
      endpoint: ApiEndpoints.jobReturnAgeRestricted(id),
      jobId: id,
      reason: reason,
      returnPhotoUrl: returnPhotoUrl,
      note: note,
      emptyNoteFallback: 'Customer could not provide valid CPR',
      failureMessage: 'Failed to start age-restricted return',
    );
  }

  /// Starts a secure-order return (can't verify OTP / recipient).
  Future<JobReturnAgeRestrictedResult> returnSecureOrder({
    required String jobId,
    required String reason,
    required String returnPhotoUrl,
    required String note,
  }) {
    final id = jobId.trim();
    return _startJobReturn(
      endpoint: ApiEndpoints.jobReturn(id),
      jobId: id,
      reason: reason,
      returnPhotoUrl: returnPhotoUrl,
      note: note,
      emptyNoteFallback: 'Recipient could not provide the one-time code',
      failureMessage: 'Failed to start secure order return',
    );
  }

  /// Confirms sealed-order handover back to the vendor.
  Future<JobConfirmReturnResult> confirmReturnHandover({
    required String jobId,
    required String vendorHandoverPhotoUrl,
  }) async {
    final id = jobId.trim();
    if (id.isEmpty) {
      throw ApiException('Job id is required');
    }

    final photoUrl = vendorHandoverPhotoUrl.trim();
    if (photoUrl.isEmpty) {
      throw ApiException('Vendor handover photo is required');
    }

    final response = await _api.post(
      ApiEndpoints.jobConfirmReturn(id),
      body: {'vendorHandoverPhotoUrl': photoUrl},
    );

    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to confirm return handover'),
      );
    }

    try {
      return JobConfirmReturnResult.fromJson(response);
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  Future<JobReturnAgeRestrictedResult> _startJobReturn({
    required String endpoint,
    required String jobId,
    required String reason,
    required String returnPhotoUrl,
    required String note,
    required String emptyNoteFallback,
    required String failureMessage,
  }) async {
    final id = jobId.trim();
    if (id.isEmpty) {
      throw ApiException('Job id is required');
    }

    final reasonCode = reason.trim();
    if (reasonCode.isEmpty) {
      throw ApiException('Return reason is required');
    }

    final photoUrl = returnPhotoUrl.trim();
    if (photoUrl.isEmpty) {
      throw ApiException('Return photo is required');
    }

    final response = await _api.post(
      endpoint,
      body: {
        'reason': reasonCode,
        'returnPhotoUrl': photoUrl,
        'note': note.trim().isEmpty ? emptyNoteFallback : note.trim(),
      },
    );

    if (response['success'] != true) {
      throw ApiException(_failureMessage(response, failureMessage));
    }

    try {
      return JobReturnAgeRestrictedResult.fromJson(response);
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  /// Resends the secure one-time delivery code to the customer.
  Future<JobResendCodeResult> resendSecureCode({
    required String jobId,
    required String code,
  }) async {
    final id = jobId.trim();
    if (id.isEmpty) {
      throw ApiException('Job id is required');
    }

    final secureCode = code.trim();
    if (secureCode.isEmpty) {
      throw ApiException('Code is required');
    }

    final response = await _api.post(
      ApiEndpoints.jobResendCode(id),
      body: {'code': secureCode},
    );

    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to resend code'),
      );
    }

    try {
      return JobResendCodeResult.fromJson(response);
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
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

import 'dart:typed_data';

import 'package:yjeek_driver/features/food_delivery/model/food_delivery_model.dart';
import 'package:yjeek_driver/features/orders/model/job_complete_model.dart';
import 'package:yjeek_driver/features/orders/model/job_detail_model.dart';
import 'package:yjeek_driver/features/orders/service/order_service.dart';
import 'package:yjeek_driver/services/api_service.dart';

class FoodDeliveryService {
  FoodDeliveryService({OrderService? orderService})
      : _orders = orderService ?? OrderService();

  final OrderService _orders;

  /// Loads the driver's current active instant/food job, or `null` when none.
  Future<FoodDeliveryModel?> getCurrentDelivery() async {
    final active = await _orders.getActiveJob();
    if (active == null) return null;

    final detail = await _orders.getJobById(active.id);
    return FoodDeliveryModel.fromJobDetail(detail);
  }

  /// Marks arrived at vendor when still in pickup phase.
  Future<FoodDeliveryModel> ensureArrivedAtPickup(String jobId) async {
    final detail = await _orders.getJobById(jobId);
    if (detail.isAtVendor || !detail.isPickupPhase) {
      return FoodDeliveryModel.fromJobDetail(detail);
    }

    final arrived = await _orders.arriveAtPickup(jobId);
    return FoodDeliveryModel.fromJobDetail(arrived);
  }

  /// Uploads pickup proof and confirms pickup.
  Future<FoodDeliveryModel> confirmPickup({
    required String jobId,
    required Uint8List pickupPhotoBytes,
  }) async {
    final photoUrl = await _orders.uploadDeliveryProof(
      bytes: pickupPhotoBytes,
      filename: 'pickup-proof.jpg',
    );
    final detail = await _orders.confirmPickup(
      jobId: jobId,
      pickupPhotoUrl: photoUrl,
    );
    return FoodDeliveryModel.fromJobDetail(detail);
  }

  /// Marks arrived at customer when in delivery phase.
  Future<FoodDeliveryModel> ensureArrivedAtCustomer(String jobId) async {
    final detail = await _orders.getJobById(jobId);
    if (detail.status.toUpperCase() == 'AT_CUSTOMER' ||
        !detail.canArriveAtCustomer) {
      return FoodDeliveryModel.fromJobDetail(detail);
    }

    final arrived = await _orders.arriveAtCustomer(jobId);
    return FoodDeliveryModel.fromJobDetail(arrived);
  }

  /// Uploads delivery proof and completes the job.
  Future<JobCompleteResult> completeDelivery({
    required String jobId,
    required Uint8List deliveryPhotoBytes,
    required bool cashCollected,
  }) async {
    final photoUrl = await _orders.uploadDeliveryProof(
      bytes: deliveryPhotoBytes,
      filename: 'delivery-proof.jpg',
    );
    return _orders.completeJob(
      jobId: jobId,
      deliveryPhotoUrl: photoUrl,
      cashCollected: cashCollected,
    );
  }
}

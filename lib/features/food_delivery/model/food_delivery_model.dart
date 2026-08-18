import 'package:yjeek_driver/features/orders/model/job_detail_model.dart';

class FoodDeliveryModel {
  const FoodDeliveryModel({
    required this.jobId,
    required this.id,
    required this.restaurantName,
    required this.customerName,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.items,
    required this.deliveryFee,
    required this.status,
    this.pickupInstructions,
    this.deliveryInstructions,
    this.requiresCashCollection = false,
    this.cashToCollectAmount = 0,
  });

  final String jobId;
  final String id;
  final String restaurantName;
  final String customerName;
  final String pickupAddress;
  final String dropoffAddress;
  final List<String> items;
  final double deliveryFee;
  final String status;
  final String? pickupInstructions;
  final String? deliveryInstructions;
  final bool requiresCashCollection;
  final double cashToCollectAmount;

  bool get isPickupPhase {
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
      case 'ASSIGNED':
      case 'DRIVER_ASSIGNED':
      case 'GOING_TO_VENDOR':
      case 'AT_RESTAURANT':
      case 'AT_VENDOR':
        return true;
      default:
        return false;
    }
  }

  bool get isDeliveryPhase {
    switch (status.toUpperCase()) {
      case 'PICKED_UP':
      case 'AT_CUSTOMER':
      case 'ON_THE_WAY':
      case 'IN_TRANSIT':
        return true;
      default:
        return false;
    }
  }

  factory FoodDeliveryModel.fromJobDetail(JobDetailModel job) {
    final order = job.order;
    final vendor = order.vendor;
    final address = order.address;

    final pickupParts = <String>[
      if (vendor.area.trim().isNotEmpty) vendor.area.trim(),
      if (vendor.city.trim().isNotEmpty) vendor.city.trim(),
    ];
    final pickupAddress = pickupParts.isEmpty
        ? (vendor.name.trim().isNotEmpty ? vendor.name.trim() : 'Pickup')
        : pickupParts.join(', ');

    final dropoffAddress = address.navigationAddress.trim().isNotEmpty
        ? address.navigationAddress.trim()
        : address.shortLabel;

    final items = order.items
        .map((item) {
          final qty = item.quantity > 0 ? '${item.quantity}× ' : '';
          return '$qty${item.name.trim()}';
        })
        .where((label) => label.trim().isNotEmpty)
        .toList(growable: false);

    return FoodDeliveryModel(
      jobId: job.id,
      id: order.displayOrderNumber.isNotEmpty
          ? order.displayOrderNumber
          : job.id,
      restaurantName:
          vendor.name.trim().isNotEmpty ? vendor.name.trim() : 'Restaurant',
      customerName: order.customer.displayName,
      pickupAddress: pickupAddress,
      dropoffAddress: dropoffAddress,
      items: items,
      deliveryFee: job.driverEarnings > 0
          ? job.driverEarnings
          : order.totalAmount,
      status: job.status,
      pickupInstructions: order.kitchenNote,
      deliveryInstructions: address.additionalDirections,
      requiresCashCollection: order.requiresCashCollection,
      cashToCollectAmount: order.cashToCollectAmount > 0
          ? order.cashToCollectAmount
          : order.totalAmount,
    );
  }

  FoodDeliveryModel copyWith({String? status}) {
    return FoodDeliveryModel(
      jobId: jobId,
      id: id,
      restaurantName: restaurantName,
      customerName: customerName,
      pickupAddress: pickupAddress,
      dropoffAddress: dropoffAddress,
      items: items,
      deliveryFee: deliveryFee,
      status: status ?? this.status,
      pickupInstructions: pickupInstructions,
      deliveryInstructions: deliveryInstructions,
      requiresCashCollection: requiresCashCollection,
      cashToCollectAmount: cashToCollectAmount,
    );
  }
}

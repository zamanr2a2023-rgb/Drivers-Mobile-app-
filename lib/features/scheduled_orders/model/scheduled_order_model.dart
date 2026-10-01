import 'package:yjeek_driver/features/orders/model/job_board_model.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_order.dart';

class ScheduledOrderModel {
  const ScheduledOrderModel({
    required this.id,
    required this.jobId,
    required this.title,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.scheduledDate,
    required this.status,
    required this.section,
    required this.boardJob,
    this.scheduledWindowLabel,
    this.isRestricted = false,
    this.customerName,
    this.price = 0.0,
  });

  final String id;
  final String jobId;
  final String title;
  final String pickupAddress;
  final String dropoffAddress;
  final DateTime scheduledDate;
  final String status;
  final String section;
  final JobsBoardJob boardJob;
  final String? scheduledWindowLabel;
  final bool isRestricted;
  final String? customerName;
  final double price;

  ScheduledDeliveryOrder toDeliveryOrder() {
    return ScheduledDeliveryOrder.fromBoardJob(boardJob);
  }

  factory ScheduledOrderModel.fromBoardJob(
    JobsBoardJob job, {
    required String section,
  }) {
    final restricted = _isRestrictedJob(job);
    final window = job.scheduledWindowLabel;
    final scheduledDate = job.expiresAt ?? DateTime.now();

    return ScheduledOrderModel(
      id: job.displayOrderId,
      jobId: job.id,
      title: job.displayRoute,
      pickupAddress: job.pickupArea.trim().isNotEmpty
          ? job.pickupArea.trim()
          : job.vendorName.trim(),
      dropoffAddress: job.dropoffAddress.trim().isNotEmpty
          ? job.dropoffAddress.trim()
          : job.dropoffArea.trim(),
      scheduledDate: scheduledDate,
      scheduledWindowLabel: window,
      status: job.displayStatusLabel,
      section: section,
      boardJob: job,
      isRestricted: restricted,
      customerName: null,
      price: job.driverEarnings,
    );
  }

  static bool _isRestrictedJob(JobsBoardJob job) {
    final haystack = [
      job.meta,
      job.routeLabel,
      job.statusLabel,
      job.vendorName,
    ].whereType<String>().join(' ').toLowerCase();

    return haystack.contains('18') ||
        haystack.contains('vape') ||
        haystack.contains('luxury') ||
        haystack.contains('restricted') ||
        haystack.contains('age');
  }
}

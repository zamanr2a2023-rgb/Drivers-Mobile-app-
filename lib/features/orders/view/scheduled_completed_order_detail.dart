// Local payload for Scheduled > Completed tab detail navigation only.

import 'package:yjeek_driver/features/orders/model/job_board_model.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_order.dart';

class ScheduledCompletedOrderDetail {
  const ScheduledCompletedOrderDetail({
    required this.orderId,
    required this.cardRouteLabel,
    required this.scheduledWindow,
    required this.deliveredAtLabel,
    required this.vendorName,
    required this.vendorAddress,
    required this.distance,
    required this.eta,
    required this.categoryBadge,
    required this.isVapeRestricted,
  });

  factory ScheduledCompletedOrderDetail.fromBoardJob(JobsBoardJob job) {
    final meta = job.completedMeta.trim();
    final deliveredAtLabel = job.isCancelled
        ? (meta.isNotEmpty ? meta : 'Cancelled')
        : (meta.isNotEmpty ? 'Delivered $meta' : 'Delivered');
    final eta = job.etaMin > 0 ? '~${job.etaMin} min' : '—';

    return ScheduledCompletedOrderDetail(
      orderId: job.displayOrderId,
      cardRouteLabel: job.displayRoute,
      scheduledWindow: job.scheduledWindowLabel,
      deliveredAtLabel: deliveredAtLabel,
      vendorName: job.vendorName,
      vendorAddress:
          job.pickupArea.trim().isNotEmpty ? job.pickupArea.trim() : '—',
      distance: '—',
      eta: eta,
      categoryBadge: 'Scheduled',
      isVapeRestricted: false,
    );
  }

  final String orderId;
  final String cardRouteLabel;
  final String scheduledWindow;
  final String deliveredAtLabel;
  final String vendorName;
  final String vendorAddress;
  final String distance;
  final String eta;
  final String categoryBadge;
  final bool isVapeRestricted;

  String get distanceEtaLabel => '$distance · $eta';

  /// Maps completed-tab detail data into the on-track delivery payload.
  ScheduledDeliveryOrder toDeliveryOrder() {
    return ScheduledDeliveryOrder(
      orderId: orderId,
      vendorName: vendorName,
      vendorAddress: vendorAddress,
      category: categoryBadge,
      customerName: 'Sara A.',
      customerPhone: '+973 3300 0000',
      customerAddress: 'Adliya · Bldg 23, Road 2825',
      scheduledWindow: scheduledWindow,
      pickupDeadlineNotice: '',
      distance: distance,
      eta: eta,
      items: const [
        ScheduledOrderItem(quantity: '1×', name: 'Age-restricted items'),
      ],
      isFragileHighValue: false,
      paymentType: ScheduledPaymentType.prepaid,
      earnings: '2.600',
      tip: '0.000',
      totalDeliveryTime: '20 min',
      deliveryDistance: '4.2 km',
      deliveryEta: '~18 min',
      orderTypeLabel: 'Scheduled · Vape',
      cardRouteLabel: cardRouteLabel,
      cardStatusLine: 'Age-restricted delivery',
    );
  }
}

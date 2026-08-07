// Local order payload for the Scheduled On Track delivery flow only.
import 'package:flutter/material.dart';
import 'package:yjeek_driver/features/orders/model/job_board_model.dart';

class ScheduledOrderItem {
  const ScheduledOrderItem({
    required this.quantity,
    required this.name,
  });

  final String quantity;
  final String name;
}

enum ScheduledPaymentType { prepaid, cash }

class ScheduledDeliveryOrder {
  factory ScheduledDeliveryOrder.fromBoardJob(JobsBoardJob job) {
    final earnings = job.driverEarnings > 0
        ? (job.driverEarnings == job.driverEarnings.roundToDouble()
            ? job.driverEarnings.toStringAsFixed(1)
            : job.driverEarnings.toStringAsFixed(3))
        : '0.000';
    final eta = job.etaMin > 0 ? '~${job.etaMin} min' : '';
    final statusLine = () {
      final message = job.statusMessage?.trim();
      if (message != null && message.isNotEmpty) return message;
      final meta = job.meta?.trim();
      if (meta != null && meta.isNotEmpty) return meta;
      return job.arrivingLabel;
    }();

    return ScheduledDeliveryOrder(
      orderId: job.id,
      vendorName: job.vendorName,
      vendorAddress:
          job.pickupArea.trim().isNotEmpty ? job.pickupArea.trim() : '—',
      category: 'Scheduled',
      customerName: 'Customer',
      customerPhone: '',
      customerAddress: job.dropoffAddress.trim().isNotEmpty
          ? job.dropoffAddress.trim()
          : (job.dropoffArea.trim().isNotEmpty ? job.dropoffArea.trim() : '—'),
      scheduledWindow: job.scheduledWindowLabel,
      pickupDeadlineNotice: statusLine,
      distance: '—',
      eta: eta.isNotEmpty ? eta : '—',
      items: const [],
      isFragileHighValue: false,
      paymentType: job.isCash
          ? ScheduledPaymentType.cash
          : ScheduledPaymentType.prepaid,
      cashAmount: job.isCash && job.totalAmount > 0
          ? 'BHD ${job.totalAmount.toStringAsFixed(3)}'
          : null,
      earnings: earnings,
      tip: '0.000',
      totalDeliveryTime: eta.isNotEmpty ? eta.replaceFirst('~', '') : '—',
      deliveryDistance: '—',
      deliveryEta: eta.isNotEmpty ? eta : '—',
      orderTypeLabel: 'Scheduled · Normal',
      cardRouteLabel: job.displayRoute,
      cardStatusLine: statusLine,
    );
  }

  const ScheduledDeliveryOrder({
    required this.orderId,
    required this.vendorName,
    required this.vendorAddress,
    required this.category,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.scheduledWindow,
    required this.pickupDeadlineNotice,
    required this.distance,
    required this.eta,
    required this.items,
    required this.isFragileHighValue,
    required this.paymentType,
    required this.earnings,
    required this.tip,
    required this.totalDeliveryTime,
    required this.deliveryDistance,
    required this.deliveryEta,
    required this.orderTypeLabel,
    required this.cardRouteLabel,
    required this.cardStatusLine,
    this.cashAmount,
  });

  final String orderId;
  final String vendorName;
  final String vendorAddress;
  final String category;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String scheduledWindow;
  final String pickupDeadlineNotice;
  final String distance;
  final String eta;
  final List<ScheduledOrderItem> items;
  final bool isFragileHighValue;
  final ScheduledPaymentType paymentType;
  final String? cashAmount;
  final String earnings;
  final String tip;
  final String totalDeliveryTime;
  final String deliveryDistance;
  final String deliveryEta;
  final String orderTypeLabel;
  final String cardRouteLabel;
  final String cardStatusLine;

  String get distanceEtaLabel => '$distance · $eta';
  String get deliveryDistanceEtaLabel => '$deliveryDistance · $deliveryEta';
  int get itemCount => items.length;

  String get paymentSummary {
    if (paymentType == ScheduledPaymentType.prepaid) {
      return 'Prepaid — Yjeek Wallet';
    }
    return 'Cash — ${cashAmount ?? ''}';
  }

  bool get isPrepaid => paymentType == ScheduledPaymentType.prepaid;
}

class ScheduledDeliveryScale {
  ScheduledDeliveryScale._();

  static const Size designSize = Size(390, 844);
  static Size screenSize = designSize;

  static void update(Size size) {
    if (size.width > 0 && size.height > 0) {
      screenSize = size;
    }
  }

  static double width(num value) =>
      value.toDouble() * (screenSize.width / designSize.width);

  static double height(num value) =>
      value.toDouble() * (screenSize.height / designSize.height);
}

extension ScheduledDeliveryUnits on num {
  double get sw => ScheduledDeliveryScale.width(this);

  double get sh => ScheduledDeliveryScale.height(this);

  double get ssp => ScheduledDeliveryScale.width(this);
}

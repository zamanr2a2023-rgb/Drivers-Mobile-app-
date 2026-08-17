// Local order payload for the Scheduled On Track delivery flow only.
import 'package:flutter/material.dart';
import 'package:yjeek_driver/features/orders/model/job_board_model.dart';
import 'package:yjeek_driver/features/orders/model/job_complete_model.dart';
import 'package:yjeek_driver/features/orders/model/job_detail_model.dart';

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
  int get itemCount {
    if (items.isEmpty) return 0;
    var total = 0;
    for (final item in items) {
      final qty = int.tryParse(item.quantity.replaceAll(RegExp(r'[^0-9]'), ''));
      total += qty != null && qty > 0 ? qty : 1;
    }
    return total;
  }

  String get paymentSummary {
    if (paymentType == ScheduledPaymentType.prepaid) {
      return 'Prepaid — Yjeek Wallet';
    }
    return 'Cash — ${cashAmount ?? ''}';
  }

  bool get isPrepaid => paymentType == ScheduledPaymentType.prepaid;

  String get liveJobId {
    final id = orderId.trim();
    return id;
  }

  bool get hasLiveJobId => liveJobId.isNotEmpty && !liveJobId.startsWith('#');

  ScheduledDeliveryOrder copyWith({
    String? orderId,
    String? vendorName,
    String? vendorAddress,
    String? category,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? scheduledWindow,
    String? pickupDeadlineNotice,
    String? distance,
    String? eta,
    List<ScheduledOrderItem>? items,
    bool? isFragileHighValue,
    ScheduledPaymentType? paymentType,
    String? cashAmount,
    bool clearCashAmount = false,
    String? earnings,
    String? tip,
    String? totalDeliveryTime,
    String? deliveryDistance,
    String? deliveryEta,
    String? orderTypeLabel,
    String? cardRouteLabel,
    String? cardStatusLine,
  }) {
    return ScheduledDeliveryOrder(
      orderId: orderId ?? this.orderId,
      vendorName: vendorName ?? this.vendorName,
      vendorAddress: vendorAddress ?? this.vendorAddress,
      category: category ?? this.category,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      scheduledWindow: scheduledWindow ?? this.scheduledWindow,
      pickupDeadlineNotice: pickupDeadlineNotice ?? this.pickupDeadlineNotice,
      distance: distance ?? this.distance,
      eta: eta ?? this.eta,
      items: items ?? this.items,
      isFragileHighValue: isFragileHighValue ?? this.isFragileHighValue,
      paymentType: paymentType ?? this.paymentType,
      cashAmount: clearCashAmount ? cashAmount : (cashAmount ?? this.cashAmount),
      earnings: earnings ?? this.earnings,
      tip: tip ?? this.tip,
      totalDeliveryTime: totalDeliveryTime ?? this.totalDeliveryTime,
      deliveryDistance: deliveryDistance ?? this.deliveryDistance,
      deliveryEta: deliveryEta ?? this.deliveryEta,
      orderTypeLabel: orderTypeLabel ?? this.orderTypeLabel,
      cardRouteLabel: cardRouteLabel ?? this.cardRouteLabel,
      cardStatusLine: cardStatusLine ?? this.cardStatusLine,
    );
  }

  ScheduledDeliveryOrder mergedWithJob(JobDetailModel job) {
    final order = job.order;
    final mappedItems = order.items
        .map(
          (item) => ScheduledOrderItem(
            quantity: '${item.quantity}×',
            name: item.name.trim().isNotEmpty ? item.name.trim() : 'Item',
          ),
        )
        .toList(growable: false);
    final vendorArea = order.vendor.area.trim().isNotEmpty
        ? order.vendor.area.trim()
        : order.vendor.city.trim();
    final earnings = job.driverEarnings > 0
        ? job.driverEarnings.toStringAsFixed(3)
        : this.earnings;
    final tip = order.tipAmount > 0
        ? order.tipAmount.toStringAsFixed(3)
        : this.tip;
    final distance = job.distanceKm > 0
        ? '${job.distanceKm.toStringAsFixed(1)} km'
        : this.distance;
    final eta = job.estimatedDurationMin > 0
        ? '~${job.estimatedDurationMin} min'
        : this.eta;

    return copyWith(
      orderId: job.id.trim().isNotEmpty ? job.id.trim() : orderId,
      vendorName: order.vendor.name.trim().isNotEmpty
          ? order.vendor.name.trim()
          : vendorName,
      vendorAddress: vendorArea.isNotEmpty ? vendorArea : vendorAddress,
      customerName: order.customer.displayName,
      customerPhone: order.customer.displayPhone,
      customerAddress: order.address.shortLabel,
      scheduledWindow: order.windowLabel != '—'
          ? order.windowLabel
          : scheduledWindow,
      distance: distance,
      eta: eta,
      items: mappedItems.isNotEmpty ? mappedItems : items,
      paymentType: order.requiresCashCollection
          ? ScheduledPaymentType.cash
          : ScheduledPaymentType.prepaid,
      cashAmount: order.requiresCashCollection
          ? 'BHD ${order.cashToCollectAmount > 0 ? order.cashToCollectAmount.toStringAsFixed(3) : order.totalAmount.toStringAsFixed(3)}'
          : null,
      clearCashAmount: !order.requiresCashCollection,
      earnings: earnings,
      tip: tip,
      totalDeliveryTime: job.estimatedDurationMin > 0
          ? '${job.estimatedDurationMin} min'
          : totalDeliveryTime,
      deliveryDistance: distance,
      deliveryEta: eta,
      orderTypeLabel: order.fulfillmentType.trim().isNotEmpty
          ? order.fulfillmentType.replaceAll('_', ' · ')
          : orderTypeLabel,
    );
  }

  ScheduledDeliveryOrder mergedWithSummary(JobCompleteSummary summary) {
    return copyWith(
      earnings: summary.earningsAddedLabel,
      tip: summary.tipAmountLabel,
      deliveryDistance: summary.distanceLabel,
      totalDeliveryTime: summary.durationLabel,
      orderTypeLabel: summary.deliveryTypeLabel != '—'
          ? summary.deliveryTypeLabel
          : orderTypeLabel,
    );
  }
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

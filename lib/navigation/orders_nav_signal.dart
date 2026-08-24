import 'package:flutter/material.dart';

/// Local signal so Dashboard can open Orders → Scheduled
/// while keeping BottomNavigation on the Orders tab.
/// Does not use / change app-wide state management.
class OrdersNavSignal {
  OrdersNavSignal._();

  /// 0 = Instant, 1 = Scheduled. Null = no pending request.
  static final ValueNotifier<int?> pendingSegment = ValueNotifier<int?>(null);

  static void openScheduled() => pendingSegment.value = 1;

  static void openScheduledOnTrack() {
    pendingSegment.value = 1;
    pendingScheduledFilter.value = 2;
  }

  static void openInstant() => pendingSegment.value = 0;

  /// Resets Orders tab embedded deliver flow (`_showDeliverToCustomer`).
  static final ValueNotifier<int> deliverFlowCloseTick = ValueNotifier(0);

  static void closeEmbeddedDeliverFlow() {
    deliverFlowCloseTick.value++;
  }

  static void clear() {
    pendingSegment.value = null;
    pendingScheduledFilter.value = null;
  }

  /// When opening Scheduled tab, optionally select filter: 0 New, 2 On track, etc.
  static final ValueNotifier<int?> pendingScheduledFilter =
      ValueNotifier<int?>(null);
}

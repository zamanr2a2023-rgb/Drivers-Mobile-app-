import 'package:flutter/material.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';
import 'package:yjeek_driver/navigation/orders_nav_signal.dart';

/// Resets job state and navigates to a success screen above the root route.
Future<void> navigateToJobSuccessScreen(
  BuildContext context, {
  required OrderProvider provider,
  required String routeName,
  Object? arguments,
  bool refreshInstantBoard = false,
  bool refreshScheduledBoards = false,
}) async {
  await provider.finalizeAfterJobComplete(
    refreshInstantBoard: refreshInstantBoard,
    refreshScheduledBoards: refreshScheduledBoards,
  );
  OrdersNavSignal.closeEmbeddedDeliverFlow();
  if (!context.mounted) return;

  Navigator.pushNamedAndRemoveUntil(
    context,
    routeName,
    (route) => route.isFirst,
    arguments: arguments,
  );
}

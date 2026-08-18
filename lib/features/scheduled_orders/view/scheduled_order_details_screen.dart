import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/constants/app_colors.dart';
import 'package:yjeek_driver/core/constants/app_sizes.dart';
import 'package:yjeek_driver/core/utils/app_helpers.dart';
import 'package:yjeek_driver/core/utils/date_formatter.dart';
import 'package:yjeek_driver/core/widgets/custom_app_bar.dart';
import 'package:yjeek_driver/core/widgets/custom_button.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';
import 'package:yjeek_driver/features/scheduled_orders/provider/scheduled_order_provider.dart';
import 'package:yjeek_driver/routes/route_names.dart';

class ScheduledOrderDetailsScreen extends StatelessWidget {
  const ScheduledOrderDetailsScreen({super.key});

  String _sectionActionLabel(String section) {
    switch (section) {
      case 'new':
        return 'Accept & Start';
      case 'require_confirmation':
        return 'Confirm & Start';
      case 'on_track':
        return 'Continue Delivery';
      default:
        return 'Start Order';
    }
  }

  Future<void> _startOrder(BuildContext context) async {
    final provider = context.read<ScheduledOrderProvider>();
    final order = provider.selectedOrder;
    if (order == null) return;

    final ok = await provider.startOrder(order);
    if (!context.mounted) return;

    if (!ok) {
      AppHelpers.showSnackBar(
        context,
        provider.startError ?? 'Failed to start order',
      );
      return;
    }

    // Keep main Orders tab in sync when driver enters the live flow.
    await context.read<OrderProvider>().loadJobDetail(order.jobId);

    if (!context.mounted) return;

    AppHelpers.showSnackBar(context, 'Order started');
    Navigator.pushNamed(
      context,
      RouteNames.goToVendorScheduled,
      arguments: order.toDeliveryOrder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduledOrderProvider>();
    final order = provider.selectedOrder;

    if (order == null) {
      return const Scaffold(body: Center(child: Text('No order selected')));
    }

    final windowLabel = order.scheduledWindowLabel?.trim();
    final scheduledLabel = windowLabel != null && windowLabel.isNotEmpty
        ? windowLabel
        : DateFormatter.formatDateTime(order.scheduledDate);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Scheduled Order'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.id,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: AppSizes.paddingMd),
              _DetailRow(Icons.calendar_today, 'Scheduled', scheduledLabel),
              _DetailRow(Icons.store, 'Pickup', order.pickupAddress),
              _DetailRow(Icons.location_on, 'Drop-off', order.dropoffAddress),
              if (order.customerName != null)
                _DetailRow(Icons.person, 'Customer', order.customerName!),
              _DetailRow(
                Icons.attach_money,
                'Earning',
                AppHelpers.formatCurrency(order.price),
              ),
              _DetailRow(Icons.label_outline, 'Status', order.status),
              const Spacer(),
              CustomButton(
                title: provider.isStarting
                    ? 'Starting...'
                    : _sectionActionLabel(order.section),
                onPressed: provider.isStarting ? null : () => _startOrder(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSm),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
        subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
    );
  }
}

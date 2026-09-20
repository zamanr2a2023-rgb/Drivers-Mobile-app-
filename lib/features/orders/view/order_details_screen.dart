import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/constants/app_colors.dart';
import 'package:yjeek_driver/core/constants/app_sizes.dart';
import 'package:yjeek_driver/core/utils/app_helpers.dart';
import 'package:yjeek_driver/core/utils/date_formatter.dart';
import 'package:yjeek_driver/core/widgets/app_loader.dart';
import 'package:yjeek_driver/core/widgets/custom_app_bar.dart';
import 'package:yjeek_driver/core/widgets/status_badge.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key, this.orderId});

  final String? orderId;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrderById(widget.orderId ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final order = provider.currentOrder;

    Widget body;
    if (provider.isLoading) {
      body = const AppLoader();
    } else if (order == null) {
      body = const Center(child: Text('No order details'));
    } else {
      body = SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingMd),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(order.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          StatusBadge(status: order.status),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingMd),
                  _InfoTile(label: 'Customer', value: order.customerName, icon: Icons.person_outline),
                  _InfoTile(label: 'Vendor', value: order.vendorName, icon: Icons.store_outlined),
                  _InfoTile(label: 'Pickup', value: order.pickupAddress, icon: Icons.store),
                  _InfoTile(label: 'Drop-off', value: order.dropoffAddress, icon: Icons.location_on),
                  _InfoTile(label: 'Distance', value: AppHelpers.formatDistance(order.distance), icon: Icons.route),
                  _InfoTile(label: 'Payment', value: order.paymentStatus, icon: Icons.payment),
                  if (order.tipAmount > 0)
                    _InfoTile(
                      label: 'Tip',
                      value: 'BHD ${order.tipAmount.toStringAsFixed(3)}',
                      icon: Icons.volunteer_activism_outlined,
                    ),
                  _InfoTile(label: 'Created', value: DateFormatter.formatDateTime(order.createdAt), icon: Icons.access_time),
                  if (order.deliveryNotes != null)
                    _InfoTile(label: 'Notes', value: order.deliveryNotes!, icon: Icons.note_outlined),
                  const SizedBox(height: AppSizes.paddingMd),
                  const Text('Items', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: AppSizes.paddingSm),
                  ...order.items.map((item) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.fastfood_outlined, color: AppColors.primary),
                          title: Text(item),
                        ),
                      )),
                  const SizedBox(height: AppSizes.paddingMd),
                  Center(
                    child: Text(
                      AppHelpers.formatCurrency(order.price),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Order Details'),
      body: body,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSm),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
        subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
    );
  }
}

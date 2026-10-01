import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/constants/app_colors.dart';
import 'package:yjeek_driver/core/constants/app_sizes.dart';
import 'package:yjeek_driver/core/utils/app_helpers.dart';
import 'package:yjeek_driver/core/utils/date_formatter.dart';
import 'package:yjeek_driver/core/widgets/app_loader.dart';
import 'package:yjeek_driver/core/widgets/custom_app_bar.dart';
import 'package:yjeek_driver/core/widgets/empty_state_widget.dart';
import 'package:yjeek_driver/core/widgets/status_badge.dart';
import 'package:yjeek_driver/features/scheduled_orders/model/scheduled_order_model.dart';
import 'package:yjeek_driver/features/scheduled_orders/provider/scheduled_order_provider.dart';
import 'package:yjeek_driver/routes/route_names.dart';

class ScheduledOrdersScreen extends StatefulWidget {
  const ScheduledOrdersScreen({super.key});

  @override
  State<ScheduledOrdersScreen> createState() => _ScheduledOrdersScreenState();
}

class _ScheduledOrdersScreenState extends State<ScheduledOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduledOrderProvider>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduledOrderProvider>();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Scheduled Orders',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.isLoading ? null : () => provider.loadOrders(),
          ),
        ],
      ),
      body: provider.isLoading
          ? const AppLoader()
          : provider.error != null && provider.orders.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.error_outline,
                  title: provider.error!,
                  subtitle: 'Pull to refresh or tap the refresh button.',
                )
              : provider.orders.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.calendar_month_outlined,
                      title: 'No scheduled orders',
                      subtitle: 'New scheduled jobs will appear here.',
                    )
                  : RefreshIndicator(
                      onRefresh: provider.loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSizes.paddingMd),
                        itemCount: provider.orders.length,
                        itemBuilder: (context, index) {
                          final order = provider.orders[index];
                          return _ScheduledOrderCard(
                            order: order,
                            onTap: () {
                              provider.selectOrder(order);
                              if (order.isRestricted) {
                                Navigator.pushNamed(
                                  context,
                                  RouteNames.restrictedOrder,
                                );
                              } else {
                                Navigator.pushNamed(
                                  context,
                                  RouteNames.scheduledOrderDetails,
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}

class _ScheduledOrderCard extends StatelessWidget {
  const _ScheduledOrderCard({required this.order, required this.onTap});
  final ScheduledOrderModel order;
  final VoidCallback onTap;

  String get _sectionLabel {
    switch (order.section) {
      case 'new':
        return 'New';
      case 'require_confirmation':
        return 'Confirm';
      case 'on_track':
        return 'On track';
      default:
        return order.section;
    }
  }

  @override
  Widget build(BuildContext context) {
    final windowLabel = order.scheduledWindowLabel?.trim();
    final dateLabel = windowLabel != null && windowLabel.isNotEmpty
        ? windowLabel
        : DateFormatter.formatDateTime(order.scheduledDate);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.id,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _sectionLabel,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (order.isRestricted)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '18+',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      StatusBadge(status: order.status),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                dateLabel,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${order.pickupAddress} → ${order.dropoffAddress}',
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                AppHelpers.formatCurrency(order.price),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

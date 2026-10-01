import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/constants/app_colors.dart';
import 'package:yjeek_driver/core/constants/app_sizes.dart';
import 'package:yjeek_driver/core/utils/app_helpers.dart';
import 'package:yjeek_driver/core/widgets/app_loader.dart';
import 'package:yjeek_driver/core/widgets/custom_app_bar.dart';
import 'package:yjeek_driver/core/widgets/custom_button.dart';
import 'package:yjeek_driver/core/widgets/empty_state_widget.dart';
import 'package:yjeek_driver/features/food_delivery/provider/food_delivery_provider.dart';
import 'package:yjeek_driver/routes/route_names.dart';

class FoodDeliveryScreen extends StatefulWidget {
  const FoodDeliveryScreen({super.key});

  @override
  State<FoodDeliveryScreen> createState() => _FoodDeliveryScreenState();
}

class _FoodDeliveryScreenState extends State<FoodDeliveryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodDeliveryProvider>().loadDelivery();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FoodDeliveryProvider>();
    final delivery = provider.delivery;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Food Delivery',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                provider.isLoading ? null : () => provider.loadDelivery(),
          ),
        ],
      ),
      body: provider.isLoading
          ? const AppLoader()
          : delivery == null
              ? EmptyStateWidget(
                  icon: Icons.delivery_dining_outlined,
                  title: provider.error ?? 'No active food delivery',
                  subtitle: 'Go online and accept an instant food order first.',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.paddingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LocationCard(
                        title: 'Restaurant Pickup',
                        name: delivery.restaurantName,
                        address: delivery.pickupAddress,
                        icon: Icons.restaurant,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSizes.paddingMd),
                      _LocationCard(
                        title: 'Customer Drop-off',
                        name: delivery.customerName,
                        address: delivery.dropoffAddress,
                        icon: Icons.home_outlined,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: AppSizes.paddingMd),
                      const Text(
                        'Items',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingSm),
                      if (delivery.items.isEmpty)
                        const Card(
                          child: ListTile(
                            title: Text('No item details from server'),
                          ),
                        )
                      else
                        ...delivery.items.map(
                          (item) => Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.fastfood_outlined,
                                color: AppColors.primary,
                              ),
                              title: Text(item),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSizes.paddingMd),
                      Center(
                        child: Text(
                          'Delivery Fee: ${AppHelpers.formatCurrency(delivery.deliveryFee)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      if (delivery.requiresCashCollection) ...[
                        const SizedBox(height: AppSizes.paddingSm),
                        Center(
                          child: Text(
                            'Collect cash: BHD ${delivery.cashToCollectAmount.toStringAsFixed(3)}',
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSizes.paddingLg),
                      CustomButton(
                        title: delivery.isDeliveryPhase
                            ? 'Drop-off Details'
                            : 'Pickup Details',
                        onPressed: () {
                          final route = delivery.isDeliveryPhase
                              ? RouteNames.dropoffDetails
                              : RouteNames.pickupDetails;
                          Navigator.pushNamed(context, route);
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.title,
    required this.name,
    required this.address,
    required this.icon,
    required this.color,
  });

  final String title;
  final String name;
  final String address;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: AppSizes.paddingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/constants/app_colors.dart';
import 'package:yjeek_driver/core/constants/app_sizes.dart';
import 'package:yjeek_driver/core/widgets/custom_app_bar.dart';
import 'package:yjeek_driver/core/widgets/custom_button.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';
import 'package:yjeek_driver/routes/route_names.dart';

class AcceptOrderScreen extends StatelessWidget {
  const AcceptOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final order = provider.currentOrder;
    final steps = OrderProvider.deliverySteps;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Active Delivery'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (order != null) ...[
                Text(order.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text('${order.vendorName} → ${order.customerName}', style: const TextStyle(color: AppColors.textLight)),
              ],
              const SizedBox(height: AppSizes.paddingLg),
              const Text('Delivery Steps', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: AppSizes.paddingMd),
              Expanded(
                child: ListView.builder(
                  itemCount: steps.length,
                  itemBuilder: (context, index) {
                    final isCompleted = index < provider.deliveryStep;
                    final isCurrent = index == provider.deliveryStep;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Column(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: isCompleted
                                  ? AppColors.success
                                  : isCurrent
                                      ? AppColors.primary
                                      : AppColors.cardBorder,
                              child: Icon(
                                isCompleted ? Icons.check : Icons.circle,
                                size: isCompleted ? 18 : 10,
                                color: isCompleted || isCurrent ? AppColors.white : AppColors.textLight,
                              ),
                            ),
                            if (index < steps.length - 1)
                              Container(width: 2, height: 40, color: isCompleted ? AppColors.success : AppColors.cardBorder),
                          ],
                        ),
                        const SizedBox(width: AppSizes.paddingMd),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 24),
                            child: Text(
                              steps[index],
                              style: TextStyle(
                                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                                color: isCurrent ? AppColors.textDark : AppColors.textLight,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (provider.deliveryStep < steps.length - 1)
                CustomButton(
                  title: 'Update: ${steps[provider.deliveryStep]}',
                  onPressed: () => provider.advanceDeliveryStep(),
                )
              else
                CustomButton(
                  title: 'Complete Delivery',
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      RouteNames.orderCompleted,
                      arguments: order?.price ?? 0.0,
                    );
                  },
                ),
              const SizedBox(height: AppSizes.paddingSm),
              CustomButton(
                title: 'Open Dispatch Chat',
                outlined: true,
                onPressed: () => Navigator.pushNamed(context, RouteNames.dispatchChat),
              ),
              const SizedBox(height: AppSizes.paddingSm),
              CustomButton(
                title: 'Food Delivery Flow',
                outlined: true,
                onPressed: () => Navigator.pushNamed(context, RouteNames.foodDelivery),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


//jjkkjjkjkljk
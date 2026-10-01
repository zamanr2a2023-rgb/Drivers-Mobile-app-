import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/constants/app_colors.dart';
import 'package:yjeek_driver/core/constants/app_sizes.dart';
import 'package:yjeek_driver/core/utils/app_helpers.dart';
import 'package:yjeek_driver/core/widgets/custom_app_bar.dart';
import 'package:yjeek_driver/core/widgets/custom_button.dart';
import 'package:yjeek_driver/features/food_delivery/provider/food_delivery_provider.dart';
import 'package:yjeek_driver/routes/route_names.dart';

class PickupDetailsScreen extends StatefulWidget {
  const PickupDetailsScreen({super.key});

  @override
  State<PickupDetailsScreen> createState() => _PickupDetailsScreenState();
}

class _PickupDetailsScreenState extends State<PickupDetailsScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _pickupPhotoBytes;
  bool _hasPickupPhoto = false;

  Future<void> _selectPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _pickupPhotoBytes = bytes;
        _hasPickupPhoto = true;
      });
    } catch (_) {
      if (!mounted) return;
      AppHelpers.showSnackBar(context, 'Photo selection failed');
    }
  }

  Future<void> _confirmPickup() async {
    final bytes = _pickupPhotoBytes;
    if (!_hasPickupPhoto || bytes == null) {
      AppHelpers.showSnackBar(context, 'Please add a pickup photo first');
      return;
    }

    final provider = context.read<FoodDeliveryProvider>();
    if (provider.isSubmitting) return;

    final ok = await provider.confirmPickup(bytes);
    if (!mounted) return;

    if (ok) {
      AppHelpers.showSnackBar(context, 'Pickup confirmed!');
      Navigator.pushNamed(context, RouteNames.dropoffDetails);
      return;
    }

    AppHelpers.showSnackBar(
      context,
      provider.submitError ?? 'Failed to confirm pickup',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FoodDeliveryProvider>();
    final delivery = provider.delivery;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Pickup Details'),
      body: delivery == null
          ? const Center(child: Text('No delivery loaded'))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.restaurant,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          delivery.restaurantName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(delivery.pickupAddress),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingMd),
                    const Text(
                      'Pickup Instructions',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSizes.paddingSm),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.paddingMd),
                        child: Text(
                          delivery.pickupInstructions ??
                              'No special instructions',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingMd),
                    const Text(
                      'Items to Collect',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSizes.paddingSm),
                    Expanded(
                      child: delivery.items.isEmpty
                          ? const Card(
                              child: ListTile(
                                title: Text('No item details'),
                              ),
                            )
                          : ListView.builder(
                              itemCount: delivery.items.length,
                              itemBuilder: (_, i) => Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.12),
                                    child: Text(
                                      '${i + 1}',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  title: Text(delivery.items[i]),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: AppSizes.paddingSm),
                    OutlinedButton.icon(
                      onPressed: provider.isSubmitting ? null : _selectPhoto,
                      icon: Icon(
                        _hasPickupPhoto ? Icons.check_circle : Icons.camera_alt,
                        color: _hasPickupPhoto
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                      label: Text(
                        _hasPickupPhoto
                            ? 'Pickup photo added'
                            : 'Add pickup photo',
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSm),
                    CustomButton(
                      title: provider.isSubmitting
                          ? 'Confirming...'
                          : 'Confirm Pickup',
                      onPressed: provider.isSubmitting || !_hasPickupPhoto
                          ? null
                          : _confirmPickup,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

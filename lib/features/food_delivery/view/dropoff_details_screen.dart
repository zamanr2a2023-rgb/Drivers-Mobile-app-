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

class DropoffDetailsScreen extends StatefulWidget {
  const DropoffDetailsScreen({super.key});

  @override
  State<DropoffDetailsScreen> createState() => _DropoffDetailsScreenState();
}

class _DropoffDetailsScreenState extends State<DropoffDetailsScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _deliveryPhotoBytes;
  bool _hasDeliveryPhoto = false;
  bool _cashCollected = false;

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
        _deliveryPhotoBytes = bytes;
        _hasDeliveryPhoto = true;
      });
    } catch (_) {
      if (!mounted) return;
      AppHelpers.showSnackBar(context, 'Photo selection failed');
    }
  }

  Future<void> _confirmDelivery() async {
    final bytes = _deliveryPhotoBytes;
    if (!_hasDeliveryPhoto || bytes == null) {
      AppHelpers.showSnackBar(context, 'Please add a delivery photo first');
      return;
    }

    final provider = context.read<FoodDeliveryProvider>();
    final delivery = provider.delivery;
    if (delivery == null) return;

    if (delivery.requiresCashCollection && !_cashCollected) {
      AppHelpers.showSnackBar(context, 'Please confirm cash was collected');
      return;
    }

    if (provider.isSubmitting) return;

    final ok = await provider.confirmDelivery(
      deliveryPhotoBytes: bytes,
      cashCollected: delivery.requiresCashCollection && _cashCollected,
    );
    if (!mounted) return;

    if (ok) {
      Navigator.pushReplacementNamed(context, RouteNames.deliverySuccess);
      return;
    }

    AppHelpers.showSnackBar(
      context,
      provider.submitError ?? 'Failed to complete delivery',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FoodDeliveryProvider>();
    final delivery = provider.delivery;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Drop-off Details'),
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
                          Icons.person_outline,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          delivery.customerName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(delivery.dropoffAddress),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingMd),
                    const Text(
                      'Delivery Instructions',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSizes.paddingSm),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.paddingMd),
                        child: Text(
                          delivery.deliveryInstructions ??
                              'No special instructions',
                        ),
                      ),
                    ),
                    if (delivery.requiresCashCollection) ...[
                      const SizedBox(height: AppSizes.paddingMd),
                      CheckboxListTile(
                        value: _cashCollected,
                        activeColor: AppColors.primary,
                        title: Text(
                          'Cash collected (BHD ${delivery.cashToCollectAmount.toStringAsFixed(3)})',
                        ),
                        onChanged: provider.isSubmitting
                            ? null
                            : (value) =>
                                setState(() => _cashCollected = value ?? false),
                      ),
                    ],
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: provider.isSubmitting ? null : _selectPhoto,
                      icon: Icon(
                        _hasDeliveryPhoto
                            ? Icons.check_circle
                            : Icons.camera_alt,
                        color: _hasDeliveryPhoto
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                      label: Text(
                        _hasDeliveryPhoto
                            ? 'Delivery photo added'
                            : 'Add delivery photo',
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSm),
                    CustomButton(
                      title: provider.isSubmitting
                          ? 'Completing...'
                          : 'Confirm Delivery',
                      onPressed: provider.isSubmitting || !_hasDeliveryPhoto
                          ? null
                          : _confirmDelivery,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

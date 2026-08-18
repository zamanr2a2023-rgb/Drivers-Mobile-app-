import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/utils/app_helpers.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';
import 'package:yjeek_driver/features/orders/view/deliver_to_customer_screen.dart';
import 'package:yjeek_driver/navigation/bottom_nav_bar.dart';
import 'package:yjeek_driver/navigation/orders_nav_signal.dart';
import 'package:yjeek_driver/routes/route_names.dart';

class _ConfirmPickupScale {
  static const Size _designSize = Size(390, 844);
  static Size _screenSize = _designSize;

  static void update(Size size) {
    if (size.width > 0 && size.height > 0) {
      _screenSize = size;
    }
  }

  static double width(num value) =>
      value.toDouble() * (_screenSize.width / _designSize.width);

  static double height(num value) =>
      value.toDouble() * (_screenSize.height / _designSize.height);
}

extension _ConfirmPickupUnits on num {
  double get w => _ConfirmPickupScale.width(this);

  double get h => _ConfirmPickupScale.height(this);

  double get sp => _ConfirmPickupScale.width(this);
}

/// Route arguments for [ConfirmPickupScreen].
class ConfirmPickupArgs {
  const ConfirmPickupArgs({
    required this.orderId,
    required this.restaurantName,
  });

  final String orderId;
  final String restaurantName;
}

/// Confirm Pickup screen (Go to restaurant → Arrived).
/// Confirm calls upload + `POST /drivers/jobs/:jobId/confirm-pickup`.
class ConfirmPickupScreen extends StatefulWidget {
  const ConfirmPickupScreen({
    super.key,
    required this.args,
    required this.onBack,
  });

  final ConfirmPickupArgs args;
  final VoidCallback onBack;

  @override
  State<ConfirmPickupScreen> createState() => _ConfirmPickupScreenState();
}

class _ConfirmPickupScreenState extends State<ConfirmPickupScreen> {
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _screenBg = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF6B7B6E);
  static const Color _cardBorder = Color(0xFFE0E0E0);
  static const Color _iconGreenBg = Color(0xFFE8F5E9);
  static const Color _iconGreen = Color(0xFF2E7D32);
  static const Color _checkGreen = Color(0xFF4CAF50);
  static const Color _qtyBg = Color(0xFFE8F5E9);
  static const Color _qtyText = Color(0xFF2E7D32);
  static const Color _cashCardBg = Color(0xFFFFF0DE);
  static const Color _cashHeading = Color(0xFFE08A1E);
  static const Color _cashBody = Color(0xFF9A6A1E);
  static const Color _uploadBg = Color(0xFFF5F5F5);
  static const Color _uploadBorder = Color(0xFFBDBDBD);
  static const Color _uploadIcon = Color(0xFF9E9E9E);
  static const Color _confirmGreen = Color(0xFF4CAF50);

  static const String _restaurantIconAsset = 'assets/images/Frame (1).png';
  static const String _cashIconAsset =
      'assets/images/cash_on_delivery_icon.png';

  static const _items = [
    (qty: '1×', name: 'Gourmet Mezze Platter'),
    (qty: '1×', name: 'Lamb Ouzi'),
    (qty: '2×', name: 'Fresh Juice — Large'),
  ];

  bool _hasPickupPhoto = false;
  bool _showDeliverToCustomer = false;
  Uint8List? _pickupPhotoBytes;
  final ImagePicker _imagePicker = ImagePicker();

  void _handleBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteNames.mainNavigation,
          (route) => false,
        );
        return;
      case 1:
        OrdersNavSignal.openInstant();
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteNames.mainNavigation,
          (route) => false,
        );
        return;
      case 2:
        Navigator.pushNamed(context, RouteNames.earnings);
        return;
      case 3:
        Navigator.pushNamed(context, RouteNames.notifications);
        return;
      case 4:
        Navigator.pushNamed(context, RouteNames.profile);
        return;
    }
  }

  Future<void> _selectPickupPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || source == null) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (!mounted || picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _pickupPhotoBytes = bytes;
        _hasPickupPhoto = true;
      });
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to access photos. Please try again.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo selection failed. Please try again.'),
        ),
      );
    }
  }

  Future<void> _confirmPickup() async {
    if (!_hasPickupPhoto) return;

    final provider = context.read<OrderProvider>();
    if (provider.isConfirmingPickup) return;

    final photoBytes = _pickupPhotoBytes;
    if (photoBytes == null) return;

    final jobId = (provider.currentJobDetail?.id.trim().isNotEmpty == true)
        ? provider.currentJobDetail!.id.trim()
        : widget.args.orderId.trim();

    if (jobId.isEmpty || jobId.startsWith('#')) {
      Navigator.pushNamed(context, RouteNames.deliverToCustomer,
          arguments: jobId);
      return;
    }

    final result = await provider.confirmPickup(
      jobId: jobId,
      pickupPhotoBytes: photoBytes,
    );
    if (!mounted) return;

    if (result != null) {
      AppHelpers.showSnackBar(
        context,
        result.progressLabel.isNotEmpty
            ? result.progressLabel
            : 'Pickup confirmed',
      );
      Navigator.pushNamed(context, RouteNames.deliverToCustomer,
          arguments: jobId);
      return;
    }

    AppHelpers.showSnackBar(
      context,
      provider.confirmPickupError ?? 'Failed to confirm pickup',
      isError: true,
    );
  }

  void _closeDeliverToCustomer() {
    setState(() => _showDeliverToCustomer = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_showDeliverToCustomer) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: DeliverToCustomerScreen(
          jobId: widget.args.orderId,
          onBack: _closeDeliverToCustomer,
        ),
      );
    }

    _ConfirmPickupScale.update(MediaQuery.sizeOf(context));
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: _white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: _white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) widget.onBack();
        },
        child: Scaffold(
          backgroundColor: _screenBg,
          body: Column(
            children: [
              ColoredBox(
                color: _white,
                child: SizedBox(height: topInset),
              ),
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding:
                      EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h + bottomInset),
                  children: [
                    _buildRestaurantInfo(),
                    SizedBox(height: 16.h),
                    _buildItemsCard(),
                    SizedBox(height: 12.h),
                    _buildCashCard(),
                    SizedBox(height: 18.h),
                    _buildPickupProofHeading(),
                    SizedBox(height: 10.h),
                    _buildUploadArea(),
                    SizedBox(height: 20.h),
                    _buildConfirmButton(),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: 1,
            onTap: (index) => _handleBottomNavTap(context, index),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: _white,
      padding: EdgeInsets.fromLTRB(4.w, 8.h, 16.w, 12.h),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _textPrimary,
              size: 20,
            ),
          ),
          Expanded(
            child: Text(
              'Pickup · ${widget.args.orderId}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: _iconGreenBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Image.asset(
              _restaurantIconAsset,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.storefront_rounded,
                color: _iconGreen,
                size: 22,
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.args.restaurantName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                  height: 1.25,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                'Verify items before you leave',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: _textMuted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsCard() {
    return Container(
      width: double.infinity,
      height: 220.h,
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            _buildItemRow(
              quantity: _items[i].qty,
              name: _items[i].name,
            ),
            if (i < _items.length - 1) SizedBox(height: 14.h),
          ],
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildItemRow({required String quantity, required String name}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: _qtyBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            quantity,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: _qtyText,
              height: 1,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            name,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: _textPrimary,
              height: 1.3,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Icon(
          Icons.check_rounded,
          color: _checkGreen,
          size: 22.sp,
        ),
      ],
    );
  }

  Widget _buildCashCard() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: _cashCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: SizedBox(
                width: 22,
                height: 13,
                child: Image.asset(
                  _cashIconAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.payments_outlined,
                    color: _cashHeading,
                    size: 22,
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Collect cash on delivery',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: _cashHeading,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Hand the order, collect BHD 8.500',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: _cashBody,
                      height: 1.3,
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

  Widget _buildPickupProofHeading() {
    return Text(
      'Pickup proof',
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
        height: 1.2,
      ),
    );
  }

  Widget _buildUploadArea() {
    final hasImage = _hasPickupPhoto && _pickupPhotoBytes != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _selectPickupPhoto,
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: _uploadBorder,
            radius: 14,
            strokeWidth: 1.5,
            dashWidth: 6,
            dashGap: 4,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              height: 120.h,
              color: _uploadBg,
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(
                          _pickupPhotoBytes!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildUploadPlaceholder(),
                        ),
                        Positioned(
                          top: 8.h,
                          right: 8.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Change photo',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: _white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _buildUploadPlaceholder(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              color: _uploadIcon,
              size: 28.sp,
            ),
            SizedBox(height: 8.h),
            Text(
              'Add pickup photo · required',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    final isConfirming = context.watch<OrderProvider>().isConfirmingPickup;
    final enabled = _hasPickupPhoto && !isConfirming;

    return Opacity(
      opacity: enabled || isConfirming ? 1 : 0.45,
      child: SizedBox(
        width: double.infinity,
        height: 49.h,
        child: Material(
          color: _confirmGreen,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            onTap: enabled ? _confirmPickup : null,
            borderRadius: BorderRadius.circular(13),
            child: Center(
              child: isConfirming
                  ? SizedBox(
                      width: 22.sp,
                      height: 22.sp,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: _white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          color: _white,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: Text(
                            'Confirm pickup & start delivery',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: _white,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashGap,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        final extractPath = metric.extractPath(
          distance,
          next.clamp(0, metric.length),
        );
        canvas.drawPath(extractPath, paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth;
}

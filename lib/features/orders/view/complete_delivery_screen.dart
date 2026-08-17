import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/utils/app_helpers.dart';
import 'package:yjeek_driver/features/orders/model/job_detail_model.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';
import 'package:yjeek_driver/routes/route_names.dart';

class _CompleteDeliveryScale {
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

extension _CompleteDeliveryUnits on num {
  double get w => _CompleteDeliveryScale.width(this);

  double get h => _CompleteDeliveryScale.height(this);

  double get sp => _CompleteDeliveryScale.width(this);
}

/// Local UI-only “Complete delivery” screen (Deliver to customer → Arrived).
class CompleteDeliveryScreen extends StatefulWidget {
  const CompleteDeliveryScreen({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  State<CompleteDeliveryScreen> createState() => _CompleteDeliveryScreenState();
}

class _CompleteDeliveryScreenState extends State<CompleteDeliveryScreen> {
  static const Color _headerGreen = Color(0xFF4DB04F);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _screenBg = Color(0xFFF4F8F2);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF9E9E9E);
  static const Color _cardBorder = Color(0xFFE0E0E0);
  static const Color _reportText = Color(0xFFCFE3D5);
  static const Color _uploadBg = Color(0xFFF5F5F5);
  static const Color _uploadBorder = Color(0xFFBDBDBD);

  static const String _fallbackCustomerName = 'Sara A.';
  static const String _fallbackOrderId = '#YJK-...52';
  static const String _fallbackItemCountLabel = '3 items';
  static const String _fallbackPaymentLabel = 'Prepaid · Yjeek Wallet';

  bool _hasProofPhoto = false;
  Uint8List? _proofPhotoBytes;
  final ImagePicker _imagePicker = ImagePicker();

  bool get _canComplete => _hasProofPhoto && _proofPhotoBytes != null;

  Future<void> _selectProofPhoto() async {
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
        _proofPhotoBytes = bytes;
        _hasProofPhoto = true;
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

  Future<void> _completeDelivery() async {
    if (!_canComplete) return;

    final provider = context.read<OrderProvider>();
    if (provider.isCompletingJob) return;

    final job = provider.currentJobDetail;
    final jobId = job?.id.trim() ?? '';
    if (jobId.isEmpty) {
      AppHelpers.showSnackBar(
        context,
        'No active job found to complete',
        isError: true,
      );
      return;
    }

    final photoBytes = _proofPhotoBytes;
    if (photoBytes == null) return;

    final result = await provider.completeJob(
      jobId: jobId,
      deliveryPhotoBytes: photoBytes,
      cashCollected: job?.requiresCashCollection ?? false,
    );

    if (!mounted) return;

    if (result != null) {
      AppHelpers.showSnackBar(context, result.message);
      Navigator.pushNamed(
        context,
        RouteNames.deliveryCompleted,
        arguments: result,
      );
      return;
    }

    AppHelpers.showSnackBar(
      context,
      provider.completeJobError ?? 'Failed to complete delivery',
      isError: true,
    );
  }

  String _customerLabel(JobDetailModel? job) {
    final name = job?.order.customer.displayName.trim() ?? '';
    return name.isNotEmpty ? name : _fallbackCustomerName;
  }

  String _orderLabel(JobDetailModel? job) {
    final number = job?.order.displayOrderNumber.trim() ?? '';
    return number.isNotEmpty ? number : _fallbackOrderId;
  }

  String _itemCountLabel(JobDetailModel? job) {
    if (job == null) return _fallbackItemCountLabel;
    final count = job.order.items.fold<int>(0, (sum, item) => sum + item.quantity);
    if (count <= 0) return _fallbackItemCountLabel;
    return count == 1 ? '1 item' : '$count items';
  }

  String _paymentLabel(JobDetailModel? job) {
    if (job == null) return _fallbackPaymentLabel;
    if (job.requiresCashCollection) {
      return 'Cash on delivery';
    }
    final method = job.order.paymentMethod.replaceAll('_', ' ').trim();
    if (method.isEmpty) return _fallbackPaymentLabel;
    final status = job.order.paymentStatus.trim();
    if (status.toUpperCase() == 'PAID') {
      return 'Prepaid · $method';
    }
    return method;
  }

  @override
  Widget build(BuildContext context) {
    _CompleteDeliveryScale.update(MediaQuery.sizeOf(context));
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final provider = context.watch<OrderProvider>();
    final job = provider.currentJobDetail;
    final isCompleting = provider.isCompletingJob;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
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
                color: Colors.white,
                child: SizedBox(height: topInset),
              ),
              _buildHeader(job),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    16.w,
                    14.h,
                    16.w,
                    16.h + bottomInset,
                  ),
                  children: [
                    _buildHandoverCard(job),
                    SizedBox(height: 14.h),
                    _buildUploadArea(),
                    SizedBox(height: 20.h),
                    _buildCompleteButton(isCompleting: isCompleting),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(JobDetailModel? job) {
    final subtitle = '${_customerLabel(job)} · ${_orderLabel(job)}';

    return Container(
      width: double.infinity,
      color: _headerGreen,
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.22),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: widget.onBack,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 36.w,
                height: 36.w,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: 18.sp,
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
                  'Complete delivery',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: _reportText,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pushNamed(
                context,
                RouteNames.reportAtDropoff,
                arguments: {
                  'orderId': _orderLabel(job),
                  'customerName': _customerLabel(job),
                  'address': job?.order.address.navigationAddress ?? '',
                },
              ),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      color: _reportText,
                      size: 13.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Report',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: _reportText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandoverCard(JobDetailModel? job) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Handover',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              height: 1.25,
            ),
          ),
          SizedBox(height: 14.h),
          _buildDetailRow('Items', _itemCountLabel(job)),
          SizedBox(height: 10.h),
          _buildDetailRow('Payment', _paymentLabel(job)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w400,
            color: _textMuted,
            height: 1.3,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadArea() {
    final hasImage = _hasProofPhoto && _proofPhotoBytes != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _selectProofPhoto,
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
                          _proofPhotoBytes!,
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
              color: _textPrimary,
              size: 24.sp,
            ),
            SizedBox(height: 8.h),
            Text(
              'Add proof of delivery',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                height: 1.2,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Required',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: _textMuted,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteButton({required bool isCompleting}) {
    final enabled = _canComplete && !isCompleting;

    return Opacity(
      opacity: enabled || isCompleting ? 1 : 0.45,
      child: SizedBox(
        width: double.infinity,
        height: 52.h,
        child: Material(
          color: _headerGreen,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: enabled ? _completeDelivery : null,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: isCompleting
                  ? SizedBox(
                      width: 22.w,
                      height: 22.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: _white,
                      ),
                    )
                  : Text(
                      'Complete delivery',
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

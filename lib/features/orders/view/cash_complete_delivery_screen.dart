import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';
import 'package:yjeek_driver/navigation/bottom_nav_bar.dart';
import 'package:yjeek_driver/navigation/orders_nav_signal.dart';
import 'package:yjeek_driver/routes/route_names.dart';

class _CashCompleteScale {
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

extension _CashCompleteUnits on num {
  double get w => _CashCompleteScale.width(this);

  double get h => _CashCompleteScale.height(this);

  double get sp => _CashCompleteScale.width(this);
}

class CashCompleteDeliveryScreen extends StatefulWidget {
  const CashCompleteDeliveryScreen({super.key});

  @override
  State<CashCompleteDeliveryScreen> createState() =>
      _CashCompleteDeliveryScreenState();
}

class _CashCompleteDeliveryScreenState
    extends State<CashCompleteDeliveryScreen> {
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _screenBg = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF6B7B6E);
  static const Color _cardBorder = Color(0xFFE0E0E0);
  static const Color _green = Color(0xFF4CAF50);
  static const Color _greenBg = Color(0xFFE8F5E9);
  static const Color _cashBg = Color(0xFFFFF0DE);
  static const Color _cashText = Color(0xFFE67E22);
  static const Color _uploadBg = Color(0xFFF8F8F8);
  static const Color _uploadBorder = Color(0xFFBDBDBD);

  Uint8List? _proofPhotoBytes;
  final ImagePicker _imagePicker = ImagePicker();

  bool get _hasProofPhoto => _proofPhotoBytes != null;

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
      setState(() => _proofPhotoBytes = bytes);
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

  void _completeDelivery() {
    Navigator.pushNamed(context, RouteNames.cashDeliveryCompleted);
  }

  @override
  Widget build(BuildContext context) {
    _CashCompleteScale.update(MediaQuery.sizeOf(context));
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: _white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) Navigator.pop(context);
        },
        child: Scaffold(
          backgroundColor: _screenBg,
          body: Column(
            children: [
              ColoredBox(
                color: _white,
                child: SizedBox(height: topInset),
              ),
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    16.w,
                    14.h,
                    16.w,
                    16.h + bottomInset,
                  ),
                  children: [
                    _buildCustomerCard(),
                    if (context
                            .watch<OrderProvider>()
                            .currentJobDetail
                            ?.order
                            .hasTip ==
                        true) ...[
                      SizedBox(height: 14.h),
                      _buildTipCard(),
                    ],
                    SizedBox(height: 14.h),
                    _buildCashCard(),
                    SizedBox(height: 14.h),
                    _buildProofTitle(),
                    SizedBox(height: 10.h),
                    _buildUploadArea(),
                    SizedBox(height: 18.h),
                    _buildCompleteButton(),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _white,
      padding: EdgeInsets.fromLTRB(4.w, 8.h, 16.w, 12.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _textPrimary,
              size: 20.sp,
            ),
          ),
          Expanded(
            child: Text(
              'Complete delivery',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 13.h, 14.w, 13.h),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: _greenBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: _green,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  () {
                    final name = context
                            .watch<OrderProvider>()
                            .currentJobDetail
                            ?.order
                            .customer
                            .displayName
                            .trim() ??
                        '';
                    return name.isEmpty ? '—' : name;
                  }(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  () {
                    final job =
                        context.watch<OrderProvider>().currentJobDetail;
                    final area = job?.order.address.shortLabel.trim() ?? '';
                    final orderNo = job?.order.displayOrderNumber.trim() ?? '';
                    if (area.isEmpty && orderNo.isEmpty) return '—';
                    if (area.isEmpty) return orderNo;
                    if (orderNo.isEmpty) return area;
                    return '$area · $orderNo';
                  }(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _textMuted,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard() {
    final order = context.watch<OrderProvider>().currentJobDetail?.order;
    final label = order?.tipAmountLabel ?? 'BHD 0.000';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 13.h, 14.w, 13.h),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Text(
            'Tip',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
              color: _textMuted,
              height: 1.25,
            ),
          ),
          const Spacer(),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashCard() {
    final order = context.watch<OrderProvider>().currentJobDetail?.order;
    final amount = order == null
        ? 0.0
        : (order.cashToCollectAmount > 0
            ? order.cashToCollectAmount
            : order.totalAmount);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: _cashBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Collect cash',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: _cashText,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'BHD ${amount.toStringAsFixed(3)}',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        color: _cashText,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.camera_alt_outlined,
                color: _cashText,
                size: 22.sp,
              ),
            ],
          ),
          SizedBox(height: 11.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 22.w,
                  height: 22.w,
                  decoration: const BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: _white,
                    size: 15.sp,
                  ),
                ),
                SizedBox(width: 9.w),
                Text(
                  'Cash collected from customer',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofTitle() {
    return Text(
      'Proof of delivery',
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        color: _textPrimary,
        height: 1.2,
      ),
    );
  }

  Widget _buildUploadArea() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _selectProofPhoto,
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: _CashDashedBorderPainter(
            color: _uploadBorder,
            radius: 14,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              height: 92.h,
              color: _uploadBg,
              child: _hasProofPhoto
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
                          right: 8.w,
                          top: 8.h,
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            color: _textPrimary,
            size: 22.sp,
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              'Add pickup photo  ·  required',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.sp,
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

  Widget _buildCompleteButton() {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: Material(
        color: _green,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _completeDelivery,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: _white,
                  size: 17.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Complete delivery',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: _white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CashDashedBorderPainter extends CustomPainter {
  const _CashDashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 6;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + 4;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CashDashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

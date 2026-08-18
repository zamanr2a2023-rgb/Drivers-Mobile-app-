import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/widgets/app_google_map.dart';
import 'package:yjeek_driver/features/orders/model/job_detail_model.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';
import 'package:yjeek_driver/features/orders/view/go_to_restaurant_screen.dart';
import 'package:yjeek_driver/features/orders/view/reject_scheduled_order_screen.dart';
import 'package:yjeek_driver/navigation/bottom_nav_bar.dart';
import 'package:yjeek_driver/navigation/orders_nav_signal.dart';
import 'package:yjeek_driver/routes/route_names.dart';

class _OrderDeliveryScale {
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

extension _OrderDeliveryUnits on num {
  double get w => _OrderDeliveryScale.width(this);

  double get h => _OrderDeliveryScale.height(this);
}

/// Order Delivery — New Request (Figma DO1).
/// Opened from Auto-Accept ON → Accept now.
class OrderDeliveryNewRequestScreen extends StatefulWidget {
  const OrderDeliveryNewRequestScreen({super.key});

  static const Color _white = Color(0xFFFFFFFF);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF6B7B6E);
  static const Color _green = Color(0xFF4CAF50);
  static const Color _greenDark = Color(0xFF0F4D27);
  static const Color _routeCardBg = Color(0xFFF2F4F2);
  static const Color _cashCardBg = Color(0xFFFFF0DE);
  static const Color _orange = Color(0xFFF28A0B);
  static const Color _orangeText = Color(0xFFE08A1E);
  static const Color _timerBg = Color(0xFFFFF0DE);
  static const Color _handle = Color(0xFFD9D9D9);
  static const Color _blackDot = Color(0xFF1B1B1B);
  static const Color _routeLine = Color(0xFFD0D5D0);
  static const Color _declineBorder = Color(0xFF8A958A);
  static const Color _declineText = Color(0xFF6B7B6E);

  static const String _timerText = '0:30';

  @override
  State<OrderDeliveryNewRequestScreen> createState() =>
      _OrderDeliveryNewRequestScreenState();
}

class _OrderDeliveryNewRequestScreenState
    extends State<OrderDeliveryNewRequestScreen> {
  bool _showRejectScreen = false;

  JobDetailModel? get _job =>
      context.read<OrderProvider>().currentJobDetail;

  String get _jobId => _job?.id ?? '';
  String get _orderId => _job?.order.displayOrderNumber ?? '#—';
  String get _restaurantName =>
      _job?.order.vendor.name.trim().isNotEmpty == true
          ? _job!.order.vendor.name.trim()
          : 'Restaurant';
  String get _pickupLocation {
    final j = _job;
    if (j == null) return '—';
    final area = j.order.vendor.area.trim();
    if (area.isNotEmpty) return area;
    return j.order.vendor.city.trim().isNotEmpty
        ? j.order.vendor.city.trim()
        : '—';
  }

  String get _pickupDistance => _job != null && _job!.distanceKm > 0
      ? '${_job!.distanceKm.toStringAsFixed(1)} km'
      : '—';
  String get _pickupEta => _job != null && _job!.estimatedDurationMin > 0
      ? '~${_job!.estimatedDurationMin} min'
      : '—';
  String get _earningsLabel => _job != null && _job!.driverEarnings > 0
      ? 'BHD ${_job!.driverEarnings.toStringAsFixed(3)}'
      : 'BHD 0.000';
  String get _distanceKmLabel =>
      _job != null && _job!.distanceKm > 0
          ? '${_job!.distanceKm.toStringAsFixed(1)} km'
          : '—';
  String get _etaCategoryLabel {
    final j = _job;
    if (j == null) return '';
    final parts = <String>[];
    if (j.estimatedDurationMin > 0) parts.add('~${j.estimatedDurationMin} min');
    final type = j.order.fulfillmentType.trim();
    if (type.isNotEmpty) parts.add(type);
    return parts.isEmpty ? '' : parts.join(' · ');
  }

  String get _dropoffLabel {
    final j = _job;
    if (j == null) return '—';
    return j.order.address.shortLabel;
  }

  String get _customerName {
    final j = _job;
    if (j == null) return 'Customer';
    return j.order.customer.displayName;
  }

  bool get _isCash => _job?.requiresCashCollection ?? false;

  String get _cashCollectLabel =>
      _job?.order.cashCollectLabel ?? 'Collect cash on delivery';

  void _openReject() {
    setState(() => _showRejectScreen = true);
  }

  void _closeReject() {
    setState(() => _showRejectScreen = false);
  }

  void _submitReject(String reason, String note) {
    final jobId = _jobId;
    if (jobId.isNotEmpty && !jobId.startsWith('#')) {
      context.read<OrderProvider>().declineJob(
            jobId: jobId,
            reason: reason,
            note: note,
          );
    }
    setState(() => _showRejectScreen = false);
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

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

  @override
  Widget build(BuildContext context) {
    context.watch<OrderProvider>();

    if (_showRejectScreen) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: RejectScheduledOrderScreen(
          orderId: _orderId,
          onBack: _closeReject,
          onKeepOrder: _closeReject,
          onSubmitDecline: _submitReject,
        ),
      );
    }

    final media = MediaQuery.of(context);
    _OrderDeliveryScale.update(media.size);
    final topInset = media.padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: OrderDeliveryNewRequestScreen._white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: OrderDeliveryNewRequestScreen._white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: OrderDeliveryNewRequestScreen._white,
        body: Column(
          children: [
            ColoredBox(
              color: OrderDeliveryNewRequestScreen._white,
              child: SizedBox(height: topInset),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final mapHeight =
                      (constraints.maxHeight * 0.42).clamp(240.0, 360.0);

                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: mapHeight,
                            width: double.infinity,
                            child: const _DeliveryMapSection(),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -16),
                            child: _DetailsPanel(
                              earningsLabel: _earningsLabel,
                              distanceKmLabel: _distanceKmLabel,
                              etaCategoryLabel: _etaCategoryLabel,
                              restaurantName: _restaurantName,
                              pickupSubtitle:
                                  'Pickup · $_pickupLocation',
                              customerName: _customerName,
                              dropoffSubtitle:
                                  'Drop-off · $_dropoffLabel',
                              isCash: _isCash,
                              cashCollectLabel: _cashCollectLabel,
                              onDecline: _openReject,
                              onAccept: () {
                                Navigator.pushNamed(
                                  context,
                                  RouteNames.goToRestaurant,
                                  arguments: GoToRestaurantArgs(
                                    orderId: _jobId,
                                    restaurantName: _restaurantName,
                                    pickupLocation: _pickupLocation,
                                    distance: _pickupDistance,
                                    estimatedTime: _pickupEta,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 1,
          onTap: (index) => _handleBottomNavTap(context, index),
        ),
      ),
    );
  }
}

class _DeliveryMapSection extends StatelessWidget {
  const _DeliveryMapSection();

  @override
  Widget build(BuildContext context) {
    return const AppGoogleMap();
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({
    required this.earningsLabel,
    required this.distanceKmLabel,
    required this.etaCategoryLabel,
    required this.restaurantName,
    required this.pickupSubtitle,
    required this.customerName,
    required this.dropoffSubtitle,
    required this.isCash,
    required this.cashCollectLabel,
    required this.onDecline,
    required this.onAccept,
  });

  final String earningsLabel;
  final String distanceKmLabel;
  final String etaCategoryLabel;
  final String restaurantName;
  final String pickupSubtitle;
  final String customerName;
  final String dropoffSubtitle;
  final bool isCash;
  final String cashCollectLabel;
  final VoidCallback onDecline;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OrderDeliveryNewRequestScreen._white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: OrderDeliveryNewRequestScreen._handle,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            SizedBox(height: 14.h),
            const _RequestHeader(),
            SizedBox(height: 14.h),
            _PriceAndDistance(
              earningsLabel: earningsLabel,
              distanceKmLabel: distanceKmLabel,
              etaCategoryLabel: etaCategoryLabel,
            ),
            SizedBox(height: 14.h),
            _RouteInfoCard(
              restaurantName: restaurantName,
              pickupSubtitle: pickupSubtitle,
              customerName: customerName,
              dropoffSubtitle: dropoffSubtitle,
            ),
            if (isCash) ...[
              SizedBox(height: 12.h),
              _CashCard(cashCollectLabel: cashCollectLabel),
            ],
            SizedBox(height: 16.h),
            _ActionButtons(
              onDecline: onDecline,
              onAccept: onAccept,
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestHeader extends StatelessWidget {
  const _RequestHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'New delivery request',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: OrderDeliveryNewRequestScreen._textDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: OrderDeliveryNewRequestScreen._timerBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.access_time_rounded,
                color: OrderDeliveryNewRequestScreen._orange,
                size: 15,
              ),
              SizedBox(width: 4),
              Text(
                OrderDeliveryNewRequestScreen._timerText,
                style: TextStyle(
                  color: OrderDeliveryNewRequestScreen._orange,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceAndDistance extends StatelessWidget {
  const _PriceAndDistance({
    required this.earningsLabel,
    required this.distanceKmLabel,
    required this.etaCategoryLabel,
  });

  final String earningsLabel;
  final String distanceKmLabel;
  final String etaCategoryLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    earningsLabel,
                    maxLines: 1,
                    style: const TextStyle(
                      color: OrderDeliveryNewRequestScreen._greenDark,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'incl. tip',
                  style: TextStyle(
                    color: OrderDeliveryNewRequestScreen._textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              distanceKmLabel,
              style: const TextStyle(
                color: OrderDeliveryNewRequestScreen._textDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              etaCategoryLabel,
              style: const TextStyle(
                color: OrderDeliveryNewRequestScreen._textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.15,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RouteInfoCard extends StatelessWidget {
  const _RouteInfoCard({
    required this.restaurantName,
    required this.pickupSubtitle,
    required this.customerName,
    required this.dropoffSubtitle,
  });

  final String restaurantName;
  final String pickupSubtitle;
  final String customerName;
  final String dropoffSubtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: OrderDeliveryNewRequestScreen._routeCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(width: 12, child: _RouteDots()),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: OrderDeliveryNewRequestScreen._textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pickupSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: OrderDeliveryNewRequestScreen._textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: OrderDeliveryNewRequestScreen._textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dropoffSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: OrderDeliveryNewRequestScreen._textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
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

class _RouteDots extends StatelessWidget {
  const _RouteDots();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _Dot(color: OrderDeliveryNewRequestScreen._green),
        Expanded(
          child: Container(
            width: 2,
            margin: const EdgeInsets.symmetric(vertical: 2),
            color: OrderDeliveryNewRequestScreen._routeLine,
          ),
        ),
        const _Dot(color: OrderDeliveryNewRequestScreen._blackDot),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _CashCard extends StatelessWidget {
  const _CashCard({required this.cashCollectLabel});

  final String cashCollectLabel;

  static const String _cashIconAsset =
      'assets/images/cash_on_delivery_icon.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: OrderDeliveryNewRequestScreen._cashCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SizedBox(
              width: 22,
              height: 13,
              child: Image.asset(
                _cashIconAsset,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.payments_outlined,
                  color: OrderDeliveryNewRequestScreen._orange,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Collect cash on delivery',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: OrderDeliveryNewRequestScreen._orangeText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cashCollectLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: OrderDeliveryNewRequestScreen._orangeText,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
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
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onDecline,
    required this.onAccept,
  });

  final VoidCallback onDecline;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48.h.clamp(46.0, 52.0),
            child: Material(
              color: OrderDeliveryNewRequestScreen._white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(
                  color: OrderDeliveryNewRequestScreen._declineBorder,
                  width: 1.4,
                ),
              ),
              child: InkWell(
                onTap: onDecline,
                borderRadius: BorderRadius.circular(14),
                child: const Center(
                  child: Text(
                    'Decline',
                    style: TextStyle(
                      color: OrderDeliveryNewRequestScreen._declineText,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: SizedBox(
            height: 48.h.clamp(46.0, 52.0),
            child: Material(
              color: OrderDeliveryNewRequestScreen._green,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: onAccept,
                borderRadius: BorderRadius.circular(14),
                child: const Center(
                  child: Text(
                    'Accept',
                    style: TextStyle(
                      color: OrderDeliveryNewRequestScreen._white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

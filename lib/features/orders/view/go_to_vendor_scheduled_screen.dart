import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/services/map_service.dart';
import 'package:yjeek_driver/core/utils/app_helpers.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_order.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_shared.dart';
import 'package:yjeek_driver/routes/route_names.dart';

/// “Go to vendor” screen for scheduled On Track deliveries.
/// Arrived calls `POST /drivers/jobs/:jobId/arrive-pickup`.
class GoToVendorScheduledScreen extends StatelessWidget {
  const GoToVendorScheduledScreen({
    super.key,
    required this.order,
  });

  final ScheduledDeliveryOrder order;

  static const Color _headerGreen = Color(0xFF4DB04F);
  static const Color _screenBg = Color(0xFFF4F8F2);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF9E9E9E);
  static const Color _cardBorder = Color(0xFFE0E0E0);
  static const Color _pickupBadgeBg = Color(0xFFE8F5E9);
  static const Color _pickupBadgeText = Color(0xFF2E7D32);
  static const Color _deadlineBg = Color(0xFFE8F5E9);
  static const Color _deadlineText = Color(0xFF2E7D32);
  static const Color _reportText = Color(0xFFCFE3D5);
  static const Color _windowGreen = Color(0xFF4DB04F);

  @override
  Widget build(BuildContext context) {
    ScheduledDeliveryScale.update(MediaQuery.sizeOf(context));
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
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
                color: Colors.white,
                child: SizedBox(height: topInset),
              ),
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const ScheduledMapPlaceholder(),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        16.sw,
                        14.sh,
                        16.sw,
                        24.sh + bottomInset,
                      ),
                      child: Column(
                        children: [
                          _buildVendorCard(),
                          SizedBox(height: 12.sh),
                          _buildDeadlineNotice(),
                          SizedBox(height: 14.sh),
                          scheduledReportNavigateRow(
                            onReport: () => Navigator.pushNamed(
                              context,
                              RouteNames.reportAtPickup,
                              arguments: {
                                'orderId': order.orderId,
                                'vendorName': order.vendorName,
                              },
                            ),
                            onNavigate: () =>
                                MapService.openNavigationOrShowError(
                              context,
                              address: order.vendorAddress,
                            ),
                          ),
                          SizedBox(height: 12.sh),
                          _buildArrivedButton(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: scheduledBottomNav(context),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _headerGreen,
      padding: EdgeInsets.fromLTRB(12.sw, 10.sh, 12.sw, 10.sh),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.22),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 36.sw,
                height: 36.sw,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: 18.ssp,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.sw),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Go to vendor',
                  style: TextStyle(
                    fontSize: 15.ssp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 3.sh),
                Text(
                  order.distanceEtaLabel,
                  style: TextStyle(
                    fontSize: 12.ssp,
                    fontWeight: FontWeight.w500,
                    color: _reportText,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              RouteNames.reportAtPickup,
              arguments: {
                'orderId': order.orderId,
                'vendorName': order.vendorName,
              },
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.sw, vertical: 6.sh),
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
                    size: 13.ssp,
                  ),
                  SizedBox(width: 4.sw),
                  Text(
                    'Report',
                    style: TextStyle(
                      fontSize: 11.ssp,
                      fontWeight: FontWeight.w600,
                      color: _reportText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.sw, 14.sh, 14.sw, 14.sh),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.sw, vertical: 4.sh),
                decoration: BoxDecoration(
                  color: _pickupBadgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PICKUP',
                  style: TextStyle(
                    fontSize: 10.ssp,
                    fontWeight: FontWeight.w700,
                    color: _pickupBadgeText,
                    height: 1,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '📦 ${order.category}',
                style: TextStyle(
                  fontSize: 11.ssp,
                  fontWeight: FontWeight.w500,
                  color: _textMuted,
                  height: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.sh),
          Text(
            order.vendorName,
            style: TextStyle(
              fontSize: 18.ssp,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              height: 1.2,
            ),
          ),
          SizedBox(height: 14.sh),
          _buildDetailRow('Address', order.vendorAddress),
          SizedBox(height: 10.sh),
          _buildDetailRow('Order', order.orderId),
          SizedBox(height: 10.sh),
          _buildDetailRow(
            'Window',
            order.scheduledWindow,
            valueColor: _windowGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.ssp,
            fontWeight: FontWeight.w400,
            color: _textMuted,
            height: 1.3,
          ),
        ),
        SizedBox(width: 12.sw),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13.ssp,
              fontWeight: FontWeight.w700,
              color: valueColor ?? _textPrimary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlineNotice() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.sw, vertical: 12.sh),
      decoration: BoxDecoration(
        color: _deadlineBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '🔒',
            style: TextStyle(fontSize: 14.ssp, height: 1),
          ),
          SizedBox(width: 10.sw),
          Expanded(
            child: Text(
              order.pickupDeadlineNotice,
              style: TextStyle(
                fontSize: 12.ssp,
                fontWeight: FontWeight.w600,
                color: _deadlineText,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrivedButton(BuildContext context) {
    final isArriving = context.watch<OrderProvider>().isArrivingAtPickup;

    return SizedBox(
      width: double.infinity,
      height: 52.sh,
      child: Material(
        color: _headerGreen,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: isArriving ? null : () => _arriveAtVendor(context),
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: isArriving
                ? SizedBox(
                    width: 22.sw,
                    height: 22.sw,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Arrived at Vendor',
                    style: TextStyle(
                      fontSize: 15.ssp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _arriveAtVendor(BuildContext context) async {
    final provider = context.read<OrderProvider>();
    if (provider.isArrivingAtPickup) return;

    var next = order;
    final jobId = scheduledLiveJobId(order, provider);

    if (isScheduledLiveJobId(jobId)) {
      final success = await provider.arriveAtPickup(jobId);
      if (!context.mounted) return;

      if (!success) {
        await provider.loadJobDetail(jobId);
        if (!context.mounted) return;
        final job = provider.currentJobDetail;
        final alreadyThere = job != null &&
            (job.isAtVendor || job.canArriveAtCustomer || !job.isPickupPhase);
        if (!alreadyThere) {
          AppHelpers.showSnackBar(
            context,
            provider.arrivePickupError ?? 'Failed to mark arrived at pickup',
            isError: true,
          );
          return;
        }
      }

      next = scheduledOrderFromJob(next, provider.currentJobDetail);
    }

    if (!context.mounted) return;
    Navigator.pushNamed(
      context,
      _pickupRouteFor(next),
      arguments: next,
    );
  }
}

String _pickupRouteFor(ScheduledDeliveryOrder order) {
  if (_isScheduledVapeOrder(order)) {
    return RouteNames.scheduledVapePickup;
  }
  if (_isSecurePickupLuxuryOrder(order)) {
    return RouteNames.securePickupLuxury;
  }
  return RouteNames.scheduledPickup;
}

bool _isScheduledVapeOrder(ScheduledDeliveryOrder order) {
  final category = order.category.toLowerCase();
  final type = order.orderTypeLabel.toLowerCase();
  return category.contains('vape') || type.contains('vape');
}

bool _isSecurePickupLuxuryOrder(ScheduledDeliveryOrder order) {
  final category = order.category.toLowerCase();
  final type = order.orderTypeLabel.toLowerCase();
  final vendor = order.vendorName.toLowerCase();
  final status = order.cardStatusLine.toLowerCase();
  return category.contains('luxury') ||
      type.contains('luxury') ||
      vendor.contains('luxury') ||
      status.contains('restricted');
}

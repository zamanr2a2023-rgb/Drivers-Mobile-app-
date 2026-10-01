import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yjeek_driver/core/widgets/app_google_map.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_completed_order_detail.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_order.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_shared.dart';
import 'package:yjeek_driver/routes/route_names.dart';

/// Detail screen opened from Orders → Scheduled → Completed card tap.
class ScheduledCompletedOrderDetailScreen extends StatelessWidget {
  const ScheduledCompletedOrderDetailScreen({
    super.key,
    required this.order,
  });

  final ScheduledCompletedOrderDetail order;

  static const Color _headerGreen = Color(0xFF4DB04F);
  static const Color _screenBg = Color(0xFFF4F8F2);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF9E9E9E);
  static const Color _cardBorder = Color(0xFFE0E0E0);
  static const Color _pickupBadgeBg = Color(0xFFFFF4E6);
  static const Color _pickupBadgeText = Color(0xFFB86A00);
  static const Color _vapeBadgeText = Color(0xFFB86A00);
  static const Color _subtitleText = Color(0xFFCFE3D5);
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
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.sw, 14.sh, 16.sw, 0),
                      child: _buildMapPlaceholder(),
                    ),
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
                          SizedBox(height: 14.sh),
                          scheduledReportNavigateRow(
                            onReport: () => Navigator.pushNamed(
                              context,
                              RouteNames.reportAtDropoff,
                              arguments: {
                                'orderId': order.orderId,
                                'vendorName': order.vendorName,
                              },
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
      padding: EdgeInsets.fromLTRB(12.sw, 10.sh, 16.sw, 10.sh),
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
                    fontSize: 19.ssp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 3.sh),
                Text(
                  order.distanceEtaLabel,
                  style: TextStyle(
                    fontSize: 15.ssp,
                    fontWeight: FontWeight.w500,
                    color: _subtitleText,
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

  Widget _buildMapPlaceholder() {
    return AppGoogleMap(
      height: 200.sh,
      borderRadius: BorderRadius.circular(16),
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
                order.isVapeRestricted
                    ? '🔞 ${order.categoryBadge}'
                    : order.categoryBadge,
                style: TextStyle(
                  fontSize: 11.ssp,
                  fontWeight: FontWeight.w600,
                  color: order.isVapeRestricted ? _vapeBadgeText : _textMuted,
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
          if (order.tipAmount > 0) ...[
            SizedBox(height: 10.sh),
            _buildDetailRow(
              'Tip',
              'BHD ${order.tipAmount.toStringAsFixed(3)}',
            ),
          ],
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

  Widget _buildArrivedButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.sh,
      child: Material(
        color: _headerGreen,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: order.isVapeRestricted
              ? () {
                  Navigator.pushNamed(
                    context,
                    RouteNames.scheduledVapePickup,
                    arguments: order.toDeliveryOrder(),
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Text(
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
}

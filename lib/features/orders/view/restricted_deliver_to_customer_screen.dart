import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yjeek_driver/core/services/map_service.dart';
import 'package:yjeek_driver/core/widgets/app_google_map.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_order.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_shared.dart';
import 'package:yjeek_driver/routes/route_names.dart';

/// Deliver-to-customer screen for restricted luxury scheduled deliveries.
class RestrictedDeliverToCustomerScreen extends StatelessWidget {
  const RestrictedDeliverToCustomerScreen({
    super.key,
    required this.order,
  });

  final ScheduledDeliveryOrder order;

  static const Color _headerGreen = Color(0xFF4DB04F);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _screenBg = Color(0xFFF4F8F2);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF9E9E9E);
  static const Color _cardBorder = Color(0xFFE0E0E0);
  static const Color _subtitleText = Color(0xFFCFE3D5);
  static const Color _securityBg = Color(0xFFE8F5E9);
  static const Color _securityText = Color(0xFF2E7D32);
  static const Color _orange = Color(0xFFE67E22);

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
                  padding: EdgeInsets.fromLTRB(
                    16.sw,
                    14.sh,
                    16.sw,
                    24.sh + bottomInset,
                  ),
                  children: [
                    _buildMapPlaceholder(),
                    SizedBox(height: 14.sh),
                    _buildDropOffCard(),
                    SizedBox(height: 12.sh),
                    _buildSecurityBanner(),
                    SizedBox(height: 14.sh),
                    _buildActionButtons(context),
                    SizedBox(height: 12.sh),
                    _buildArrivedButton(context),
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
                  'Deliver to customer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.ssp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 3.sh),
                Text(
                  order.deliveryDistanceEtaLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.ssp,
                    fontWeight: FontWeight.w500,
                    color: _subtitleText,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => Navigator.pushNamed(
                context,
                RouteNames.reportAtDropoff,
                arguments: {
                  'orderId': order.orderId,
                  'customerName': order.customerName,
                },
              ),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.sw, vertical: 6.sh),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      color: _subtitleText,
                      size: 13.ssp,
                    ),
                    SizedBox(width: 4.sw),
                    Text(
                      'Report',
                      style: TextStyle(
                        fontSize: 11.ssp,
                        fontWeight: FontWeight.w600,
                        color: _subtitleText,
                        height: 1.2,
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

  Widget _buildMapPlaceholder() {
    return AppGoogleMap(
      height: 200.sh,
      borderRadius: BorderRadius.circular(14),
    );
  }

  Widget _buildDropOffCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.sw, 14.sh, 14.sw, 14.sh),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Drop-off · named recipient only',
            style: TextStyle(
              fontSize: 14.ssp,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              height: 1.25,
            ),
          ),
          SizedBox(height: 14.sh),
          _buildDetailRow('Recipient', '${order.customerName} (ID required)'),
          SizedBox(height: 10.sh),
          _buildDetailRow('Phone', order.customerPhone),
          SizedBox(height: 10.sh),
          _buildDetailRow('Address', order.customerAddress),
          if (order.hasTip) ...[
            SizedBox(height: 10.sh),
            _buildDetailRow('Tip', order.tipAmountLabel),
          ],
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
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: 13.ssp,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.sw, vertical: 10.sh),
      decoration: BoxDecoration(
        color: _securityBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔒',
            style: TextStyle(fontSize: 13.ssp, height: 1.25),
          ),
          SizedBox(width: 10.sw),
          Expanded(
            child: Text(
              'Hand only to the named recipient after ID, signature & OTP. No verify = return to vendor.',
              style: TextStyle(
                fontSize: 12.ssp,
                fontWeight: FontWeight.w600,
                color: _securityText,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48.sh,
            child: Material(
              color: const Color(0xFFFFF8F3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFF5A623), width: 1.2),
              ),
              child: InkWell(
                onTap: () => Navigator.pushNamed(
                  context,
                  RouteNames.reportAtDropoff,
                  arguments: {
                    'orderId': order.orderId,
                    'customerName': order.customerName,
                  },
                ),
                borderRadius: BorderRadius.circular(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flag_outlined, color: _orange, size: 18.ssp),
                    SizedBox(width: 6.sw),
                    Text(
                      'Report',
                      style: TextStyle(
                        fontSize: 15.ssp,
                        fontWeight: FontWeight.w700,
                        color: _orange,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 10.sw),
        Expanded(
          child: SizedBox(
            height: 48.sh,
            child: Material(
              color: _textPrimary,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => MapService.openNavigationOrShowError(
                  context,
                  address: order.customerAddress,
                ),
                borderRadius: BorderRadius.circular(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.near_me, color: _white, size: 18.ssp),
                    SizedBox(width: 6.sw),
                    Text(
                      'Navigate',
                      style: TextStyle(
                        fontSize: 15.ssp,
                        fontWeight: FontWeight.w700,
                        color: _white,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
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
          onTap: () => Navigator.pushNamed(
            context,
            RouteNames.secureDeliveryLuxury,
            arguments: order,
          ),
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Text(
              'Arrived at customer',
              style: TextStyle(
                fontSize: 15.ssp,
                fontWeight: FontWeight.w700,
                color: _white,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

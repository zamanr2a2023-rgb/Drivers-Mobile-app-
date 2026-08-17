import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/services/map_service.dart';
import 'package:yjeek_driver/core/utils/app_helpers.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_order.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_shared.dart';
import 'package:yjeek_driver/routes/route_names.dart';

/// “Deliver to customer” screen for scheduled On Track deliveries.
/// Arrived calls `POST /drivers/jobs/:jobId/arrive-customer`.
class ScheduledDeliverToCustomerScreen extends StatelessWidget {
  const ScheduledDeliverToCustomerScreen({
    super.key,
    required this.order,
  });

  final ScheduledDeliveryOrder order;

  static const Color _headerGreen = Color(0xFF4DB04F);
  static const Color _screenBg = Color(0xFFF4F8F2);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF9E9E9E);
  static const Color _cardBorder = Color(0xFFE0E0E0);
  static const Color _prepaidBg = Color(0xFFE8F5E9);
  static const Color _prepaidHeading = Color(0xFF2E7D32);
  static const Color _reportText = Color(0xFFCFE3D5);
  static const Color _codBg = Color(0xFFFFF3E8);
  static const Color _codOrange = Color(0xFFE67E22);
  static const Color _codOrangeDark = Color(0xFFD35400);
  static const String _cashIconAsset =
      'assets/images/cash_on_delivery_icon.png';

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
                          _buildDropOffCard(),
                          SizedBox(height: 12.sh),
                          order.isPrepaid
                              ? _buildPrepaidCard()
                              : _buildCashCard(),
                          SizedBox(height: 14.sh),
                          scheduledReportNavigateRow(
                            onReport: () => Navigator.pushNamed(
                              context,
                              RouteNames.reportAtDropoff,
                              arguments: {
                                'orderId': order.orderId,
                                'customerName': order.customerName,
                              },
                            ),
                            onNavigate: () =>
                                MapService.openNavigationOrShowError(
                              context,
                              address: order.customerAddress,
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
                  'Deliver to customer',
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
          Material(
            color: Colors.transparent,
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
          ),
        ],
      ),
    );
  }

  Widget _buildDropOffCard() {
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
          Text(
            'Drop-off',
            style: TextStyle(
              fontSize: 14.ssp,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              height: 1.25,
            ),
          ),
          SizedBox(height: 14.sh),
          _buildDetailRow('Customer', order.customerName),
          SizedBox(height: 10.sh),
          _buildDetailRow('Phone', order.customerPhone),
          SizedBox(height: 10.sh),
          _buildDetailRow('Address', order.customerAddress),
          SizedBox(height: 10.sh),
          _buildDetailRow('Window', order.scheduledWindow),
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

  Widget _buildPrepaidCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.sw, vertical: 14.sh),
      decoration: BoxDecoration(
        color: _prepaidBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_box_outlined, color: _prepaidHeading, size: 20.ssp),
          SizedBox(width: 10.sw),
          Expanded(
            child: Text(
              'Prepaid order — no cash to collect.',
              style: TextStyle(
                fontSize: 14.ssp,
                fontWeight: FontWeight.w600,
                color: _prepaidHeading,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.sw, vertical: 14.sh),
      decoration: BoxDecoration(
        color: _codBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1.sh),
            child: SizedBox(
              width: 22,
              height: 13,
              child: Image.asset(
                _cashIconAsset,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.payments_outlined,
                  color: _codOrange,
                  size: 22.ssp,
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
                  'Collect cash on delivery',
                  style: TextStyle(
                    fontSize: 14.ssp,
                    fontWeight: FontWeight.w700,
                    color: _codOrangeDark,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 3.sh),
                Text(
                  'Hand the order, collect ${order.cashAmount ?? ''}',
                  style: TextStyle(
                    fontSize: 13.ssp,
                    fontWeight: FontWeight.w400,
                    color: _codOrange,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrivedButton(BuildContext context) {
    final isArriving = context.watch<OrderProvider>().isArrivingAtCustomer;

    return SizedBox(
      width: double.infinity,
      height: 52.sh,
      child: Material(
        color: _headerGreen,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: isArriving ? null : () => _arriveAtCustomer(context),
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
                    'Arrived at customer',
                    style: TextStyle(
                      fontSize: 16.ssp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _arriveAtCustomer(BuildContext context) async {
    final provider = context.read<OrderProvider>();
    if (provider.isArrivingAtCustomer) return;

    var next = order;
    final jobId = scheduledLiveJobId(order, provider);

    if (isScheduledLiveJobId(jobId)) {
      final job = provider.currentJobDetail;
      if (job != null && job.id == jobId && job.isPickupPhase) {
        AppHelpers.showSnackBar(
          context,
          'Pick up the order before arriving at the customer',
          isError: true,
        );
        return;
      }

      final success = await provider.arriveAtCustomer(jobId);
      if (!context.mounted) return;

      if (!success) {
        AppHelpers.showSnackBar(
          context,
          provider.arriveCustomerError ?? 'Failed to mark arrived at customer',
          isError: true,
        );
        return;
      }

      next = scheduledOrderFromJob(next, provider.currentJobDetail);
    }

    if (!context.mounted) return;
    Navigator.pushNamed(
      context,
      RouteNames.scheduledCompleteDelivery,
      arguments: next,
    );
  }
}

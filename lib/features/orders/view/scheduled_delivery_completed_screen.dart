import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/features/orders/model/job_complete_model.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_order.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_shared.dart';
import 'package:yjeek_driver/routes/route_names.dart';

/// Delivery completed success screen for scheduled deliveries.
class ScheduledDeliveryCompletedScreen extends StatelessWidget {
  const ScheduledDeliveryCompletedScreen({
    super.key,
    required this.order,
  });

  final ScheduledDeliveryOrder order;

  static const Color _white = Color(0xFFFFFFFF);
  static const Color _screenBg = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF6B7B6E);
  static const Color _successGreen = Color(0xFF4CAF50);
  static const Color _earningsCardBg = Color(0xFFE8F5E9);
  static const Color _earningsGreen = Color(0xFF0F4D27);
  static const Color _earningsSubGreen = Color(0xFF2E7D32);
  static const Color _summaryBorder = Color(0xFFE0E0E0);
  static const Color _divider = Color(0xFFE8E8E8);
  static const Color _buttonGreen = Color(0xFF4CAF50);

  static const ScheduledDeliveryOrder _nextRestrictedLuxuryOrder =
      ScheduledDeliveryOrder(
    orderId: '#YJK-...52',
    vendorName: 'Sharaf DG · Luxury counter',
    vendorAddress: 'Seef · Bldg 210, Floor 2',
    category: 'Luxury · high-value',
    customerName: 'Sara A.',
    customerPhone: '+973 3300 0000',
    customerAddress: 'Adliya · Bldg 23, Road 2825',
    scheduledWindow: 'Today · 6–8 PM',
    pickupDeadlineNotice:
        'High-value order. Collect the sealed box, confirm the tamper seal & serial before leaving.',
    distance: '1.4 km',
    eta: '~6 min',
    items: [
      ScheduledOrderItem(quantity: '1×', name: 'Sealed luxury item'),
    ],
    isFragileHighValue: true,
    paymentType: ScheduledPaymentType.prepaid,
    earnings: '4.500',
    tip: '0.000',
    totalDeliveryTime: '26 min',
    deliveryDistance: '4.2 km',
    deliveryEta: '~18 min',
    orderTypeLabel: 'Scheduled · Luxury',
    cardRouteLabel: 'Sharaf DG → Adliya',
    cardStatusLine: 'Restricted high-value delivery',
  );

  bool get _isRestrictedLuxuryCompletion {
    final category = order.category.toLowerCase();
    final type = order.orderTypeLabel.toLowerCase();
    final status = order.cardStatusLine.toLowerCase();
    return order.isFragileHighValue ||
        category.contains('luxury') ||
        category.contains('pharmacy') ||
        type.contains('luxury') ||
        status.contains('restricted');
  }

  void _findNextOrder(BuildContext context) {
    final provider = context.read<OrderProvider>();
    provider.loadScheduledOnTrackJobsBoard();
    provider.loadScheduledCompletedJobsBoard();

    if (order.hasLiveJobId || !_isRestrictedLuxuryCompletion) {
      scheduledReturnToOnTrack(context);
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      RouteNames.goToVendorScheduled,
      arguments: _nextRestrictedLuxuryOrder,
    );
  }

  JobCompleteSummary? _summary(BuildContext context) {
    return context.watch<OrderProvider>().lastCompleteResult?.summary;
  }

  @override
  Widget build(BuildContext context) {
    ScheduledDeliveryScale.update(MediaQuery.sizeOf(context));
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
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.sw),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 28.sh),
                      _buildSuccessSection(),
                      SizedBox(height: 22.sh),
                      _buildEarningsCard(context),
                      SizedBox(height: 12.sh),
                      _buildSummaryCard(context),
                      const Spacer(),
                      SizedBox(height: 28.sh),
                      _buildFindNextOrderButton(context),
                      SizedBox(height: 20.sh + bottomInset),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: scheduledBottomNav(context),
        ),
      ),
    );
  }

  Widget _buildSuccessSection() {
    return Column(
      children: [
        Center(
          child: Container(
            width: 72.sw,
            height: 72.sw,
            decoration: const BoxDecoration(
              color: _successGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: _white,
              size: 40.ssp,
            ),
          ),
        ),
        SizedBox(height: 16.sh),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Delivery completed 🎉',
            textAlign: TextAlign.start,
            style: TextStyle(
              fontSize: 20.ssp,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              height: 1.2,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsCard(BuildContext context) {
    final summary = _summary(context);
    final earnings = summary?.earningsAddedLabel ?? order.earnings;
    final tip = summary?.tipAmountLabel ?? order.tip;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.sw, vertical: 18.sh),
      decoration: BoxDecoration(
        color: _earningsCardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '+ BHD $earnings',
            style: TextStyle(
              fontSize: 26.ssp,
              fontWeight: FontWeight.w700,
              color: _earningsGreen,
              height: 1.1,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 6.sh),
          Text(
            'Added to today · incl. BHD $tip tip',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.ssp,
              fontWeight: FontWeight.w500,
              color: _earningsSubGreen,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final summary = _summary(context);
    final distance = summary?.distanceLabel ?? order.deliveryDistance;
    final time = summary?.durationLabel ?? order.totalDeliveryTime;
    final typeLabel = summary?.deliveryTypeLabel;
    final type =
        (typeLabel != null && typeLabel != '—') ? typeLabel : order.orderTypeLabel;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 16.sh),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _summaryBorder),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _buildSummaryColumn(
                distance,
                'Distance',
              ),
            ),
            Container(width: 1, color: _divider),
            Expanded(
              child: _buildSummaryColumn(
                time,
                'Time',
              ),
            ),
            Container(width: 1, color: _divider),
            Expanded(
              child: _buildSummaryColumn(
                type,
                'Type',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryColumn(String value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.ssp,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            height: 1.2,
          ),
        ),
        SizedBox(height: 4.sh),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.ssp,
            fontWeight: FontWeight.w500,
            color: _textMuted,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildFindNextOrderButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 49.sh,
      child: Material(
        color: _buttonGreen,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: () => _findNextOrder(context),
          borderRadius: BorderRadius.circular(13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.near_me_rounded, color: _white, size: 20.ssp),
              SizedBox(width: 8.sw),
              Text(
                'Find next order',
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
    );
  }
}

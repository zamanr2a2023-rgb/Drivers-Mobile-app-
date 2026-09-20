import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_order.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_shared.dart';

/// Delivery completed success screen for Scheduled Vape age-verified deliveries.
class ScheduledVapeDeliveryCompletedScreen extends StatelessWidget {
  const ScheduledVapeDeliveryCompletedScreen({
    super.key,
    required this.order,
  });

  final ScheduledDeliveryOrder order;

  static const Color _headerGreen = Color(0xFF4DB04F);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _screenBg = Color(0xFFF4F8F2);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF9E9E9E);
  static const Color _successCircleBg = Color(0xFFE8F5E9);
  static const Color _successCheck = Color(0xFF2E7D32);
  static const Color _summaryBorder = Color(0xFFE0E0E0);
  static const Color _verificationGreen = Color(0xFF4DB04F);

  String get _orderTypeLabel {
    if (order.orderTypeLabel.toLowerCase().contains('vape')) {
      return order.orderTypeLabel;
    }
    return 'Scheduled · Vape';
  }

  void _openNextRestrictedLuxuryOrder(BuildContext context) {
    scheduledReturnToOnTrack(context);
  }

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
        canPop: true,
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
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16.sw,
                    24.sh,
                    16.sw,
                    16.sh + bottomInset,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSuccessIcon(),
                      SizedBox(height: 20.sh),
                      _buildEarningsSection(),
                      SizedBox(height: 16.sh),
                      _buildSummaryCard(),
                      SizedBox(height: 32.sh),
                      _buildFindNextOrderButton(context),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _headerGreen,
      padding: EdgeInsets.fromLTRB(12.sw, 10.sh, 12.sw, 10.sh),
      child: Row(
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
            child: Text(
              'Delivery completed 🎉',
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 19.ssp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),
          SizedBox(width: 36.sw),
        ],
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Center(
      child: Container(
        width: 72.sw,
        height: 72.sw,
        decoration: const BoxDecoration(
          color: _successCircleBg,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_rounded,
          color: _successCheck,
          size: 40.ssp,
        ),
      ),
    );
  }

  Widget _buildEarningsSection() {
    return Column(
      children: [
        Text(
          '+ BHD ${order.earnings}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26.ssp,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            height: 1.1,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 6.sh),
        Text(
          'Age verified · proof of delivery photo saved',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.ssp,
            fontWeight: FontWeight.w400,
            color: _textMuted,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.sw, 14.sh, 14.sw, 14.sh),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _summaryBorder),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'Verification',
            '18+ confirmed ✓',
            valueColor: _verificationGreen,
          ),
          SizedBox(height: 10.sh),
          _buildSummaryRow('Distance', order.deliveryDistance),
          SizedBox(height: 10.sh),
          _buildSummaryRow('Type', _orderTypeLabel),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
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

  Widget _buildFindNextOrderButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.sh,
      child: Material(
        color: _headerGreen,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _openNextRestrictedLuxuryOrder(context),
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Text(
              'Find next order',
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

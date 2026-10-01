import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_order.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_shared.dart';

/// Delivery completed screen for restricted luxury scheduled deliveries.
class LuxuryDeliveryCompletedScreen extends StatelessWidget {
  const LuxuryDeliveryCompletedScreen({
    super.key,
    required this.order,
  });

  final ScheduledDeliveryOrder order;

  static const Color _headerGreen = Color(0xFF4DB04F);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _screenBg = Color(0xFFF4F8F2);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF7B8A7D);
  static const Color _successCircleBg = Color(0xFFE8F5E9);
  static const Color _successCheck = Color(0xFF2E7D32);
  static const Color _summaryBorder = Color(0xFFE0E0E0);
  static const Color _verifiedText = Color(0xFF4DB04F);

  String get _orderTypeLabel {
    if (order.orderTypeLabel.toLowerCase().contains('luxury')) {
      return order.orderTypeLabel;
    }
    return 'Scheduled · Luxury';
  }

  void _findNextOrder(BuildContext context) {
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
                    24.sh,
                    16.sw,
                    24.sh + bottomInset,
                  ),
                  children: [
                    _buildSuccessIcon(),
                    SizedBox(height: 20.sh),
                    _buildEarningsSection(),
                    SizedBox(height: 16.sh),
                    _buildSummaryCard(),
                    SizedBox(height: 20.sh),
                    _buildFindNextOrderButton(context),
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
            child: Text(
              'Delivery completed 🎉',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 19.ssp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),
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
          ),
        ),
        SizedBox(height: 10.sh),
        Text(
          'Secure proof of delivery · ID, OTP & signature saved',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.ssp,
            fontWeight: FontWeight.w500,
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
            'Recipient',
            '${order.customerName} · ID verified ✓',
            valueColor: _verifiedText,
          ),
          SizedBox(height: 10.sh),
          _buildSummaryRow(
            'Proof',
            'Signature + OTP + photo',
            valueColor: _verifiedText,
          ),
          SizedBox(height: 10.sh),
          _buildSummaryRow('Type', _orderTypeLabel),
          if (order.hasTip) ...[
            SizedBox(height: 10.sh),
            _buildSummaryRow('Tip', order.tipAmountLabel),
          ],
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
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => _findNextOrder(context),
          borderRadius: BorderRadius.circular(24),
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

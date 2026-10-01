import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';
import 'package:yjeek_driver/navigation/bottom_nav_bar.dart';
import 'package:yjeek_driver/navigation/orders_nav_signal.dart';
import 'package:yjeek_driver/routes/route_names.dart';

class _CashDeliveredScale {
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

extension _CashDeliveredUnits on num {
  double get w => _CashDeliveredScale.width(this);

  double get h => _CashDeliveredScale.height(this);

  double get sp => _CashDeliveredScale.width(this);
}

class CashDeliveryCompletedScreen extends StatelessWidget {
  const CashDeliveryCompletedScreen({super.key});

  static const Color _white = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF6B7B6E);
  static const Color _green = Color(0xFF4CAF50);
  static const Color _greenDark = Color(0xFF0F4D27);
  static const Color _earningsBg = Color(0xFFE8F5E9);
  static const Color _cardBorder = Color(0xFFE0E0E0);

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

  void _findNextOrder(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.mainNavigation,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    _CashDeliveredScale.update(MediaQuery.sizeOf(context));
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
      child: Scaffold(
        backgroundColor: _white,
        body: Column(
          children: [
            ColoredBox(
              color: _white,
              child: SizedBox(height: topInset),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          16.w,
                          42.h,
                          16.w,
                          16.h + bottomInset,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSuccessIcon(),
                              SizedBox(height: 22.h),
                              _buildTitle(),
                              SizedBox(height: 16.h),
                              _buildEarningsCard(context),
                              SizedBox(height: 18.h),
                              _buildSummaryCard(context),
                              const Spacer(),
                              _buildFindNextOrderButton(context),
                            ],
                          ),
                        ),
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

  Widget _buildSuccessIcon() {
    return Center(
      child: Container(
        width: 76.w,
        height: 76.w,
        decoration: const BoxDecoration(
          color: _green,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_rounded,
          color: _white,
          size: 44.sp,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Delivery completed 🎉',
      textAlign: TextAlign.left,
      style: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w800,
        color: _textPrimary,
        height: 1.2,
      ),
    );
  }

  Widget _buildEarningsCard(BuildContext context) {
    final summary = context.watch<OrderProvider>().lastCompleteResult?.summary;
    final earnings = summary?.earningsAddedLabel ?? '0.000';
    final tip = summary?.tipAmountLabel ?? '0.000';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: _earningsBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '+ BHD $earnings',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              color: _greenDark,
              height: 1.1,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            (double.tryParse(tip) ?? 0) > 0
                ? 'Added to today · incl. BHD $tip tip'
                : 'Added to today',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: _greenDark,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final summary = context.watch<OrderProvider>().lastCompleteResult?.summary;
    final distance = summary?.distanceLabel ?? '—';
    final time = summary?.durationLabel ?? '—';
    final cash = summary?.cashCollected != null
        ? 'BHD ${summary!.cashCollected!.toStringAsFixed(3)}'
        : '—';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Expanded(child: _SummaryMetric(value: distance, label: 'Distance')),
          const _SummaryDivider(),
          Expanded(child: _SummaryMetric(value: time, label: 'Time')),
          const _SummaryDivider(),
          Expanded(child: _SummaryMetric(value: 'Cash', label: cash)),
        ],
      ),
    );
  }

  Widget _buildFindNextOrderButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: Material(
        color: _green,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _findNextOrder(context),
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.near_me,
                  color: _white,
                  size: 18.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Find next order',
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

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
            color: CashDeliveryCompletedScreen._textPrimary,
            height: 1.2,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: CashDeliveryCompletedScreen._textMuted,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32.h,
      color: CashDeliveryCompletedScreen._cardBorder,
    );
  }
}

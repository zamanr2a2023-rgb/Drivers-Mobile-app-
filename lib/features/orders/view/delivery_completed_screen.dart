import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/features/dashboard/provider/dashboard_provider.dart';
import 'package:yjeek_driver/features/orders/model/job_complete_model.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';
import 'package:yjeek_driver/navigation/bottom_nav_bar.dart';
import 'package:yjeek_driver/navigation/orders_nav_signal.dart';
import 'package:yjeek_driver/routes/route_names.dart';

class _DeliveryCompletedScale {
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

extension _DeliveryCompletedUnits on num {
  double get w => _DeliveryCompletedScale.width(this);

  double get h => _DeliveryCompletedScale.height(this);

  double get sp => _DeliveryCompletedScale.width(this);
}

/// Delivery completed success screen — shows `POST .../complete` summary.
class DeliveryCompletedScreen extends StatelessWidget {
  const DeliveryCompletedScreen({super.key});

  static const Color _headerGreen = Color(0xFF4DB04F);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _screenBg = Color(0xFFF4F8F2);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF9E9E9E);
  static const Color _successCircleBg = Color(0xFFE8F5E9);
  static const Color _successCheck = Color(0xFF2E7D32);
  static const Color _summaryBorder = Color(0xFFE0E0E0);

  void _leaveAfterComplete(BuildContext context, {bool openInstant = false}) {
    if (openInstant) {
      OrdersNavSignal.openInstant();
    }
    OrdersNavSignal.closeEmbeddedDeliverFlow();
    context.read<OrderProvider>().loadInstantJobsBoard();
    context.read<DashboardProvider>().loadDashboard();
    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.mainNavigation,
      (route) => false,
    );
  }

  void _handleBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        _leaveAfterComplete(context);
        return;
      case 1:
        _leaveAfterComplete(context, openInstant: true);
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
    _leaveAfterComplete(context, openInstant: true);
  }

  JobCompleteSummary? _summary(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is JobCompleteResult) return args.summary;
    if (args is JobCompleteSummary) return args;
    return context.watch<OrderProvider>().lastCompleteResult?.summary;
  }

  @override
  Widget build(BuildContext context) {
    _DeliveryCompletedScale.update(MediaQuery.sizeOf(context));
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final summary = _summary(context);

    final earnings = summary?.earningsAddedLabel ?? '0.000';
    final tip = summary?.tipAmountLabel ?? '0.000';
    final distance = summary?.distanceLabel ?? '—';
    final time = summary?.durationLabel ?? '—';
    final type = summary?.deliveryTypeLabel ?? '—';

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
                    16.w,
                    24.h,
                    16.w,
                    16.h + bottomInset,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSuccessIcon(),
                      SizedBox(height: 20.h),
                      _buildEarningsSection(earnings: earnings, tip: tip),
                      SizedBox(height: 16.h),
                      _buildSummaryCard(
                        distance: distance,
                        time: time,
                        type: type,
                      ),
                      SizedBox(height: 32.h),
                      _buildFindNextOrderButton(context),
                    ],
                  ),
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
      color: _headerGreen,
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.22),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => _findNextOrder(context),
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 36.w,
                height: 36.w,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: 18.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Delivery completed 🎉',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 15.sp,
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
        width: 72.w,
        height: 72.w,
        decoration: const BoxDecoration(
          color: _successCircleBg,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_rounded,
          color: _successCheck,
          size: 40.sp,
        ),
      ),
    );
  }

  Widget _buildEarningsSection({
    required String earnings,
    required String tip,
  }) {
    return Column(
      children: [
        Text(
          '+ BHD $earnings',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            height: 1.1,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Added to today · incl. BHD $tip tip',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w400,
            color: _textMuted,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String distance,
    required String time,
    required String type,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _summaryBorder),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Distance', distance),
          SizedBox(height: 10.h),
          _buildSummaryRow('Time', time),
          SizedBox(height: 10.h),
          _buildSummaryRow('Type', type),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w400,
            color: _textMuted,
            height: 1.3,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
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
      height: 52.h,
      child: Material(
        color: _headerGreen,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _findNextOrder(context),
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Text(
              'Find next order',
              style: TextStyle(
                fontSize: 15.sp,
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

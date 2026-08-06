import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/widgets/app_google_map.dart';
import 'package:yjeek_driver/features/dashboard/provider/dashboard_provider.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';
import 'package:yjeek_driver/navigation/orders_nav_signal.dart';
import 'package:yjeek_driver/routes/route_names.dart';

/// Home UI matched to Figma references.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Figma palette (local to this screen only)
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _subtitleColor = Color(0xFF757575);
  static const Color _nameChipBg = Color(0xFFE8F5E9);
  static const Color _nameChipText = Color(0xFF2E7D32);
  static const Color _offlineChipBg = Color(0xFFF2F2F2);
  static const Color _offlineDot = Color(0xFF9E9E9E);
  static const Color _offlineText = Color(0xFF757575);
  static const Color _buttonGreen = Color(0xFF4CAF50);
  static const Color _viewGreen = Color(0xFF4CAF50);
  static const Color _cardBorder = Color(0xFFE0E0E0);
  static const String _scheduledCalendarIcon =
      'assets/images/calendar_jul_17.png';
  static const String _earningsStatIcon = 'assets/images/earnings.png';

  // Online Home colors sampled from the supplied Figma screenshot.
  static const Color _onlineBg = Color(0xFFFFFFFF);
  static const Color _onlineText = Color(0xFF1A1A1A);
  static const Color _onlineMuted = Color(0xFF6F7B6F);
  static const Color _onlineGreen = Color(0xFF4CAF50);
  static const Color _onlineGreenDark = Color(0xFF2E7D32);
  static const Color _onlineGreenPill = Color(0xFFE8F4DF);
  static const Color _onlineBalanceBg = Color(0xFF1A1A1A);
  static const Color _onlineNotificationRed = Color(0xFFFF3737);
  static const Color _onlineAutoAcceptBg = Color(0xFFFFF2D9);
  static const Color _onlineAutoAcceptBorder = Color(0xFFFFD47D);
  static const Color _onlineEnableOrange = Color(0xFFD45100);
  static const Color _onlineBoltFill = Color(0xFFFFC400);
  static const Color _onlineBoltStroke = Color(0xFFFF9800);
  static const Color _onlineScheduledBorder = Color(0xFFE2E8E1);
  static const Color _onlineScheduledIconBg = Color(0xFFEAF9EF);
  static const Color _onlineStatBg = Color(0xFFF3F7F2);

  Timer? _offerPollTimer;
  String? _presentedOfferId;
  bool _openingOffer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
    });
  }

  @override
  void dispose() {
    _offerPollTimer?.cancel();
    super.dispose();
  }

  void _syncOfferPolling(bool online) {
    if (!online) {
      _offerPollTimer?.cancel();
      _offerPollTimer = null;
      _presentedOfferId = null;
      return;
    }
    if (_offerPollTimer != null) return;
    _offerPollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollIncomingOffers(),
    );
    _pollIncomingOffers();
  }

  Future<void> _pollIncomingOffers() async {
    if (!mounted || _openingOffer) return;
    final dashboard = context.read<DashboardProvider>();
    if (!dashboard.isOnline) return;

    final orders = context.read<OrderProvider>();
    await orders.loadJobOffers();
    if (!mounted) return;

    final offer = orders.currentOffer;
    if (offer == null) {
      _presentedOfferId = null;
      return;
    }
    if (_presentedOfferId == offer.id) return;

    final routeName = ModalRoute.of(context)?.settings.name;
    if (routeName == RouteNames.newRequest ||
        routeName == RouteNames.orderDeliveryNewRequest) {
      _presentedOfferId = offer.id;
      return;
    }

    _presentedOfferId = offer.id;
    _openingOffer = true;
    try {
      await Navigator.pushNamed(context, RouteNames.newRequest);
    } finally {
      _openingOffer = false;
      // Allow re-present if still offered after closing.
      if (mounted) _presentedOfferId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    _syncOfferPolling(dashboard.isOnline);

    if (dashboard.isOnline) {
      return _buildOnlineHome(context, dashboard);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: RefreshIndicator(
            color: _buttonGreen,
            onRefresh: () => context.read<DashboardProvider>().loadDashboard(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Fit content to viewport — map absorbs remaining height.
                const headerBlock = 52.0;
                const bannerBlock = 60.0;
                const bottomBlock = 248.0;
                final mapHeight = (constraints.maxHeight -
                        headerBlock -
                        bannerBlock -
                        bottomBlock)
                    .clamp(200.0, 480.0);

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, dashboard),
                        const SizedBox(height: 12),
                        _buildScheduledBanner(context, dashboard),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: mapHeight,
                          width: double.infinity,
                          child: const AppGoogleMap(),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "You're offline",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: _textDark,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Go online to start receiving delivery requests near you.',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: _subtitleColor,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildStatsRow(dashboard),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: dashboard.isLoading
                                      ? null
                                      : () async {
                                          await context
                                              .read<DashboardProvider>()
                                              .toggleOnlineStatus();
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _buttonGreen,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    disabledBackgroundColor:
                                        _buttonGreen.withValues(alpha: 0.6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.bolt_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Go online',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineHome(
    BuildContext context,
    DashboardProvider dashboard,
  ) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: _onlineBg,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _onlineBg,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOnlineHeader(context, dashboard),
              const SizedBox(height: 18),
              _buildOnlineAutoAcceptCard(context, dashboard),
              const SizedBox(height: 10),
              _buildOnlineScheduledCard(context, dashboard),
              const SizedBox(height: 4),
              // Keep GoogleMap outside scrollables — iOS Platform Views often
              // show only the Google logo (blank tiles) inside SingleChildScrollView.
              const Expanded(child: AppGoogleMap()),
              _buildOnlineSummary(context, dashboard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineHeader(
    BuildContext context,
    DashboardProvider dashboard,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    _OnlinePill(
                      color: _onlineGreenPill,
                      horizontalPadding: 12,
                      child: Text(
                        dashboard.driverName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _onlineGreenDark,
                          height: 1.05,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const _OnlinePill(
                      color: _onlineGreenPill,
                      horizontalPadding: 12,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 8,
                            height: 8,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: _onlineGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "You're online",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _onlineGreenDark,
                              height: 1.05,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _OnlinePill(
                      color: _onlineBalanceBg,
                      horizontalPadding: 11,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 13,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _onlineBg,
                                width: 1.8,
                              ),
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                            child: Container(
                              width: 4.5,
                              height: 4.5,
                              decoration: const BoxDecoration(
                                color: _onlineBg,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dashboard.walletBalanceLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _onlineBg,
                              height: 1.05,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, RouteNames.notifications),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 32,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      size: 30,
                      color: Color(0xFF2D211B),
                    ),
                    if (dashboard.hasUnreadNotifications)
                      const Positioned(
                        right: 1,
                        top: 7,
                        child: SizedBox(
                          width: 9,
                          height: 9,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _onlineNotificationRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineAutoAcceptCard(
    BuildContext context,
    DashboardProvider dashboard,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 55,
        padding: const EdgeInsets.fromLTRB(13, 8, 12, 8),
        decoration: BoxDecoration(
          color: _onlineAutoAcceptBg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _onlineAutoAcceptBorder, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 35,
              height: 17,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _onlineBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Center(
                child: _OnlineBoltIcon(
                  width: 15,
                  height: 17,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dashboard.autoAcceptTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _onlineText,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dashboard.autoAcceptSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: _onlineMuted,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: _onlineEnableOrange,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: dashboard.isUpdatingAutoAccept
                    ? null
                    : () async {
                        final ok = await context
                            .read<DashboardProvider>()
                            .setAutoAcceptEnabled(true);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'Auto-Accept enabled'
                                  : (context
                                          .read<DashboardProvider>()
                                          .error ??
                                      'Could not enable Auto-Accept'),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                borderRadius: BorderRadius.circular(16),
                child: const SizedBox(
                  width: 70,
                  height: 32,
                  child: Center(
                    child: Text(
                      'Enable',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _onlineBg,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineScheduledCard(
    BuildContext context,
    DashboardProvider dashboard,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: _onlineBg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => OrdersNavSignal.openScheduled(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 40,
            padding: const EdgeInsets.fromLTRB(13, 0, 12, 0),
            decoration: BoxDecoration(
              color: _onlineBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _onlineScheduledBorder, width: 1),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 35,
                  height: 17,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _onlineScheduledIconBg,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Image.asset(
                      _scheduledCalendarIcon,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.calendar_today,
                        size: 13,
                        color: _onlineText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    dashboard.scheduledOrdersLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _onlineText,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'View',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5BC970),
                    height: 1,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFF5BC970),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineSummary(
    BuildContext context,
    DashboardProvider dashboard,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  "Today's summary",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _onlineText,
                    height: 1,
                  ),
                ),
              ),
              Text(
                'Fri 12 Jun',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _onlineMuted,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 62,
                  child: _OnlineHomeStatCard(
                    icon: const Icon(
                      Icons.arrow_upward_rounded,
                      size: 21,
                      color: _onlineGreenDark,
                    ),
                    value: '${dashboard.tripsToday}',
                    label: 'Orders',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 62,
                  child: _OnlineHomeStatCard(
                    icon: const _HomeAssetIcon(
                      assetPath: _earningsStatIcon,
                      width: 20,
                      height: 14,
                      color: _onlineGreenDark,
                    ),
                    value: dashboard.todayEarningsLabel,
                    label: 'Earnings',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 62,
                  child: _OnlineHomeStatCard(
                    icon: const Icon(
                      Icons.access_time_rounded,
                      size: 19,
                      color: _onlineGreenDark,
                    ),
                    value: dashboard.onlineDurationLabel,
                    label: 'Online',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: dashboard.isLoading
                  ? null
                  : () async {
                      await context
                          .read<DashboardProvider>()
                          .toggleOnlineStatus();
                    },
              style: OutlinedButton.styleFrom(
                backgroundColor: _onlineBg,
                foregroundColor: _onlineGreenDark,
                disabledForegroundColor:
                    _onlineGreenDark.withValues(alpha: 0.6),
                side: const BorderSide(color: _onlineGreen, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text(
                'Go offline',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _onlineGreenDark,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    DashboardProvider dashboard,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _nameChipBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              dashboard.driverName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _nameChipText,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: _offlineChipBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 7,
                  height: 7,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _offlineDot,
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  'Offline',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _offlineText,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, RouteNames.notifications),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    size: 26,
                    color: _textDark,
                  ),
                  if (dashboard.hasUnreadNotifications)
                    const Positioned(
                      right: 8,
                      top: 8,
                      child: SizedBox(
                        width: 8,
                        height: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFFE53935),
                            shape: BoxShape.circle,
                          ),
                        ),
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

  Widget _buildScheduledBanner(
    BuildContext context,
    DashboardProvider dashboard,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => OrdersNavSignal.openScheduled(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _cardBorder, width: 1),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  height: 16,
                  child: Image.asset(
                    _scheduledCalendarIcon,
                    width: 34,
                    height: 16,
                    fit: BoxFit.fill,
                    errorBuilder: (_, __, ___) => Container(
                      width: 34,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.calendar_today,
                        size: 10,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    dashboard.scheduledOrdersLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                ),
                const Text(
                  'View',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _viewGreen,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: _viewGreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(DashboardProvider dashboard) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 72,
            child: _HomeStatCard(
              icon: const Icon(
                Icons.arrow_upward_rounded,
                size: 16,
                color: Color(0xFF4CAF50),
              ),
              value: '${dashboard.tripsToday}',
              label: 'Trips today',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 72,
            child: _HomeStatCard(
              icon: const _HomeAssetIcon(
                assetPath: _earningsStatIcon,
                width: 18,
                height: 13,
                color: Color(0xFF4CAF50),
              ),
              value: dashboard.todayEarningsLabel,
              label: 'Earnings',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 72,
            child: _HomeStatCard(
              icon: const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: Color(0xFF4CAF50),
              ),
              value: dashboard.onlineDurationLabel,
              label: 'Online',
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeAssetIcon extends StatelessWidget {
  const _HomeAssetIcon({
    required this.assetPath,
    required this.width,
    required this.height,
    this.color,
  });

  final String assetPath;
  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      color: color,
      colorBlendMode: color != null ? BlendMode.srcIn : null,
      errorBuilder: (_, __, ___) => Icon(
        Icons.payments_outlined,
        size: width,
        color: const Color(0xFF4CAF50),
      ),
    );
  }
}

class _OnlinePill extends StatelessWidget {
  const _OnlinePill({
    required this.color,
    required this.child,
    this.horizontalPadding = 12,
  });

  final Color color;
  final Widget child;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 27),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _OnlineHomeStatCard extends StatelessWidget {
  const _OnlineHomeStatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final Widget icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
      decoration: BoxDecoration(
        color: _DashboardScreenState._onlineStatBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _DashboardScreenState._onlineText,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: _DashboardScreenState._onlineMuted,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineBoltIcon extends StatelessWidget {
  const _OnlineBoltIcon({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: const CustomPaint(painter: _OnlineBoltPainter()),
    );
  }
}

class _OnlineBoltPainter extends CustomPainter {
  const _OnlineBoltPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.68, size.height * 0.02)
      ..lineTo(size.width * 0.12, size.height * 0.56)
      ..lineTo(size.width * 0.47, size.height * 0.56)
      ..lineTo(size.width * 0.32, size.height * 0.98)
      ..lineTo(size.width * 0.90, size.height * 0.39)
      ..lineTo(size.width * 0.54, size.height * 0.39)
      ..close();

    final strokePaint = Paint()
      ..color = _DashboardScreenState._onlineBoltStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeJoin = StrokeJoin.miter
      ..strokeCap = StrokeCap.square;
    final fillPaint = Paint()
      ..color = _DashboardScreenState._onlineBoltFill
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HomeStatCard extends StatelessWidget {
  const _HomeStatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final Widget icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 5),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }
}

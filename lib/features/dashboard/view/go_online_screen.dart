import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/widgets/app_google_map.dart';
import 'package:yjeek_driver/features/dashboard/provider/dashboard_provider.dart';
import 'package:yjeek_driver/navigation/orders_nav_signal.dart';
import 'package:yjeek_driver/routes/route_names.dart';

class GoOnlineScreen extends StatelessWidget {
  const GoOnlineScreen({super.key});

  static const Color _textDark = Color(0xFF1E1E1E);
  static const Color _subtitleColor = Color(0xFF8A958A);
  static const Color _nameChipBg = Color(0xFFE8F6EA);
  static const Color _nameChipText = Color(0xFF2E7D32);
  static const Color _onlineChipBg = Color(0xFFE8F6EA);
  static const Color _balanceBg = Color(0xFF1E1E1E);
  static const Color _buttonGreen = Color(0xFF4CAF50);
  static const Color _viewGreen = Color(0xFF4CAF50);
  static const Color _cardBorder = Color(0xFFE6EBE6);
  static const Color _calendarCircleBg = Color(0xFFEAF6EC);
  static const Color _autoAcceptBg = Color(0xFFFFF3E8);
  static const Color _enableOrange = Color(0xFFD97706);
  static const Color _boltOrange = Color(0xFFF59E0B);
  static const Color _waitingBolt = Color(0xFFF59E0B);
  static const Color _statCardBg = Color(0xFFF3F7F3);
  static const String _scheduledCalendarIcon =
      'assets/images/calendar_jul_17.png';
  static const String _earningsStatIcon = 'assets/images/earnings.png';

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: ColoredBox(
        color: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 12),
                _buildAutoAcceptBanner(context),
                const SizedBox(height: 10),
                _buildScheduledBanner(context),
                const SizedBox(height: 12),
                _buildMapSection(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Today's summary",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _textDark,
                              ),
                            ),
                          ),
                          Text(
                            'Fri 12 Jun',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _subtitleColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildStatsRow(),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: dashboard.isLoading
                              ? null
                              : () async {
                                  await context
                                      .read<DashboardProvider>()
                                      .toggleOnlineStatus();
                                },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _buttonGreen,
                            side: const BorderSide(
                              color: _buttonGreen,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Go offline',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _buttonGreen,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: [
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: _nameChipBg,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Text(
                      'Ahmed Ali',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _nameChipText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: _onlineChipBg,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _buttonGreen,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "You're online",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _nameChipText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: _balanceBg,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'BHD 12.500',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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
            onTap: () => Navigator.pushNamed(context, RouteNames.notifications),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  size: 26,
                  color: _textDark,
                ),
                Positioned(
                  right: 1,
                  top: 1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoAcceptBanner(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final enabled = dashboard.isAutoAcceptEnabled;
    final updating = dashboard.isUpdatingAutoAccept;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
        decoration: BoxDecoration(
          color: _autoAcceptBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bolt,
                color: _boltOrange,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dashboard.autoAcceptTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dashboard.autoAcceptSubtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: _subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: _enableOrange,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: updating
                    ? null
                    : () async {
                        final provider = context.read<DashboardProvider>();
                        final ok = await provider
                            .setAutoAcceptEnabled(!enabled);
                        if (!context.mounted) return;
                        if (!ok) {
                          final message = provider.error ??
                              'Failed to update auto-accept';
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(message),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                        }
                      },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: updating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          enabled ? 'Disable' : 'Enable',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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

  Widget _buildScheduledBanner(BuildContext context) {
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
              border: Border.all(color: _cardBorder),
            ),
            child: Row(
              children: [
                // Light green horizontal pill (not a circle)
                Container(
                  width: 44,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _calendarCircleBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    _scheduledCalendarIcon,
                    width: 22,
                    height: 22,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: _textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    '2 scheduled orders today',
                    style: TextStyle(
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
                  Icons.chevron_right,
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

  Widget _buildMapSection() {
    return const SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppGoogleMap(showRecenterButton: true),
          Positioned(
            left: 16,
            right: 16,
            top: 12,
            child: _GoOnlineWaitingBanner(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: SizedBox(
            height: 78,
            child: _OnlineStatCard(
              icon: Icon(
                Icons.arrow_upward_rounded,
                size: 18,
                color: Color(0xFF4CAF50),
              ),
              value: '4',
              label: 'Orders',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 78,
            child: _OnlineStatCard(
              icon: Image.asset(
                _earningsStatIcon,
                width: 22,
                height: 15,
                fit: BoxFit.contain,
                color: const Color(0xFF4CAF50),
                colorBlendMode: BlendMode.srcIn,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.payments_outlined,
                  size: 18,
                  color: Color(0xFF4CAF50),
                ),
              ),
              value: 'BHD 12.50',
              label: 'Earnings',
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: SizedBox(
            height: 78,
            child: _OnlineStatCard(
              icon: Icon(
                Icons.access_time_rounded,
                size: 18,
                color: Color(0xFF4CAF50),
              ),
              value: '3h 20m',
              label: 'Online',
            ),
          ),
        ),
      ],
    );
  }
}

class _GoOnlineWaitingBanner extends StatelessWidget {
  const _GoOnlineWaitingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.bolt, color: GoOnlineScreen._waitingBolt, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waiting for requests...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: GoOnlineScreen._textDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Stay near busy areas for more orders',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: GoOnlineScreen._subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineStatCard extends StatelessWidget {
  const _OnlineStatCard({
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: GoOnlineScreen._statCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 6),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: GoOnlineScreen._textDark,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: GoOnlineScreen._subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/features/profile/view/doc_upload_ui.dart';
import 'package:yjeek_driver/features/settings/provider/settings_provider.dart';
import 'package:yjeek_driver/l10n/l10n.dart';
import 'package:yjeek_driver/services/api_service.dart';

/// DE1 · Earnings
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  int _selectedPeriod = 0; // 0 Today, 1 This week, 2 This month

  bool _isLoadingToday = false;
  bool _hasTodayData = false;
  bool _isLoadingWeekly = false;
  bool _hasWeeklyData = false;
  bool _isLoadingMonthly = false;
  bool _hasMonthlyData = false;

  // Today (daily) API fields.
  double _todayTotalEarnings = 0;
  int _todayTrips = 0;
  String _todayOnlineDurationLabel = '0m';
  double _todayTripFares = 0;
  double _todayTips = 0;
  double _todayIncentivesAndBonuses = 0;
  double _todayBreakdownTotal = 0;
  double _todayCodToSettle = 0;

  // Weekly (weekly) API fields.
  double _weeklyTotalEarnings = 0;
  int _weeklyTrips = 0;
  String _weeklyOnlineDurationLabel = '0m';
  double _weeklyTripFares = 0;
  double _weeklyTips = 0;
  double _weeklyIncentivesAndBonuses = 0;
  double _weeklyBreakdownTotal = 0;
  double _weeklyCodToSettle = 0;

  // Monthly (monthly) API fields.
  double _monthlyTotalEarnings = 0;
  int _monthlyTrips = 0;
  String _monthlyOnlineDurationLabel = '0m';
  double _monthlyTripFares = 0;
  double _monthlyTips = 0;
  double _monthlyIncentivesAndBonuses = 0;
  double _monthlyBreakdownTotal = 0;
  double _monthlyCodToSettle = 0;

  static const _periodKeys = ['Today', 'This week', 'This month'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_selectedPeriod == 0) {
        _ensureTodayLoaded();
      }
    });
  }

  Future<void> _ensureTodayLoaded() async {
    if (_hasTodayData || _isLoadingToday) return;

    setState(() => _isLoadingToday = true);
    try {
      final response =
          await ApiService.instance.get('/drivers/earnings?period=daily');

      if (response['success'] != true) {
        final message = response['message']?.toString().trim();
        throw ApiException(
          (message != null && message.isNotEmpty)
              ? message
              : 'Failed to load daily earnings',
        );
      }

      final data = response['data'];
      if (data is! Map) {
        throw ApiException('Invalid response from server');
      }

      final summaryRaw = data['summary'];
      final breakdownRaw = data['breakdown'];
      final walletRaw = data['wallet'];
      if (summaryRaw is! Map || breakdownRaw is! Map || walletRaw is! Map) {
        throw ApiException('Invalid response from server');
      }

      setState(() {
        _todayTotalEarnings = _asDouble(summaryRaw['totalEarnings']);
        _todayTrips = _asInt(summaryRaw['trips']);
        _todayOnlineDurationLabel =
            summaryRaw['onlineDurationLabel']?.toString() ?? '0m';

        _todayTripFares = _asDouble(breakdownRaw['tripFares']);
        _todayTips = _asDouble(breakdownRaw['tips']);
        _todayIncentivesAndBonuses =
            _asDouble(breakdownRaw['incentivesAndBonuses']);
        _todayBreakdownTotal = _asDouble(breakdownRaw['total']);

        _todayCodToSettle = _asDouble(walletRaw['codToSettle']);
        _hasTodayData = true;
      });
    } catch (_) {
      // Keep screen usable with existing hardcoded values (for non-today)
      // and 0s for today until the next successful refresh.
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingToday = false);
    }
  }

  Future<void> _ensureWeeklyLoaded() async {
    if (_hasWeeklyData || _isLoadingWeekly) return;

    setState(() => _isLoadingWeekly = true);
    try {
      final response =
          await ApiService.instance.get('/drivers/earnings?period=weekly');

      if (response['success'] != true) {
        final message = response['message']?.toString().trim();
        throw ApiException(
          (message != null && message.isNotEmpty)
              ? message
              : 'Failed to load weekly earnings',
        );
      }

      final data = response['data'];
      if (data is! Map) {
        throw ApiException('Invalid response from server');
      }

      final summaryRaw = data['summary'];
      final breakdownRaw = data['breakdown'];
      final walletRaw = data['wallet'];
      if (summaryRaw is! Map || breakdownRaw is! Map || walletRaw is! Map) {
        throw ApiException('Invalid response from server');
      }

      setState(() {
        _weeklyTotalEarnings = _asDouble(summaryRaw['totalEarnings']);
        _weeklyTrips = _asInt(summaryRaw['trips']);
        _weeklyOnlineDurationLabel =
            summaryRaw['onlineDurationLabel']?.toString() ?? '0m';

        _weeklyTripFares = _asDouble(breakdownRaw['tripFares']);
        _weeklyTips = _asDouble(breakdownRaw['tips']);
        _weeklyIncentivesAndBonuses =
            _asDouble(breakdownRaw['incentivesAndBonuses']);
        _weeklyBreakdownTotal = _asDouble(breakdownRaw['total']);

        _weeklyCodToSettle = _asDouble(walletRaw['codToSettle']);
        _hasWeeklyData = true;
      });
    } catch (_) {
      // Keep hardcoded values (for non-weekly UI) until the next refresh.
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingWeekly = false);
    }
  }

  Future<void> _ensureMonthlyLoaded() async {
    if (_hasMonthlyData || _isLoadingMonthly) return;

    setState(() => _isLoadingMonthly = true);
    try {
      final response =
          await ApiService.instance.get('/drivers/earnings?period=monthly');

      if (response['success'] != true) {
        final message = response['message']?.toString().trim();
        throw ApiException(
          (message != null && message.isNotEmpty)
              ? message
              : 'Failed to load monthly earnings',
        );
      }

      final data = response['data'];
      if (data is! Map) {
        throw ApiException('Invalid response from server');
      }

      final summaryRaw = data['summary'];
      final breakdownRaw = data['breakdown'];
      final walletRaw = data['wallet'];
      if (summaryRaw is! Map || breakdownRaw is! Map || walletRaw is! Map) {
        throw ApiException('Invalid response from server');
      }

      setState(() {
        _monthlyTotalEarnings = _asDouble(summaryRaw['totalEarnings']);
        _monthlyTrips = _asInt(summaryRaw['trips']);
        _monthlyOnlineDurationLabel =
            summaryRaw['onlineDurationLabel']?.toString() ?? '0m';

        _monthlyTripFares = _asDouble(breakdownRaw['tripFares']);
        _monthlyTips = _asDouble(breakdownRaw['tips']);
        _monthlyIncentivesAndBonuses =
            _asDouble(breakdownRaw['incentivesAndBonuses']);
        _monthlyBreakdownTotal = _asDouble(breakdownRaw['total']);

        _monthlyCodToSettle = _asDouble(walletRaw['codToSettle']);
        _hasMonthlyData = true;
      });
    } catch (_) {
      // Keep hardcoded values (for non-monthly UI) until the next refresh.
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingMonthly = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();
    return Scaffold(
      backgroundColor: DocColors.screenBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Text(
                L10n.tr('Earnings'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: DocColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSegmentedControl(),
                    const SizedBox(height: 14),
                    _buildSummaryCard(),
                    const SizedBox(height: 14),
                    _buildEstimateNote(),
                    const SizedBox(height: 14),
                    _buildBreakdownCard(),
                    const SizedBox(height: 14),
                    _buildCodCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEFE7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(_periodKeys.length, (i) {
          final selected = i == _selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () async {
                setState(() => _selectedPeriod = i);
                if (i == 0) await _ensureTodayLoaded();
                if (i == 1) await _ensureWeeklyLoaded();
                if (i == 2) await _ensureMonthlyLoaded();
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? DocColors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  L10n.tr(_periodKeys[i]),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? DocColors.textPrimary
                        : DocColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final isToday = _selectedPeriod == 0;
    final isWeekly = _selectedPeriod == 1;
    final isMonthly = _selectedPeriod == 2;
    final totalText = isToday
        ? (_hasTodayData ? _formatBhd3(_todayTotalEarnings) : 'BHD 86.400')
        : (isWeekly
            ? (_hasWeeklyData ? _formatBhd3(_weeklyTotalEarnings) : 'BHD 86.400')
            : (isMonthly
                ? (_hasMonthlyData
                    ? _formatBhd3(_monthlyTotalEarnings)
                    : 'BHD 86.400')
                : 'BHD 86.400'));
    final tripsText = isToday
        ? (_hasTodayData
            ? L10n.trParams('{count} trips', {'count': '$_todayTrips'})
            : L10n.trParams('{count} trips', {'count': '32'}))
        : (isWeekly
            ? (_hasWeeklyData
                ? L10n.trParams('{count} trips', {'count': '$_weeklyTrips'})
                : L10n.trParams('{count} trips', {'count': '32'}))
            : (isMonthly
                ? (_hasMonthlyData
                    ? L10n.trParams('{count} trips', {'count': '$_monthlyTrips'})
                    : L10n.trParams('{count} trips', {'count': '32'}))
                : L10n.trParams('{count} trips', {'count': '32'})));
    final onlineLabelText = isToday
        ? (_hasTodayData
            ? L10n.trParams('{duration} online',
                {'duration': _todayOnlineDurationLabel})
            : L10n.trParams('{duration} online', {'duration': '18h 20m'}))
        : (isWeekly
            ? (_hasWeeklyData
                ? L10n.trParams('{duration} online',
                    {'duration': _weeklyOnlineDurationLabel})
                : L10n.trParams('{duration} online', {'duration': '18h 20m'}))
            : (isMonthly
                ? (_hasMonthlyData
                    ? L10n.trParams('{duration} online',
                        {'duration': _monthlyOnlineDurationLabel})
                    : L10n.trParams('{duration} online', {'duration': '18h 20m'}))
                : L10n.trParams('{duration} online', {'duration': '18h 20m'})));
    final titleText = isToday
        ? L10n.tr('Today · earnings')
        : isWeekly
            ? L10n.tr('This week · earnings')
            : L10n.tr('This month · earnings');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DocColors.greenDeep,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFFCFE3D5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            totalText,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                tripsText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFCFE3D5),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '·',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFCFE3D5),
                  ),
                ),
              ),
              Text(
                onlineLabelText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFCFE3D5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstimateNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DocColors.infoBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ⓘ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: DocColors.infoText,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              L10n.tr(
                'Amounts shown are estimates and may not be final. Your earnings are confirmed after settlement.',
              ),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.35,
                color: DocColors.infoText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard() {
    final isToday = _selectedPeriod == 0;
    final isWeekly = _selectedPeriod == 1;
    final isMonthly = _selectedPeriod == 2;
    final hasToday = isToday && _hasTodayData;
    final hasWeekly = isWeekly && _hasWeeklyData;
    final hasMonthly = isMonthly && _hasMonthlyData;

    final tripFaresText = hasToday
        ? _formatBhd3(_todayTripFares)
        : (hasWeekly
            ? _formatBhd3(_weeklyTripFares)
            : (hasMonthly ? _formatBhd3(_monthlyTripFares) : 'BHD 72.000'));
    final tipsText = hasToday
        ? _formatBhd3(_todayTips)
        : (hasWeekly ? _formatBhd3(_weeklyTips) : (hasMonthly ? _formatBhd3(_monthlyTips) : 'BHD 6.400'));
    final incentivesText = hasToday
        ? _formatBhd3(_todayIncentivesAndBonuses)
        : (hasWeekly
            ? _formatBhd3(_weeklyIncentivesAndBonuses)
            : (hasMonthly
                ? _formatBhd3(_monthlyIncentivesAndBonuses)
                : 'BHD 8.000'));
    final totalText = hasToday
        ? _formatBhd3(_todayBreakdownTotal)
        : (hasWeekly
            ? _formatBhd3(_weeklyBreakdownTotal)
            : (hasMonthly ? _formatBhd3(_monthlyBreakdownTotal) : 'BHD 86.400'));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DocColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DocColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L10n.tr('Breakdown'),
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: DocColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _BreakdownRow(label: L10n.tr('Trip fares'), value: tripFaresText),
          const SizedBox(height: 10),
          _BreakdownRow(
            label: L10n.tr('Tips'),
            value: tipsText,
            valueColor: DocColors.greenDark,
          ),
          const SizedBox(height: 10),
          _BreakdownRow(
            label: L10n.tr('Incentives & bonuses'),
            value: incentivesText,
            valueColor: DocColors.greenDark,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: DocColors.cardBorder),
          const SizedBox(height: 12),
          _BreakdownRow(
            label: L10n.tr('Total'),
            value: totalText,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCodCard() {
    final isToday = _selectedPeriod == 0;
    final isWeekly = _selectedPeriod == 1;
    final isMonthly = _selectedPeriod == 2;
    final hasToday = isToday && _hasTodayData;
    final hasWeekly = isWeekly && _hasWeeklyData;
    final hasMonthly = isMonthly && _hasMonthlyData;

    final codText = hasToday
        ? _formatBhd3(_todayCodToSettle)
        : (hasWeekly
            ? _formatBhd3(_weeklyCodToSettle)
            : (hasMonthly ? _formatBhd3(_monthlyCodToSettle) : 'BHD 24.500'));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DocColors.warnBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L10n.tr('COD to settle'),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9A6A1E),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  codText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: DocColors.warnText,
                  ),
                ),
              ],
            ),
          ),
          const _CodIcon(),
        ],
      ),
    );
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _formatBhd3(double amount) {
    return 'BHD ${amount.toStringAsFixed(3)}';
  }
}

/// Rounded square with a centered circle, matching the design's COD icon.
class _CodIcon extends StatelessWidget {
  const _CodIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: DocColors.warnText, width: 2),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          border: Border.all(color: DocColors.warnText, width: 2),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: bold ? DocColors.textPrimary : DocColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? DocColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

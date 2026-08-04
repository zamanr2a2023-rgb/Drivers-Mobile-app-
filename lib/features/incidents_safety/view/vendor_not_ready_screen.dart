import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/utils/app_helpers.dart';
import 'package:yjeek_driver/features/incidents_safety/view/incident_ui.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';

/// DR2 · Vendor not ready / report wait at vendor
class VendorNotReadyScreen extends StatefulWidget {
  const VendorNotReadyScreen({
    super.key,
    this.args = const IncidentContextArgs(),
  });

  final IncidentContextArgs args;

  @override
  State<VendorNotReadyScreen> createState() => _VendorNotReadyScreenState();
}

class _VendorNotReadyScreenState extends State<VendorNotReadyScreen> {
  late Duration _elapsed;
  Timer? _timer;
  String? _waitStatusMessage;

  @override
  void initState() {
    super.initState();
    _elapsed = const Duration(minutes: 4, seconds: 12);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timerText {
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String? _resolveJobId(OrderProvider orders) {
    final detailId = orders.currentJobDetail?.id.trim();
    if (detailId != null && detailId.isNotEmpty) return detailId;
    if (orders.instantActiveJobs.isNotEmpty) {
      final activeId = orders.instantActiveJobs.first.id.trim();
      if (activeId.isNotEmpty) return activeId;
    }
    return null;
  }

  void _applyWaitLabel(String? waitingLabel, int? waitingSec) {
    if (waitingSec != null && waitingSec >= 0) {
      _elapsed = Duration(seconds: waitingSec);
      return;
    }
    final label = waitingLabel?.trim() ?? '';
    if (label.isEmpty) return;
    final parts = label.split(':');
    if (parts.length != 2) return;
    final minutes = int.tryParse(parts[0]);
    final seconds = int.tryParse(parts[1]);
    if (minutes == null || seconds == null) return;
    _elapsed = Duration(minutes: minutes, seconds: seconds);
  }

  Future<void> _reportWaitToDispatch() async {
    final orders = context.read<OrderProvider>();
    if (orders.isReportingWait) return;

    final jobId = _resolveJobId(orders);
    if (jobId == null) {
      AppHelpers.showSnackBar(
        context,
        'No active job found',
        isError: true,
      );
      return;
    }

    final result = await orders.reportWaitAtVendor(jobId);
    if (!mounted) return;

    if (result != null) {
      setState(() {
        _applyWaitLabel(
          result.wait?.waitingLabel,
          result.wait?.waitingSec,
        );
        _waitStatusMessage = result.wait?.message;
      });
      showIncidentSnack(context, result.message);
      Navigator.maybePop(context);
      return;
    }

    AppHelpers.showSnackBar(
      context,
      orders.reportWaitError ?? 'Failed to report wait',
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isReporting = context.watch<OrderProvider>().isReportingWait;

    return Scaffold(
      backgroundColor: IncidentColors.screenBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            IncidentHeader(
              title: 'Order not ready',
              subtitle: widget.args.pickupSubtitle,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  IncidentCard(
                    child: Column(
                      children: [
                        const Text(
                          'You’ve been waiting',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: IncidentColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _timerText,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            color: IncidentColors.timerOrange,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _waitStatusMessage ?? 'Auto-flagged at 4 min',
                          style: const TextStyle(
                            fontSize: 11,
                            color: IncidentColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const IncidentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What happens when you report',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: IncidentColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '• Dispatch contacts the vendor and logs the wait\n'
                          '• Your wait time is excluded from your RPI',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: IncidentColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  IncidentPrimaryButton(
                    label: isReporting
                        ? 'Reporting…'
                        : 'Report wait to dispatch',
                    onPressed: isReporting ? null : _reportWaitToDispatch,
                  ),
                  const SizedBox(height: 10),
                  IncidentOutlinedButton(
                    label: 'Keep waiting',
                    onPressed:
                        isReporting ? null : () => Navigator.maybePop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

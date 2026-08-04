import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yjeek_driver/core/constants/app_assets.dart';
import 'package:yjeek_driver/core/utils/app_helpers.dart';
import 'package:yjeek_driver/features/incidents_safety/view/incident_ui.dart';
import 'package:yjeek_driver/features/orders/model/contact_attempts_model.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';
import 'package:yjeek_driver/routes/route_names.dart';

/// DR4 · Can’t reach customer
class CantReachCustomerScreen extends StatefulWidget {
  const CantReachCustomerScreen({
    super.key,
    this.args = const IncidentContextArgs(),
  });

  final IncidentContextArgs args;

  @override
  State<CantReachCustomerScreen> createState() =>
      _CantReachCustomerScreenState();
}

class _CantReachCustomerScreenState extends State<CantReachCustomerScreen> {
  late Duration _waiting;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _waiting = const Duration(minutes: 3, seconds: 10);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _waiting += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timerText {
    final m = _waiting.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _waiting.inSeconds.remainder(60).toString().padLeft(2, '0');
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

  Future<void> _logCallAttempt() async {
    final orders = context.read<OrderProvider>();
    if (orders.isLoggingContactAttempt) return;

    final jobId = _resolveJobId(orders);
    if (jobId == null) {
      AppHelpers.showSnackBar(
        context,
        'No active job found',
        isError: true,
      );
      return;
    }

    final phone = orders.currentJobDetail?.order.customer.displayPhone;
    if (phone != null && phone.trim().isNotEmpty && phone != '—') {
      final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
      try {
        await launchUrl(uri);
      } catch (_) {
        // Still log the attempt even if dialer fails.
      }
    }

    final result = await orders.logContactAttempt(jobId: jobId, type: 'CALL');
    if (!mounted) return;

    if (result != null) {
      showIncidentSnack(
        context,
        result.message ?? 'Call attempt logged',
      );
      return;
    }

    AppHelpers.showSnackBar(
      context,
      orders.contactAttemptError ?? 'Failed to log contact attempt',
      isError: true,
    );
  }

  Future<void> _markUnableToDeliver() async {
    final orders = context.read<OrderProvider>();
    if (orders.isMarkingUnableToDeliver) return;

    final jobId = _resolveJobId(orders);
    if (jobId == null) {
      AppHelpers.showSnackBar(
        context,
        'No active job found',
        isError: true,
      );
      return;
    }

    final attemptCount = orders.contactAttempts?.attempts.length ?? 0;
    final note = attemptCount > 0
        ? 'Customer not answering after $attemptCount calls'
        : 'Customer not answering after 2 calls';

    final result = await orders.markUnableToDeliver(
      jobId: jobId,
      note: note,
    );
    if (!mounted) return;

    if (result != null) {
      showIncidentSnack(context, result.message);
      Navigator.pushNamed(
        context,
        RouteNames.dispatchCantReachChat,
        arguments: widget.args,
      );
      return;
    }

    AppHelpers.showSnackBar(
      context,
      orders.unableToDeliverError ?? 'Failed to mark unable to deliver',
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();
    final attemptsData = orders.contactAttempts;
    final attempts = attemptsData?.attempts ?? const <ContactAttempt>[];
    final requiredCount = attemptsData?.requiredForUnableToDeliver ?? 2;
    final canMarkUnable = attemptsData?.canMarkUnableToDeliver ?? false;
    final isLogging = orders.isLoggingContactAttempt;
    final isMarkingUnable = orders.isMarkingUnableToDeliver;

    return Scaffold(
      backgroundColor: IncidentColors.screenBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            IncidentHeader(
              title: 'Can’t reach customer',
              subtitle: widget.args.dropoffSubtitle,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  IncidentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          requiredCount == 1
                              ? 'One documented attempt required'
                              : '$requiredCount documented attempts required',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: IncidentColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (attempts.isEmpty)
                          const Text(
                            'No attempts logged yet',
                            style: TextStyle(
                              fontSize: 12,
                              color: IncidentColors.textMuted,
                            ),
                          )
                        else
                          ...List.generate(attempts.length, (index) {
                            final attempt = attempts[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == attempts.length - 1 ? 0 : 10,
                              ),
                              child: _AttemptRow(
                                title:
                                    'Attempt ${index + 1} · ${attempt.titleLabel}',
                                subtitle: attempt.loggedLabel,
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  IncidentCard(
                    child: Column(
                      children: [
                        const Text(
                          'Waiting at door',
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
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: IncidentOutlinedButton(
                          label: isLogging ? 'Logging…' : 'Call',
                          leading: const Icon(
                            Icons.call,
                            size: 18,
                            color: IncidentColors.textPrimary,
                          ),
                          onPressed: isLogging ? null : _logCallAttempt,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: IncidentOutlinedButton(
                          label: 'Message',
                          leading: Image.asset(
                            AppAssets.incidentMessage,
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                          onPressed: () =>
                              showIncidentSnack(context, 'Message sent'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  IncidentPrimaryButton(
                    label: isMarkingUnable
                        ? 'Reporting…'
                        : 'Mark as unable to deliver',
                    onPressed: (canMarkUnable && !isMarkingUnable)
                        ? _markUnableToDeliver
                        : null,
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

class _AttemptRow extends StatelessWidget {
  const _AttemptRow({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: IncidentColors.successGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: IncidentColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: IncidentColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

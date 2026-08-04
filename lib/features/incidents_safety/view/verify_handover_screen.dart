import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/features/incidents_safety/view/incident_ui.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';

/// DR5 · Verify handover / OTP problem
/// Resend uses `POST /drivers/jobs/:jobId/resend-code`.
class VerifyHandoverScreen extends StatefulWidget {
  const VerifyHandoverScreen({
    super.key,
    this.args = const IncidentContextArgs(),
  });

  final IncidentContextArgs args;

  @override
  State<VerifyHandoverScreen> createState() => _VerifyHandoverScreenState();
}

class _VerifyHandoverScreenState extends State<VerifyHandoverScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String? _resolveJobId(OrderProvider orders) {
    final detailId = orders.currentJobDetail?.id.trim();
    if (detailId != null && detailId.isNotEmpty && !detailId.startsWith('#')) {
      return detailId;
    }

    if (orders.instantActiveJobs.isNotEmpty) {
      final activeId = orders.instantActiveJobs.first.id.trim();
      if (activeId.isNotEmpty && !activeId.startsWith('#')) return activeId;
    }

    final orderId = widget.args.orderId.trim();
    if (orderId.isNotEmpty && !orderId.startsWith('#')) return orderId;

    return null;
  }

  Future<void> _resendCode() async {
    final provider = context.read<OrderProvider>();
    if (provider.isResendingSecureCode) return;

    final code = _codeController.text.trim();
    if (code.isEmpty) {
      showIncidentSnack(context, 'Enter the delivery code first');
      return;
    }

    final jobId = _resolveJobId(provider);
    if (jobId == null) {
      showIncidentSnack(context, 'No active job found to resend code');
      return;
    }

    final result = await provider.resendSecureCode(jobId: jobId, code: code);
    if (!mounted) return;

    if (result != null) {
      showIncidentSnack(context, result.message);
      return;
    }

    showIncidentSnack(
      context,
      provider.resendSecureCodeError ?? 'Failed to resend code',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isResending = context.watch<OrderProvider>().isResendingSecureCode;

    return Scaffold(
      backgroundColor: IncidentColors.screenBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const IncidentHeader(title: 'Verify / OTP problem'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  const Text(
                    'This category needs verified handover. Don’t hand over without it.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: IncidentColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Resend code to the customer’s registered number',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: IncidentColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    enabled: !isResending,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                      color: IncidentColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Code',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                        color: IncidentColors.textMuted.withValues(alpha: 0.8),
                      ),
                      filled: true,
                      fillColor: IncidentColors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: IncidentColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: IncidentColors.successGreen,
                          width: 1.4,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: IncidentColors.cardBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  IncidentPrimaryButton(
                    label: isResending
                        ? 'Sending…'
                        : 'Resend code to the customer',
                    color: IncidentColors.successGreen,
                    onPressed: isResending ? null : _resendCode,
                    leading: isResending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
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

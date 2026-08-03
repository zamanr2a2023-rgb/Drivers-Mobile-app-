import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';

/// Local UI-only screen for rejecting a New scheduled order.
/// Shown inside Orders tab so BottomNavigation stays on Orders.
class RejectScheduledOrderScreen extends StatefulWidget {
  const RejectScheduledOrderScreen({
    super.key,
    required this.orderId,
    required this.onBack,
    required this.onKeepOrder,
    required this.onSubmitDecline,
  });

  final String orderId;
  final VoidCallback onBack;
  final VoidCallback onKeepOrder;
  final void Function(String reason, String note) onSubmitDecline;

  @override
  State<RejectScheduledOrderScreen> createState() =>
      _RejectScheduledOrderScreenState();
}

class _RejectScheduledOrderScreenState
    extends State<RejectScheduledOrderScreen> {
  static const Color _headerGreen = Color(0xFF4DB04F);
  static const Color _screenBg = Color(0xFFF5F5F5);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF9E9E9E);
  static const Color _textSecondary = Color(0xFF757575);
  static const Color _border = Color(0xFFE0E0E0);
  static const Color _selectedBorder = Color(0xFF4DB04F);
  static const Color _radioGreen = Color(0xFF4DB04F);
  static const Color _warningBg = Color(0xFFFFF3E8);
  static const Color _warningBorder = Color(0xFFFFE0C2);
  static const Color _warningOrange = Color(0xFFE67E22);
  static const Color _submitBlack = Color(0xFF1A1A1A);

  static const _reasons = [
    (
      title: 'Vehicle breakdown',
      subtitle: 'Bike/car not drivable',
    ),
    (
      title: 'Safety concern',
      subtitle: 'Unsafe area or situation',
    ),
    (
      title: 'Active emergency',
      subtitle: 'Personal / medical emergency',
    ),
    (
      title: 'Other reason',
      subtitle: 'May count as a refusal',
    ),
  ];

  int? _selectedReason;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _selectedReason != null;

  void _submit() {
    if (!_canSubmit) return;
    if (context.read<OrderProvider>().isDecliningJob) return;
    widget.onSubmitDecline(
      _reasons[_selectedReason!].title,
      _noteController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isDeclining = context.watch<OrderProvider>().isDecliningJob;
    final canSubmit = _canSubmit && !isDeclining;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: _headerGreen,
        statusBarIconBrightness: Brightness.light,
      ),
      child: ColoredBox(
        color: _screenBg,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 18, 16, 24 + bottomInset),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  const Text(
                    'Valid reasons only',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < _reasons.length; i++) ...[
                    _ReasonCard(
                      title: _reasons[i].title,
                      subtitle: _reasons[i].subtitle,
                      selected: _selectedReason == i,
                      onTap: isDeclining
                          ? () {}
                          : () => setState(() => _selectedReason = i),
                    ),
                    if (i < _reasons.length - 1) const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 14),
                  _buildNoteCard(),
                  const SizedBox(height: 12),
                  _buildWarningCard(),
                  const SizedBox(height: 20),
                  Opacity(
                    opacity: canSubmit || isDeclining ? 1 : 0.45,
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Material(
                        color: _submitBlack,
                        borderRadius: BorderRadius.circular(28),
                        child: InkWell(
                          onTap: canSubmit ? _submit : null,
                          borderRadius: BorderRadius.circular(28),
                          child: Center(
                            child: isDeclining
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Submit & decline',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Material(
                      color: _surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                        side: const BorderSide(color: _border),
                      ),
                      child: InkWell(
                        onTap: isDeclining ? null : widget.onKeepOrder,
                        borderRadius: BorderRadius.circular(28),
                        child: const Center(
                          child: Text(
                            'Keep the order',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: _headerGreen,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Why are you rejecting?',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  'Order ${widget.orderId}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFEDF2EF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add a note (optional)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: const InputDecorationTheme(
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            child: TextField(
              controller: _noteController,
              maxLines: 3,
              minLines: 2,
              cursorColor: _textPrimary,
              style: const TextStyle(
                fontSize: 14,
                color: _textPrimary,
              ),
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                hintText: 'Tell us more about why you’re rejecting...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: _textMuted,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _warningBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _warningBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: _warningOrange,
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Invalid or no reason counts as a refusal',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _warningOrange,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? _RejectScheduledOrderScreenState._selectedBorder
                  : _RejectScheduledOrderScreenState._border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? _RejectScheduledOrderScreenState._radioGreen
                      : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? _RejectScheduledOrderScreenState._radioGreen
                        : const Color(0xFFBDBDBD),
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _RejectScheduledOrderScreenState._textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: _RejectScheduledOrderScreenState._textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/utils/app_helpers.dart';
import 'package:yjeek_driver/features/incidents_safety/view/incident_ui.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';

/// DR3 · Damage at pickup
class DamageAtPickupScreen extends StatefulWidget {
  const DamageAtPickupScreen({
    super.key,
    this.args = const IncidentContextArgs(),
  });

  final IncidentContextArgs args;

  @override
  State<DamageAtPickupScreen> createState() => _DamageAtPickupScreenState();
}

class _DamageAtPickupScreenState extends State<DamageAtPickupScreen> {
  static const _reportReason = 'DAMAGED_AT_PICKUP';

  static const _issues = [
    'Leaking / spilled',
    'Broken seal',
    'Crushed / damaged',
    'Wrong packaging',
  ];

  static const _damageTypeByLabel = {
    'Leaking / spilled': 'LEAKING_SPILLED',
    'Broken seal': 'BROKEN_SEAL',
    'Crushed / damaged': 'CRUSHED_DAMAGED',
    'Wrong packaging': 'WRONG_PACKAGING',
  };

  final _selected = <String>{};
  bool _declining = true;
  Uint8List? _photoBytes;

  Future<void> _pickPhoto() async {
    final bytes = await pickIncidentPhoto(context);
    if (!mounted || bytes == null) return;
    setState(() => _photoBytes = bytes);
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

  String _damageTypeCode() {
    for (final label in _issues) {
      if (_selected.contains(label)) {
        return _damageTypeByLabel[label] ?? 'LEAKING_SPILLED';
      }
    }
    return 'LEAKING_SPILLED';
  }

  String _noteFromSelection() {
    if (_selected.isEmpty) return 'Damage reported at pickup';
    return _selected.join(', ');
  }

  Future<void> _submit() async {
    final photoBytes = _photoBytes;
    if (photoBytes == null) {
      showIncidentSnack(context, 'Please add a photo of the damage');
      return;
    }
    if (_selected.isEmpty) {
      showIncidentSnack(context, 'Please select what’s wrong');
      return;
    }

    final orders = context.read<OrderProvider>();
    if (orders.isReportingJobIssue) return;

    final jobId = _resolveJobId(orders);
    if (jobId == null) {
      AppHelpers.showSnackBar(
        context,
        'No active job found',
        isError: true,
      );
      return;
    }

    final result = await orders.reportJobIssue(
      jobId: jobId,
      reason: _reportReason,
      note: _noteFromSelection(),
      damageType: _damageTypeCode(),
      photoBytes: photoBytes,
      declineItems: _declining,
    );

    if (!mounted) return;

    if (result != null) {
      showIncidentSnack(context, result.message);
      Navigator.maybePop(context);
      return;
    }

    AppHelpers.showSnackBar(
      context,
      orders.jobReportError ?? 'Failed to report damage',
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isReporting = context.watch<OrderProvider>().isReportingJobIssue;

    return Scaffold(
      backgroundColor: IncidentColors.screenBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const IncidentHeader(
              title: 'Damage at pickup',
              subtitle: 'Photograph before you leave',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  IncidentPhotoUpload(
                    hasPhoto: _photoBytes != null,
                    photoBytes: _photoBytes,
                    onTap: isReporting ? () {} : _pickPhoto,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'What’s wrong?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: IncidentColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _issues.map((issue) {
                      final selected = _selected.contains(issue);
                      return IncidentChip(
                        label: issue,
                        selected: selected,
                        onTap: isReporting
                            ? () {}
                            : () {
                                setState(() {
                                  if (selected) {
                                    _selected.remove(issue);
                                  } else {
                                    _selected.add(issue);
                                  }
                                });
                              },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  IncidentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'I’m declining these items',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: IncidentColors.textPrimary,
                                ),
                              ),
                            ),
                            _DeclineToggle(
                              value: _declining,
                              onChanged: isReporting
                                  ? (_) {}
                                  : (v) => setState(() => _declining = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Vendor must re-pack or re-prepare before you take it.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.35,
                            color: IncidentColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  IncidentPrimaryButton(
                    label: isReporting
                        ? 'Submitting…'
                        : 'Submit & decline items',
                    onPressed: (!_declining || isReporting) ? null : _submit,
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

/// 24px circular control matching the design: a red ring (red circle with
/// white 20px center) when on, grey ring when off.
class _DeclineToggle extends StatelessWidget {
  const _DeclineToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: value ? IncidentColors.danger : const Color(0xFFD9DDD9),
          shape: BoxShape.circle,
        ),
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: IncidentColors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

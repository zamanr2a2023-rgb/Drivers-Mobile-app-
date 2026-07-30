import 'package:flutter/material.dart';
import 'package:yjeek_driver/core/constants/app_assets.dart';
import 'package:yjeek_driver/features/profile/model/account_documents_model.dart';
import 'package:yjeek_driver/features/profile/service/profile_service.dart';
import 'package:yjeek_driver/features/profile/view/doc_upload_ui.dart';
import 'package:yjeek_driver/routes/route_names.dart';
import 'package:yjeek_driver/services/api_service.dart';

/// D4 · Documents
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final ProfileService _profileService = ProfileService();

  bool _isLoading = false;
  AccountDocumentsModel? _documents;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDocuments();
    });
  }

  Future<void> _loadDocuments() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final documents = await _profileService.getDocuments();
      if (!mounted) return;
      setState(() => _documents = documents);
    } on ApiException catch (e) {
      if (!mounted) return;
      showDocSnack(context, e.message);
    } catch (_) {
      if (!mounted) return;
      showDocSnack(context, 'Failed to load documents');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openChecklistItem(DocumentChecklistItemModel item) async {
    final route = _routeForKey(item.key);
    if (route == null) return;
    await Navigator.pushNamed(context, route);
    if (!mounted) return;
    await _loadDocuments();
  }

  String? _routeForKey(String key) {
    switch (key.trim().toLowerCase()) {
      case 'cpr':
        return RouteNames.uploadCpr;
      case 'passport':
        return RouteNames.uploadPassport;
      case 'visa':
        return RouteNames.uploadVisa;
      case 'driving_license':
        return RouteNames.uploadDrivingLicense;
      case 'vehicle_registration':
        return RouteNames.uploadVehicleRegistration;
      case 'profile_photo':
        return RouteNames.uploadProfilePhoto;
      default:
        return null;
    }
  }

  String _iconForKey(String key) {
    switch (key.trim().toLowerCase()) {
      case 'cpr':
        return AppAssets.docCpr;
      case 'passport':
        return AppAssets.docPassport;
      case 'visa':
        return AppAssets.docVisa;
      case 'driving_license':
        return AppAssets.docDrivingLicense;
      case 'vehicle_registration':
        return AppAssets.docVehicle;
      case 'profile_photo':
        return AppAssets.docProfilePhoto;
      default:
        return AppAssets.docCpr;
    }
  }

  _DocStatus _statusForUi(String uiStatus) {
    final normalized = uiStatus.trim().toLowerCase();
    if (normalized.contains('done') ||
        normalized.contains('approved') ||
        normalized.contains('complete')) {
      return _DocStatus.done;
    }
    if (normalized.contains('review') || normalized.contains('pending')) {
      return _DocStatus.underReview;
    }
    return _DocStatus.required_;
  }

  @override
  Widget build(BuildContext context) {
    final data = _documents;
    final canSubmit = data?.canSubmitForReview == true;

    return Scaffold(
      backgroundColor: DocColors.screenBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DocHeader(title: 'Documents'),
            Expanded(
              child: _isLoading && data == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: DocColors.green,
                      ),
                    )
                  : RefreshIndicator(
                      color: DocColors.green,
                      onRefresh: _loadDocuments,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          children: [
                            _buildProgressCard(data?.progress),
                            const SizedBox(height: 14),
                            if (data == null || data.checklist.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Text(
                                  'No documents found',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: DocColors.textSecondary,
                                  ),
                                ),
                              )
                            else
                              ...[
                                for (var i = 0;
                                    i < data.checklist.length;
                                    i++) ...[
                                  if (i > 0) const SizedBox(height: 14),
                                  _DocumentRow(
                                    iconAsset: _iconForKey(data.checklist[i].key),
                                    title: data.checklist[i].label,
                                    helper: data.checklist[i].subtitle,
                                    statusLabel: data.checklist[i].uiStatus,
                                    status: _statusForUi(
                                      data.checklist[i].uiStatus,
                                    ),
                                    onTap: () =>
                                        _openChecklistItem(data.checklist[i]),
                                  ),
                                ],
                              ],
                          ],
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: DocPrimaryButton(
                label: 'Submit for review',
                color: canSubmit ? DocColors.green : const Color(0xFFB7C5B7),
                onPressed: canSubmit
                    ? () {
                        showDocSnack(
                          context,
                          'Documents submitted for review',
                        );
                        Navigator.maybePop(context);
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(DocumentsProgressModel? progress) {
    final label = (progress?.label.trim().isNotEmpty == true)
        ? progress!.label
        : '0 of 0 completed';
    final almostThere = progress?.almostThere == true;
    final value = progress?.fraction ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DocColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DocColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: DocColors.textPrimary,
                ),
              ),
              if (almostThere)
                const Text(
                  'Almost there',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: DocColors.greenDark,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: DocColors.doneBg,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(DocColors.green),
            ),
          ),
        ],
      ),
    );
  }
}

enum _DocStatus { done, required_, underReview }

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.title,
    required this.helper,
    required this.status,
    required this.statusLabel,
    required this.onTap,
    required this.iconAsset,
  });

  final String iconAsset;
  final String title;
  final String helper;
  final String statusLabel;
  final _DocStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DocColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DocColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DocColors.doneBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(iconAsset, width: 22, height: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: DocColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      helper,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: DocColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(),
              const SizedBox(width: 6),
              const Text(
                '›',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF99A199),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge() {
    final (Color bg, Color fg) = switch (status) {
      _DocStatus.done => (DocColors.doneBg, DocColors.greenDark),
      _DocStatus.required_ => (DocColors.warnBg, DocColors.warnText),
      _DocStatus.underReview => (DocColors.reviewBg, DocColors.reviewText),
    };
    final label = statusLabel.trim().isEmpty
        ? switch (status) {
            _DocStatus.done => 'Done',
            _DocStatus.required_ => 'Required',
            _DocStatus.underReview => 'Under review',
          }
        : statusLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == _DocStatus.done) ...[
            Icon(Icons.check, size: 11, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

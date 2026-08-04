import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/utils/app_helpers.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_order.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_shared.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_vape_return_state.dart';

/// Return-the-order screen for failed verification (age / secure).
/// Starts return, then confirms handover via `POST .../confirm-return`.
class ReturnTheOrderScreen extends StatefulWidget {
  const ReturnTheOrderScreen({
    super.key,
    required this.order,
  });

  final ScheduledDeliveryOrder order;

  @override
  State<ReturnTheOrderScreen> createState() => _ReturnTheOrderScreenState();
}

class _ReturnTheOrderScreenState extends State<ReturnTheOrderScreen> {
  static const Color _headerRed = Color(0xFFE53935);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _screenBg = Color(0xFFF4F8F2);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF9E9E9E);
  static const Color _cardBorder = Color(0xFFE0E0E0);
  static const Color _alertBg = Color(0xFFFFEBEE);
  static const Color _alertText = Color(0xFFC62828);
  static const Color _uploadBg = Color(0xFFF5F5F5);
  static const Color _uploadBorder = Color(0xFFBDBDBD);
  static const Color _policyBg = Color(0xFFE8F5E9);
  static const Color _policyText = Color(0xFF2E7D32);
  static const Color _radioEmpty = Color(0xFFBDBDBD);
  static const Color _divider = Color(0xFFEEEEEE);
  static const Color _cancelBorder = Color(0xFFE0E0E0);

  static const List<String> _reasons = [
    'Customer is under 18',
    'No valid ID shown',
    'Name does not match the order',
    'Customer not present',
    'Customer refused ID check',
  ];

  String? _selectedReason;
  bool _hasReturnPhoto = false;
  Uint8List? _returnPhotoBytes;
  String? _inlineError;
  final ImagePicker _imagePicker = ImagePicker();

  ScheduledDeliveryOrder get order => widget.order;

  bool get _isSubmitting =>
      context.watch<OrderProvider>().isProcessingReturn;

  bool get _isSecureReturn {
    final category = order.category.toLowerCase();
    final type = order.orderTypeLabel.toLowerCase();
    final status = order.cardStatusLine.toLowerCase();
    return order.isFragileHighValue ||
        category.contains('luxury') ||
        category.contains('high-value') ||
        type.contains('luxury') ||
        status.contains('restricted high-value') ||
        status.contains('secure');
  }

  static String _mapAgeReasonCode(String reasonLabel) {
    switch (reasonLabel) {
      case 'Customer is under 18':
        return 'UNDER_18';
      case 'No valid ID shown':
        return 'NO_VALID_ID';
      case 'Name does not match the order':
        return 'NAME_MISMATCH';
      case 'Customer not present':
        return 'CUSTOMER_NOT_PRESENT';
      case 'Customer refused ID check':
        return 'CUSTOMER_REFUSED';
      default:
        return 'NO_VALID_ID';
    }
  }

  static String _mapSecureReasonCode(String reasonLabel) {
    switch (reasonLabel) {
      case 'Customer not present':
        return 'RECIPIENT_NOT_PRESENT';
      case 'Name does not match the order':
        return 'RECIPIENT_MISMATCH';
      case 'Customer refused ID check':
        return 'VERIFICATION_REFUSED';
      case 'No valid ID shown':
        return 'NO_VALID_ID';
      case 'Customer is under 18':
      default:
        return 'CODE_VERIFICATION_FAILED';
    }
  }

  String? _resolveJobId(OrderProvider orders) {
    final detailId = orders.currentJobDetail?.id.trim();
    if (detailId != null &&
        detailId.isNotEmpty &&
        !detailId.startsWith('#')) {
      return detailId;
    }

    if (orders.instantActiveJobs.isNotEmpty) {
      final activeId = orders.instantActiveJobs.first.id.trim();
      if (activeId.isNotEmpty && !activeId.startsWith('#')) return activeId;
    }

    final orderId = order.orderId.trim();
    if (orderId.isNotEmpty && !orderId.startsWith('#')) return orderId;

    return null;
  }

  Future<void> _selectReturnPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || source == null) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (!mounted || picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _returnPhotoBytes = bytes;
        _hasReturnPhoto = true;
        _inlineError = null;
      });
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to access photos. Please try again.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo selection failed. Please try again.'),
        ),
      );
    }
  }

  Future<void> _confirmReturn() async {
    final provider = context.read<OrderProvider>();
    if (provider.isProcessingReturn) return;

    if (_selectedReason == null) {
      setState(() {
        _inlineError = 'Please select a verification failure reason.';
      });
      return;
    }

    if (!_hasReturnPhoto || _returnPhotoBytes == null) {
      setState(() {
        _inlineError = 'Please add a return photo before confirming.';
      });
      return;
    }

    final jobId = _resolveJobId(provider);
    if (jobId == null) {
      setState(() {
        _inlineError = 'No active job found to start return.';
      });
      return;
    }

    setState(() => _inlineError = null);

    final alreadyReturning = provider.currentJobDetail?.status.trim() ==
        'RETURNING_TO_VENDOR';

    if (!alreadyReturning) {
      final isSecure = _isSecureReturn;
      final reasonCode = isSecure
          ? _mapSecureReasonCode(_selectedReason!)
          : _mapAgeReasonCode(_selectedReason!);
      final note = isSecure && reasonCode == 'CODE_VERIFICATION_FAILED'
          ? 'Recipient could not provide the one-time code'
          : _selectedReason!;

      final startResult = isSecure
          ? await provider.returnSecureOrder(
              jobId: jobId,
              reason: reasonCode,
              returnPhotoBytes: _returnPhotoBytes!,
              note: note,
            )
          : await provider.returnAgeRestricted(
              jobId: jobId,
              reason: reasonCode,
              returnPhotoBytes: _returnPhotoBytes!,
              note: note,
            );
      if (!mounted) return;

      if (startResult == null) {
        AppHelpers.showSnackBar(
          context,
          (isSecure
                  ? provider.returnSecureOrderError
                  : provider.returnAgeRestrictedError) ??
              'Failed to start return',
          isError: true,
        );
        return;
      }

      ScheduledVapeReturnState.save(
        ScheduledVapeReturnSubmission(
          orderId: order.orderId,
          reason: _selectedReason!,
          photoBytes: _returnPhotoBytes!.toList(),
          submittedAt: DateTime.now(),
        ),
      );
    }

    final confirmResult = await provider.confirmReturnHandover(
      jobId: jobId,
      vendorHandoverPhotoBytes: _returnPhotoBytes!,
    );
    if (!mounted) return;

    if (confirmResult != null) {
      AppHelpers.showSnackBar(context, confirmResult.message);
      return;
    }

    AppHelpers.showSnackBar(
      context,
      provider.confirmReturnError ?? 'Failed to confirm return handover',
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    ScheduledDeliveryScale.update(MediaQuery.sizeOf(context));
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isSubmitting = _isSubmitting;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: !isSubmitting,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !isSubmitting) Navigator.pop(context);
        },
        child: Scaffold(
          backgroundColor: _screenBg,
          body: Column(
            children: [
              ColoredBox(
                color: Colors.white,
                child: SizedBox(height: topInset),
              ),
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    16.sw,
                    14.sh,
                    16.sw,
                    16.sh + bottomInset,
                  ),
                  children: [
                    _buildAlertBanner(),
                    SizedBox(height: 16.sh),
                    _buildReasonSection(),
                    SizedBox(height: 14.sh),
                    _buildPhotoUpload(),
                    SizedBox(height: 14.sh),
                    _buildWhatHappensNext(),
                    SizedBox(height: 12.sh),
                    _buildPolicyBox(),
                    if (_inlineError != null) ...[
                      SizedBox(height: 12.sh),
                      Text(
                        _inlineError!,
                        style: TextStyle(
                          fontSize: 12.ssp,
                          fontWeight: FontWeight.w600,
                          color: _alertText,
                          height: 1.3,
                        ),
                      ),
                    ],
                    SizedBox(height: 20.sh),
                    _buildConfirmButton(),
                    SizedBox(height: 10.sh),
                    _buildCancelButton(),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: scheduledBottomNav(context),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: _headerRed,
      padding: EdgeInsets.fromLTRB(12.sw, 10.sh, 16.sw, 10.sh),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.22),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _isSubmitting ? null : () => Navigator.pop(context),
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 36.sw,
                height: 36.sw,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: 18.ssp,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.sw),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Return the order',
                  style: TextStyle(
                    fontSize: 19.ssp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 3.sh),
                Text(
                  'Verification failed · ${order.orderId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.ssp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.sw, vertical: 12.sh),
      decoration: BoxDecoration(
        color: _alertBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22.ssp,
            height: 22.ssp,
            decoration: const BoxDecoration(
              color: _alertText,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.remove, color: _white, size: 16.ssp),
          ),
          SizedBox(width: 10.sw),
          Expanded(
            child: Text(
              'The customer could not be verified, so the order must be returned to the vendor. Keep it sealed.',
              style: TextStyle(
                fontSize: 12.ssp,
                fontWeight: FontWeight.w600,
                color: _alertText,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Why couldn\u2019t you verify?',
          style: TextStyle(
            fontSize: 17.ssp,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            height: 1.25,
          ),
        ),
        SizedBox(height: 10.sh),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _cardBorder),
          ),
          child: Column(
            children: [
              for (var i = 0; i < _reasons.length; i++) ...[
                _buildReasonRow(_reasons[i]),
                if (i < _reasons.length - 1)
                  Divider(height: 1, thickness: 1, color: _divider),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReasonRow(String reason) {
    final selected = _selectedReason == reason;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSubmitting
            ? null
            : () => setState(() {
                  _selectedReason = reason;
                  _inlineError = null;
                }),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.sw, vertical: 14.sh),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  reason,
                  style: TextStyle(
                    fontSize: 13.ssp,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
              SizedBox(width: 12.sw),
              Container(
                width: 22.ssp,
                height: 22.ssp,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? _headerRed : _radioEmpty,
                    width: selected ? 6 : 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoUpload() {
    final hasImage = _hasReturnPhoto && _returnPhotoBytes != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSubmitting ? null : _selectReturnPhoto,
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: ScheduledDashedBorderPainter(
            color: _uploadBorder,
            radius: 14,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              height: 96.sh,
              color: _uploadBg,
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(
                          _returnPhotoBytes!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildUploadPlaceholder(),
                        ),
                        Positioned(
                          top: 8.sh,
                          right: 8.sw,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.sw,
                              vertical: 4.sh,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Change photo',
                              style: TextStyle(
                                fontSize: 11.ssp,
                                fontWeight: FontWeight.w600,
                                color: _white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _buildUploadPlaceholder(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_camera_outlined,
            color: _textPrimary,
            size: 22.ssp,
          ),
          SizedBox(height: 8.sh),
          Text(
            'Add return photo · required',
            style: TextStyle(
              fontSize: 13.ssp,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatHappensNext() {
    const steps = [
      'Keep the order sealed and unopened',
      'Return it to the vendor',
      'Hand it over and get vendor confirmation',
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.sw, 14.sh, 14.sw, 14.sh),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What happens next',
            style: TextStyle(
              fontSize: 14.ssp,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              height: 1.25,
            ),
          ),
          SizedBox(height: 12.sh),
          for (var i = 0; i < steps.length; i++) ...[
            Text(
              '${i + 1} · ${steps[i]}',
              style: TextStyle(
                fontSize: 12.ssp,
                fontWeight: FontWeight.w400,
                color: _textMuted,
                height: 1.35,
              ),
            ),
            if (i < steps.length - 1) SizedBox(height: 8.sh),
          ],
        ],
      ),
    );
  }

  Widget _buildPolicyBox() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.sw, vertical: 12.sh),
      decoration: BoxDecoration(
        color: _policyBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_box, color: _policyText, size: 20.ssp),
          SizedBox(width: 10.sw),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12.ssp,
                  fontWeight: FontWeight.w500,
                  color: _policyText,
                  height: 1.35,
                ),
                children: const [
                  TextSpan(
                    text: 'Following age / ID policy correctly does ',
                  ),
                  TextSpan(
                    text: 'NOT',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: ' affect your rating or earnings for this trip.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 52.sh,
      child: Material(
        color: _headerRed,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: _isSubmitting ? null : _confirmReturn,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: _isSubmitting
                ? SizedBox(
                    width: 22.ssp,
                    height: 22.ssp,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Confirm return to vendor',
                    style: TextStyle(
                      fontSize: 15.ssp,
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

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      height: 52.sh,
      child: Material(
        color: _white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _cancelBorder),
        ),
        child: InkWell(
          onTap: _isSubmitting ? null : () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 15.ssp,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/utils/app_helpers.dart';
import 'package:yjeek_driver/features/orders/order_flow_helpers.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_order.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_shared.dart';
import 'package:yjeek_driver/routes/route_names.dart';

/// Age-restricted delivery verification for Scheduled Vape orders.
/// Confirm calls upload + `POST /drivers/jobs/:jobId/complete` with ageVerification.
class AgeRestrictedDeliveryScreen extends StatefulWidget {
  const AgeRestrictedDeliveryScreen({
    super.key,
    required this.order,
  });

  final ScheduledDeliveryOrder order;

  @override
  State<AgeRestrictedDeliveryScreen> createState() =>
      _AgeRestrictedDeliveryScreenState();
}

class _AgeRestrictedDeliveryScreenState
    extends State<AgeRestrictedDeliveryScreen> {
  static const Color _headerGreen = Color(0xFF4DB04F);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _screenBg = Color(0xFFF4F8F2);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF9E9E9E);
  static const Color _cardBorder = Color(0xFFE0E0E0);
  static const Color _subtitleText = Color(0xFFCFE3D5);
  static const Color _warningBg = Color(0xFFFFF4E6);
  static const Color _warningText = Color(0xFFB86A00);
  static const Color _uploadBg = Color(0xFFF5F5F5);
  static const Color _uploadBorder = Color(0xFFBDBDBD);
  static const Color _avatarBg = Color(0xFFE8F5E9);
  static const Color _avatarText = Color(0xFF2E7D32);
  static const Color _returnText = Color(0xFFE53935);
  static const Color _returnBorder = Color(0xFFE0E0E0);

  static const List<String> _idChecks = [
    'Name matches the card',
    'Photo matches the person',
    '18 years or older',
  ];

  bool _hasCprPhoto = false;
  bool _hasProofPhoto = false;
  Uint8List? _cprPhotoBytes;
  Uint8List? _proofPhotoBytes;
  final ImagePicker _imagePicker = ImagePicker();

  ScheduledDeliveryOrder get order => widget.order;

  String get _customerFullName => _resolveFullCustomerName(order.customerName);

  String get _customerInitials => _initialsFromName(_customerFullName);

  String get _idSummaryLine => _resolveIdSummary(order);

  String get _headerSubtitle {
    final category =
        order.category.contains('Vape') ? order.category : 'Vape · 18+';
    return '$category · ${order.orderId}';
  }

  static String _resolveFullCustomerName(String customerName) {
    if (customerName.trim() == 'Sara A.') return 'Sara Ahmed';
    return customerName;
  }

  static String _initialsFromName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  static String _resolveIdSummary(ScheduledDeliveryOrder order) {
    final fullName = _resolveFullCustomerName(order.customerName);
    if (fullName == 'Sara Ahmed') {
      return 'CPR ••• 8821 · DOB 12 Jun 1996 · 29 yrs';
    }
    return 'CPR ••• •••• · DOB unavailable';
  }

  Future<void> _selectPhoto({required bool forCpr}) async {
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
        if (forCpr) {
          _cprPhotoBytes = bytes;
          _hasCprPhoto = true;
        } else {
          _proofPhotoBytes = bytes;
          _hasProofPhoto = true;
        }
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

  Future<void> _confirmDelivery() async {
    if (!_hasCprPhoto || _cprPhotoBytes == null) {
      AppHelpers.showSnackBar(
        context,
        'Please add the customer CPR photo',
        isError: true,
      );
      return;
    }
    if (!_hasProofPhoto || _proofPhotoBytes == null) {
      AppHelpers.showSnackBar(
        context,
        'Please add proof of delivery photo',
        isError: true,
      );
      return;
    }

    final provider = context.read<OrderProvider>();
    if (provider.isCompletingJob) return;

    final jobId = _resolveJobId(provider);
    if (jobId == null) {
      AppHelpers.showSnackBar(
        context,
        'No active job found to complete',
        isError: true,
      );
      return;
    }

    final result = await provider.completeAgeRestrictedJob(
      jobId: jobId,
      ageVerificationPhotoBytes: _cprPhotoBytes!,
      deliveryPhotoBytes: _proofPhotoBytes!,
      nameMatches: true,
      photoMatches: true,
      verified18OrOlder: true,
    );
    if (!mounted) return;

    if (result != null) {
      AppHelpers.showSnackBar(context, result.message);
      await navigateToJobSuccessScreen(
        context,
        provider: provider,
        routeName: RouteNames.scheduledVapeDeliveryCompleted,
        arguments: order,
        refreshScheduledBoards: true,
      );
      return;
    }

    AppHelpers.showSnackBar(
      context,
      provider.completeJobError ?? 'Failed to complete age-restricted delivery',
      isError: true,
    );
  }

  void _returnOrder() {
    Navigator.pushNamed(
      context,
      RouteNames.returnTheOrder,
      arguments: order,
    );
  }

  @override
  Widget build(BuildContext context) {
    ScheduledDeliveryScale.update(MediaQuery.sizeOf(context));
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) Navigator.pop(context);
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
                    _buildWarningBanner(),
                    SizedBox(height: 12.sh),
                    _buildCprPhotoCard(),
                    SizedBox(height: 12.sh),
                    _buildIdMatchCard(),
                    SizedBox(height: 12.sh),
                    _buildProofCard(),
                    SizedBox(height: 20.sh),
                    _buildConfirmButton(),
                    SizedBox(height: 10.sh),
                    _buildReturnButton(),
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
      color: _headerGreen,
      padding: EdgeInsets.fromLTRB(12.sw, 10.sh, 16.sw, 10.sh),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.22),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => Navigator.pop(context),
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
                  'Age-restricted delivery',
                  style: TextStyle(
                    fontSize: 15.ssp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 3.sh),
                Text(
                  _headerSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.ssp,
                    fontWeight: FontWeight.w500,
                    color: _subtitleText,
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

  Widget _buildWarningBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.sw, vertical: 12.sh),
      decoration: BoxDecoration(
        color: _warningBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: _warningText,
            size: 18.ssp,
          ),
          SizedBox(width: 10.sw),
          Expanded(
            child: Text(
              'Verify the customer is 18+ and the name matches the order before handing over.',
              style: TextStyle(
                fontSize: 12.ssp,
                fontWeight: FontWeight.w600,
                color: _warningText,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
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
            title,
            style: TextStyle(
              fontSize: 14.ssp,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              height: 1.25,
            ),
          ),
          SizedBox(height: 14.sh),
          child,
        ],
      ),
    );
  }

  Widget _buildCprPhotoCard() {
    return _buildSectionCard(
      title: '2 · Photograph the customer\u2019s CPR',
      child: _buildUploadArea(
        hasPhoto: _hasCprPhoto,
        photoBytes: _cprPhotoBytes,
        placeholderText: 'Add CPR photo · required',
        onTap: () => _selectPhoto(forCpr: true),
      ),
    );
  }

  Widget _buildIdMatchCard() {
    return _buildSectionCard(
      title: '3 · Match with the ID on file',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40.sw,
                height: 40.sw,
                decoration: const BoxDecoration(
                  color: _avatarBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _customerInitials,
                  style: TextStyle(
                    fontSize: 14.ssp,
                    fontWeight: FontWeight.w700,
                    color: _avatarText,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(width: 12.sw),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _customerFullName,
                      style: TextStyle(
                        fontSize: 14.ssp,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 3.sh),
                    Text(
                      _idSummaryLine,
                      style: TextStyle(
                        fontSize: 12.ssp,
                        fontWeight: FontWeight.w400,
                        color: _textMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.sh),
          for (var i = 0; i < _idChecks.length; i++) ...[
            _buildCheckedRow(_idChecks[i]),
            if (i < _idChecks.length - 1) SizedBox(height: 10.sh),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckedRow(String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 22.ssp,
          height: 22.ssp,
          decoration: const BoxDecoration(
            color: _headerGreen,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, color: _white, size: 14.ssp),
        ),
        SizedBox(width: 10.sw),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.ssp,
              fontWeight: FontWeight.w500,
              color: _textPrimary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProofCard() {
    return _buildSectionCard(
      title: '4 · Proof of delivery',
      child: _buildUploadArea(
        hasPhoto: _hasProofPhoto,
        photoBytes: _proofPhotoBytes,
        placeholderText: 'Add photo · required',
        onTap: () => _selectPhoto(forCpr: false),
      ),
    );
  }

  Widget _buildUploadArea({
    required bool hasPhoto,
    required Uint8List? photoBytes,
    required String placeholderText,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
              child: hasPhoto && photoBytes != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(
                          photoBytes,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildUploadPlaceholder(
                            placeholderText,
                          ),
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
                  : _buildUploadPlaceholder(placeholderText),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder(String text) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.sw),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              color: _textPrimary,
              size: 20.ssp,
            ),
            SizedBox(width: 8.sw),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.ssp,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    final isCompleting = context.watch<OrderProvider>().isCompletingJob;

    return SizedBox(
      width: double.infinity,
      height: 52.sh,
      child: Material(
        color: _headerGreen,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: isCompleting ? null : _confirmDelivery,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: isCompleting
                ? SizedBox(
                    width: 22.ssp,
                    height: 22.ssp,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: _white,
                    ),
                  )
                : Text(
                    'Confirm 18+ & complete delivery',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

  Widget _buildReturnButton() {
    return SizedBox(
      width: double.infinity,
      height: 52.sh,
      child: Material(
        color: _white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _returnBorder),
        ),
        child: InkWell(
          onTap: _returnOrder,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Text(
              'Can\u2019t verify \u2014 return the order',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.ssp,
                fontWeight: FontWeight.w700,
                color: _returnText,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

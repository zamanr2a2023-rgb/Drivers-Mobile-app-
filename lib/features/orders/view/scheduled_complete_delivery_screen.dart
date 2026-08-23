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

/// Complete delivery screen for scheduled On Track deliveries.
/// Completes via upload + `POST /drivers/jobs/:jobId/complete`.
class ScheduledCompleteDeliveryScreen extends StatefulWidget {
  const ScheduledCompleteDeliveryScreen({
    super.key,
    required this.order,
  });

  final ScheduledDeliveryOrder order;

  @override
  State<ScheduledCompleteDeliveryScreen> createState() =>
      _ScheduledCompleteDeliveryScreenState();
}

class _ScheduledCompleteDeliveryScreenState
    extends State<ScheduledCompleteDeliveryScreen> {
  static const Color _headerGreen = Color(0xFF4DB04F);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _screenBg = Color(0xFFF4F8F2);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF9E9E9E);
  static const Color _cardBorder = Color(0xFFE0E0E0);
  static const Color _reportText = Color(0xFFCFE3D5);
  static const Color _uploadBg = Color(0xFFF5F5F5);
  static const Color _uploadBorder = Color(0xFFBDBDBD);

  bool _hasProofPhoto = false;
  Uint8List? _proofPhotoBytes;
  final ImagePicker _imagePicker = ImagePicker();
  late ScheduledDeliveryOrder _order;

  ScheduledDeliveryOrder get order => _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadJobDetails());
  }

  Future<void> _loadJobDetails() async {
    final provider = context.read<OrderProvider>();
    final jobId = scheduledLiveJobId(_order, provider);
    if (!isScheduledLiveJobId(jobId)) return;

    if (provider.currentJobDetail?.id != jobId) {
      await provider.loadJobDetail(jobId);
    }
    if (!mounted) return;
    final job = provider.currentJobDetail;
    if (job == null) return;
    setState(() => _order = _order.mergedWithJob(job));
  }

  String get _paymentDisplay =>
      order.paymentSummary.replaceAll('—', '·').replaceAll('-', '·');

  Future<void> _selectProofPhoto() async {
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
        _proofPhotoBytes = bytes;
        _hasProofPhoto = true;
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

  Future<void> _completeDelivery() async {
    if (!_hasProofPhoto) return;

    final provider = context.read<OrderProvider>();
    if (provider.isCompletingJob) return;

    final photoBytes = _proofPhotoBytes;
    if (photoBytes == null) return;

    var next = _order;
    final jobId = scheduledLiveJobId(_order, provider);

    if (isScheduledLiveJobId(jobId)) {
      final result = await provider.completeJob(
        jobId: jobId,
        deliveryPhotoBytes: photoBytes,
        cashCollected: _order.paymentType == ScheduledPaymentType.cash,
      );
      if (!mounted) return;

      if (result == null) {
        AppHelpers.showSnackBar(
          context,
          provider.completeJobError ?? 'Failed to complete delivery',
          isError: true,
        );
        return;
      }

      final summary = result.summary;
      if (summary != null) {
        next = next.mergedWithSummary(summary);
      }
      AppHelpers.showSnackBar(context, result.message);
    }

    if (!mounted) return;
    await navigateToJobSuccessScreen(
      context,
      provider: provider,
      routeName: RouteNames.scheduledDeliveryCompleted,
      arguments: next,
      refreshScheduledBoards: isScheduledLiveJobId(jobId),
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
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    16.sw,
                    14.sh,
                    16.sw,
                    16.sh + bottomInset,
                  ),
                  children: [
                    _buildHandoverCard(),
                    SizedBox(height: 14.sh),
                    _buildUploadArea(),
                    SizedBox(height: 20.sh),
                    _buildCompleteButton(),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _headerGreen,
      padding: EdgeInsets.fromLTRB(12.sw, 10.sh, 12.sw, 10.sh),
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
                  'Complete delivery',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.ssp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 3.sh),
                Text(
                  '${order.customerName} · ${order.orderId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.ssp,
                    fontWeight: FontWeight.w500,
                    color: _reportText,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pushNamed(
                context,
                RouteNames.reportAtDropoff,
                arguments: {
                  'orderId': order.orderId,
                  'customerName': order.customerName,
                  'address': order.customerAddress,
                },
              ),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.sw, vertical: 6.sh),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      color: _reportText,
                      size: 13.ssp,
                    ),
                    SizedBox(width: 4.sw),
                    Text(
                      'Report',
                      style: TextStyle(
                        fontSize: 11.ssp,
                        fontWeight: FontWeight.w600,
                        color: _reportText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandoverCard() {
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
            'Handover',
            style: TextStyle(
              fontSize: 14.ssp,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              height: 1.25,
            ),
          ),
          SizedBox(height: 14.sh),
          _buildDetailRow(
            'Items',
            order.itemCount <= 0
                ? '—'
                : (order.itemCount == 1
                    ? '1 item'
                    : '${order.itemCount} items'),
          ),
          SizedBox(height: 10.sh),
          _buildDetailRow('Payment', _paymentDisplay),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.ssp,
            fontWeight: FontWeight.w400,
            color: _textMuted,
            height: 1.3,
          ),
        ),
        SizedBox(width: 12.sw),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13.ssp,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadArea() {
    final hasImage = _hasProofPhoto && _proofPhotoBytes != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _selectProofPhoto,
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
              height: 120.sh,
              color: _uploadBg,
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(
                          _proofPhotoBytes!,
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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.sw),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              color: _textPrimary,
              size: 24.ssp,
            ),
            SizedBox(height: 8.sh),
            Text(
              'Add proof of delivery',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.ssp,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                height: 1.2,
              ),
            ),
            SizedBox(height: 4.sh),
            Text(
              'Required',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.ssp,
                fontWeight: FontWeight.w400,
                color: _textMuted,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteButton() {
    final isCompleting = context.watch<OrderProvider>().isCompletingJob;
    final enabled = _hasProofPhoto && !isCompleting;

    return Opacity(
      opacity: enabled || isCompleting ? 1 : 0.45,
      child: SizedBox(
        width: double.infinity,
        height: 52.sh,
        child: Material(
          color: _headerGreen,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: enabled ? _completeDelivery : null,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: isCompleting
                  ? SizedBox(
                      width: 22.sw,
                      height: 22.sw,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: _white,
                      ),
                    )
                  : Text(
                      'Complete delivery',
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
      ),
    );
  }
}

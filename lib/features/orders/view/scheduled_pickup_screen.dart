import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/utils/app_helpers.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_order.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_shared.dart';
import 'package:yjeek_driver/routes/route_names.dart';

/// Scheduled pickup screen (Go to vendor → Arrived).
/// Confirm calls upload + `POST /drivers/jobs/:jobId/confirm-pickup`.
class ScheduledPickupScreen extends StatefulWidget {
  const ScheduledPickupScreen({
    super.key,
    required this.order,
  });

  final ScheduledDeliveryOrder order;

  @override
  State<ScheduledPickupScreen> createState() => _ScheduledPickupScreenState();
}

class _ScheduledPickupScreenState extends State<ScheduledPickupScreen> {
  static const Color _headerGreen = Color(0xFF4DB04F);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _screenBg = Color(0xFFF4F8F2);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF9E9E9E);
  static const Color _cardBorder = Color(0xFFE0E0E0);
  static const Color _qtyGreen = Color(0xFF2E7D32);
  static const Color _fragileBg = Color(0xFFFFF8E8);
  static const Color _fragileText = Color(0xFF8B6914);
  static const Color _reportText = Color(0xFFCFE3D5);
  static const Color _uploadBg = Color(0xFFF5F5F5);
  static const Color _uploadBorder = Color(0xFFBDBDBD);
  static const Color _radioEmpty = Color(0xFFBDBDBD);

  bool _itemsVerified = false;
  bool _packagingVerified = false;
  bool _hasPickupPhoto = false;
  Uint8List? _pickupPhotoBytes;
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
    final jobId = _thisJobId(provider);
    if (!isScheduledLiveJobId(jobId)) return;

    await provider.loadJobDetail(jobId);
    if (!mounted) return;
    final job = provider.currentJobDetail;
    if (job == null || job.id != jobId) return;
    setState(() => _order = _order.mergedWithJob(job));
  }

  String _thisJobId(OrderProvider provider) {
    final fromOrder = _order.liveJobId;
    if (isScheduledLiveJobId(fromOrder)) return fromOrder;
    return scheduledLiveJobId(_order, provider);
  }

  bool get _canConfirm =>
      _itemsVerified && _packagingVerified && _hasPickupPhoto;

  Future<void> _selectPickupPhoto() async {
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
        _pickupPhotoBytes = bytes;
        _hasPickupPhoto = true;
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

  Future<void> _confirmPickup() async {
    if (!_canConfirm) return;

    final provider = context.read<OrderProvider>();
    if (provider.isConfirmingPickup || provider.isArrivingAtPickup) return;

    final photoBytes = _pickupPhotoBytes;
    if (photoBytes == null) return;

    var next = _order;
    final jobId = _thisJobId(provider);

    if (isScheduledLiveJobId(jobId)) {
      final arrived = await _ensureArrivedAtVendor(provider, jobId);
      if (!mounted) return;
      if (!arrived) {
        AppHelpers.showSnackBar(
          context,
          provider.arrivePickupError ??
              'Arrive at the restaurant before confirming pickup',
          isError: true,
        );
        return;
      }

      final result = await provider.confirmPickup(
        jobId: jobId,
        pickupPhotoBytes: photoBytes,
      );
      if (!mounted) return;

      if (result == null) {
        final retryArrive = _isArriveFirstError(provider.confirmPickupError);
        if (retryArrive) {
          final arrivedAgain = await provider.arriveAtPickup(jobId);
          if (!mounted) return;
          if (arrivedAgain || _jobAllowsConfirm(provider, jobId)) {
            final retry = await provider.confirmPickup(
              jobId: jobId,
              pickupPhotoBytes: photoBytes,
            );
            if (!mounted) return;
            if (retry != null) {
              next = _order.mergedWithJob(retry);
              AppHelpers.showSnackBar(
                context,
                retry.progressLabel.isNotEmpty
                    ? retry.progressLabel
                    : 'Pickup confirmed',
              );
              Navigator.pushNamed(
                context,
                RouteNames.scheduledDeliverToCustomer,
                arguments: next,
              );
              return;
            }
          }
        }

        AppHelpers.showSnackBar(
          context,
          provider.confirmPickupError ?? 'Failed to confirm pickup',
          isError: true,
        );
        return;
      }

      next = _order.mergedWithJob(result);
      AppHelpers.showSnackBar(
        context,
        result.progressLabel.isNotEmpty
            ? result.progressLabel
            : 'Pickup confirmed',
      );
    }

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      RouteNames.scheduledDeliverToCustomer,
      arguments: next,
    );
  }

  Future<bool> _ensureArrivedAtVendor(
    OrderProvider provider,
    String jobId,
  ) async {
    var job = provider.currentJobDetail;
    if (job == null || job.id != jobId) {
      await provider.loadJobDetail(jobId);
      if (!mounted) return false;
      job = provider.currentJobDetail;
    }

    if (_jobAllowsConfirm(provider, jobId)) return true;

    final success = await provider.arriveAtPickup(jobId);
    if (!mounted) return false;
    if (success) return true;

    await provider.loadJobDetail(jobId);
    if (!mounted) return false;
    return _jobAllowsConfirm(provider, jobId);
  }

  bool _jobAllowsConfirm(OrderProvider provider, String jobId) {
    final job = provider.currentJobDetail;
    if (job == null || job.id != jobId) return false;
    if (job.isAtVendor) return true;
    if (job.canArriveAtCustomer) return true;
    if (!job.isPickupPhase) return true;
    return false;
  }

  bool _isArriveFirstError(String? message) {
    final text = (message ?? '').toLowerCase();
    return text.contains('arrive at the restaurant') ||
        text.contains('before confirming pickup');
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
                    _buildVerifyItemsCard(),
                    if (order.isFragileHighValue) ...[
                      SizedBox(height: 12.sh),
                      _buildFragileWarning(),
                    ],
                    SizedBox(height: 12.sh),
                    _buildPickupChecksCard(),
                    SizedBox(height: 14.sh),
                    _buildUploadArea(),
                    SizedBox(height: 20.sh),
                    _buildConfirmButton(),
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
                  'Pickup · scheduled',
                  style: TextStyle(
                    fontSize: 15.ssp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 3.sh),
                Text(
                  '${order.vendorName} · ${order.orderId}',
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
          GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              RouteNames.reportAtPickup,
              arguments: {
                'orderId': order.orderId,
                'vendorName': order.vendorName,
              },
            ),
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
        ],
      ),
    );
  }

  Widget _buildVerifyItemsCard() {
    final items = order.items;
    final isLoadingItems =
        context.watch<OrderProvider>().isLoadingJobDetail && items.isEmpty;

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
            'Verify items before you leave',
            style: TextStyle(
              fontSize: 14.ssp,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              height: 1.25,
            ),
          ),
          SizedBox(height: 14.sh),
          if (items.isEmpty)
            Text(
              isLoadingItems ? 'Loading items…' : 'No items listed',
              style: TextStyle(
                fontSize: 13.ssp,
                fontWeight: FontWeight.w500,
                color: _textMuted,
                height: 1.3,
              ),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              _buildItemRow(item: items[i]),
              if (i < items.length - 1) SizedBox(height: 12.sh),
            ],
        ],
      ),
    );
  }

  Widget _buildItemRow({required ScheduledOrderItem item}) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14.ssp,
          fontWeight: FontWeight.w500,
          color: _textPrimary,
          height: 1.35,
        ),
        children: [
          TextSpan(
            text: '${item.quantity} ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _qtyGreen,
            ),
          ),
          TextSpan(text: item.name),
        ],
      ),
    );
  }

  Widget _buildFragileWarning() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.sw, vertical: 12.sh),
      decoration: BoxDecoration(
        color: _fragileBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: _fragileText, size: 18.ssp),
          SizedBox(width: 10.sw),
          Expanded(
            child: Text(
              'Fragile / high-value items — handle with care and keep the packaging sealed.',
              style: TextStyle(
                fontSize: 12.ssp,
                fontWeight: FontWeight.w600,
                color: _fragileText,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupChecksCard() {
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
            'Pickup checks',
            style: TextStyle(
              fontSize: 14.ssp,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              height: 1.25,
            ),
          ),
          SizedBox(height: 14.sh),
          _buildCheckRow(
            value: _itemsVerified,
            label: 'Items match the order',
            onChanged: (v) => setState(() => _itemsVerified = v),
          ),
          SizedBox(height: 12.sh),
          _buildCheckRow(
            value: _packagingVerified,
            label: 'Packaging sealed & undamaged',
            onChanged: (v) => setState(() => _packagingVerified = v),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckIndicator(bool value) {
    if (value) {
      return Container(
        width: 22.ssp,
        height: 22.ssp,
        decoration: const BoxDecoration(
          color: _headerGreen,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check, color: _white, size: 14.ssp),
      );
    }

    return Container(
      width: 22.ssp,
      height: 22.ssp,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _radioEmpty, width: 1.5),
      ),
    );
  }

  Widget _buildCheckRow({
    required bool value,
    required String label,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          _buildCheckIndicator(value),
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
      ),
    );
  }

  Widget _buildUploadArea() {
    final hasImage = _hasPickupPhoto && _pickupPhotoBytes != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _selectPickupPhoto,
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
                          _pickupPhotoBytes!,
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
              'Add pickup photo',
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

  Widget _buildConfirmButton() {
    final isConfirming = context.watch<OrderProvider>().isConfirmingPickup;
    final isArriving = context.watch<OrderProvider>().isArrivingAtPickup;
    final busy = isConfirming || isArriving;
    final enabled = _canConfirm && !busy;

    return Opacity(
      opacity: enabled || busy ? 1 : 0.45,
      child: SizedBox(
        width: double.infinity,
        height: 52.sh,
        child: Material(
          color: _headerGreen,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: enabled ? _confirmPickup : null,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 22.sw,
                      height: 22.sw,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: _white,
                      ),
                    )
                  : Text(
                      'Confirm pickup & start delivery',
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

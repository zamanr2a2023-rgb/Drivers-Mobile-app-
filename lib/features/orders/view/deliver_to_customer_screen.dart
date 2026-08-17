import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/models/map_location.dart';
import 'package:yjeek_driver/core/services/map_service.dart';
import 'package:yjeek_driver/core/utils/app_helpers.dart';
import 'package:yjeek_driver/core/widgets/app_google_map.dart';
import 'package:yjeek_driver/features/orders/model/job_detail_model.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';
import 'package:yjeek_driver/features/orders/view/complete_delivery_screen.dart';
import 'package:yjeek_driver/features/orders/view/confirm_pickup_screen.dart';
import 'package:yjeek_driver/features/orders/view/go_to_restaurant_screen.dart';
import 'package:yjeek_driver/routes/route_names.dart';

/// “Deliver to customer” screen (Instant Active → Continue).
/// Loads job details from `GET /drivers/jobs/:jobId`.
/// Shown inside Orders tab so BottomNavigation stays on Orders.
class DeliverToCustomerScreen extends StatefulWidget {
  const DeliverToCustomerScreen({
    super.key,
    required this.onBack,
    required this.jobId,
  });

  final VoidCallback onBack;
  final String jobId;

  @override
  State<DeliverToCustomerScreen> createState() =>
      _DeliverToCustomerScreenState();
}

class _DeliverToCustomerScreenState extends State<DeliverToCustomerScreen> {
  static const Color _headerGreen = Color(0xFF4DB04F);
  static const Color _screenBg = Color(0xFFF4F8F2);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF9E9E9E);
  static const Color _cardBorder = Color(0xFFE0E0E0);
  static const Color _prepaidBg = Color(0xFFE8F5E9);
  static const Color _prepaidText = Color(0xFF2E7D32);
  static const Color _codBg = Color(0xFFFFF0DE);
  static const Color _codOrange = Color(0xFFE67E22);
  static const Color _reportText = Color(0xFFCFE3D5);
  static const Color _reportBg = Color(0xFFFFF8F3);
  static const Color _reportBorder = Color(0xFFF5A623);
  static const Color _reportOrange = Color(0xFFE67E22);
  static const Color _navigateBlack = Color(0xFF1A1A1A);

  static const String _cashIconAsset =
      'assets/images/cash_on_delivery_icon.png';

  bool _showCompleteDelivery = false;
  bool _didRedirectPickup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OrderProvider>().loadJobDetail(widget.jobId);
    });
  }

  void _openCompleteDelivery() {
    Navigator.pushNamed(context, RouteNames.completeDelivery);
  }

  Future<void> _arriveAtCustomer() async {
    final provider = context.read<OrderProvider>();
    if (provider.isArrivingAtCustomer) return;

    final job = provider.currentJobDetail;
    if (job != null && job.isPickupPhase) {
      AppHelpers.showSnackBar(
        context,
        'Pick up the order before arriving at the customer',
        isError: true,
      );
      _redirectToPickupFlow(job);
      return;
    }

    final arrivedStatus = job?.status.trim().toUpperCase() ?? '';
    if (arrivedStatus == 'AT_CUSTOMER' ||
        arrivedStatus == 'ARRIVED' ||
        arrivedStatus == 'ARRIVED_CUSTOMER') {
      _openCompleteDelivery();
      return;
    }

    final success = await provider.arriveAtCustomer(widget.jobId);
    if (!mounted) return;

    if (success) {
      _openCompleteDelivery();
      return;
    }

    AppHelpers.showSnackBar(
      context,
      provider.arriveCustomerError ?? 'Failed to mark arrived at customer',
      isError: true,
    );
  }

  void _redirectToPickupFlow(JobDetailModel job) {
    if (!mounted || _didRedirectPickup) return;
    _didRedirectPickup = true;

    final navigator = Navigator.of(context);
    final restaurant = job.order.vendor.name.trim().isNotEmpty
        ? job.order.vendor.name.trim()
        : 'Vendor';
    final pickupLocation = job.order.vendor.area.trim().isNotEmpty
        ? job.order.vendor.area.trim()
        : (job.order.vendor.city.trim().isNotEmpty
            ? job.order.vendor.city.trim()
            : 'Pickup');
    final eta = job.estimatedDurationMin > 0
        ? '~${job.estimatedDurationMin} min'
        : '—';
    final distance = job.distanceKm > 0
        ? '${job.distanceKm.toStringAsFixed(1)} km'
        : '—';

    widget.onBack();

    if (job.isAtVendor) {
      navigator.pushNamed(
        RouteNames.confirmPickup,
        arguments: ConfirmPickupArgs(
          orderId: job.id,
          restaurantName: restaurant,
        ),
      );
      return;
    }

    navigator.pushNamed(
      RouteNames.goToRestaurant,
      arguments: GoToRestaurantArgs(
        orderId: job.id,
        restaurantName: restaurant,
        pickupLocation: pickupLocation,
        distance: distance,
        estimatedTime: eta,
      ),
    );
  }

  void _closeCompleteDelivery() {
    setState(() => _showCompleteDelivery = false);
  }

  void _handleBack() {
    context.read<OrderProvider>().clearJobDetail();
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    if (_showCompleteDelivery) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: CompleteDeliveryScreen(
          onBack: _closeCompleteDelivery,
        ),
      );
    }

    final provider = context.watch<OrderProvider>();
    final job = provider.currentJobDetail;
    final isLoading = provider.isLoadingJobDetail;
    final isArriving = provider.isArrivingAtCustomer;
    final error = provider.jobDetailError;
    final topInset = MediaQuery.paddingOf(context).top;

    if (job != null &&
        job.id == widget.jobId &&
        job.isPickupPhase &&
        !_didRedirectPickup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _redirectToPickupFlow(job);
      });
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _handleBack();
        },
        child: ColoredBox(
          color: _screenBg,
          child: Column(
            children: [
              ColoredBox(
                color: Colors.white,
                child: SizedBox(height: topInset),
              ),
              _buildHeader(job),
              Expanded(
                child: _buildBody(
                  isLoading: isLoading,
                  isArriving: isArriving,
                  error: error,
                  job: job,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required bool isLoading,
    required bool isArriving,
    required String? error,
    required JobDetailModel? job,
  }) {
    if (isLoading && job == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: _headerGreen,
          strokeWidth: 2.5,
        ),
      );
    }

    if (error != null && job == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
        children: [
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () =>
                  context.read<OrderProvider>().loadJobDetail(widget.jobId),
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    if (job == null) {
      return const Center(
        child: Text(
          'Job not found',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _textMuted,
          ),
        ),
      );
    }

    final dropoff = MapLocation.tryParse(
      latitude: job.order.address.latitude,
      longitude: job.order.address.longitude,
      label: job.order.customer.displayName,
      kind: MapLocationKind.dropoff,
    );
    final pickup = MapLocation.tryParse(
      latitude: job.order.vendor.latitude,
      longitude: job.order.vendor.longitude,
      label: job.order.vendor.name,
      kind: MapLocationKind.pickup,
    );

    return RefreshIndicator(
      color: _headerGreen,
      onRefresh: () =>
          context.read<OrderProvider>().loadJobDetail(widget.jobId),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          AppGoogleMap(
            height: 200,
            pickup: pickup,
            dropoff: dropoff,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: Column(
              children: [
                _buildDropOffCard(job),
                const SizedBox(height: 12),
                if (job.requiresCashCollection)
                  _buildCashBanner(job)
                else
                  _buildPrepaidBanner(),
                const SizedBox(height: 14),
                _buildReportNavigateRow(job),
                const SizedBox(height: 12),
                _buildArrivedButton(
                  isArriving: isArriving,
                  enabled: !job.isPickupPhase,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(JobDetailModel? job) {
    final subtitle = job?.distanceEtaLabel ?? '…';

    return Container(
      width: double.infinity,
      color: _headerGreen,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.22),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _handleBack,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deliver to customer',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
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
              onTap: () {
                final address = job?.order.address.navigationAddress ?? '';
                final customerName = job?.order.customer.displayName ?? '';
                final orderId = (job?.order.displayOrderNumber.trim().isNotEmpty ??
                        false)
                    ? job!.order.displayOrderNumber
                    : (job?.id ?? '');
                Navigator.pushNamed(
                  context,
                  RouteNames.reportAtDropoff,
                  arguments: {
                    'orderId': orderId,
                    'customerName': customerName,
                    'address': address,
                  },
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      color: _reportText,
                      size: 13,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Report',
                      style: TextStyle(
                        fontSize: 11,
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

  Widget _buildDropOffCard(JobDetailModel job) {
    final order = job.order;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Drop-off',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          _buildDetailRow('Customer', order.customer.displayName),
          const SizedBox(height: 10),
          _buildDetailRow('Phone', order.customer.displayPhone),
          const SizedBox(height: 10),
          _buildDetailRow('Address', order.address.shortLabel),
          const SizedBox(height: 10),
          _buildDetailRow('Window', order.windowLabel),
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
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: _textMuted,
            height: 1.3,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrepaidBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _prepaidBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.check_box_outlined, color: _prepaidText, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Prepaid order — no cash to collect.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _prepaidText,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashBanner(JobDetailModel job) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _codBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SizedBox(
              width: 22,
              height: 13,
              child: Image.asset(
                _cashIconAsset,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.payments_outlined,
                  color: _codOrange,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Collect cash on delivery',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _codOrange,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  job.order.cashCollectLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _codOrange,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportNavigateRow(JobDetailModel job) {
    final address = job.order.address.navigationAddress;
    final customerName = job.order.customer.displayName;
    final orderId = job.order.displayOrderNumber.isNotEmpty
        ? job.order.displayOrderNumber
        : job.id;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: Material(
              color: _reportBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: _reportBorder, width: 1.2),
              ),
              child: InkWell(
                onTap: () => Navigator.pushNamed(
                  context,
                  RouteNames.reportAtDropoff,
                  arguments: {
                    'orderId': orderId,
                    'customerName': customerName,
                    'address': address,
                  },
                ),
                borderRadius: BorderRadius.circular(14),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      color: _reportOrange,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Report',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _reportOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 48,
            child: Material(
              color: _navigateBlack,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () {
                  final lat = job.order.address.latitude;
                  final lng = job.order.address.longitude;
                  if (lat != null && lng != null) {
                    MapService.openNavigationOrShowError(
                      context,
                      latitude: lat,
                      longitude: lng,
                      address: address,
                    );
                  } else {
                    MapService.openNavigationOrShowError(
                      context,
                      address: address,
                    );
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.near_me,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Navigate',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArrivedButton({
    required bool isArriving,
    required bool enabled,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: enabled ? _headerGreen : _headerGreen.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: isArriving ? null : _arriveAtCustomer,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: isArriving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    enabled ? 'Arrived at customer' : 'Pick up order first',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

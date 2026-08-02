import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/utils/app_helpers.dart';
import 'package:yjeek_driver/features/orders/model/job_board_model.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';
import 'package:yjeek_driver/features/orders/view/deliver_to_customer_screen.dart';
import 'package:yjeek_driver/features/orders/view/reject_scheduled_order_screen.dart';
import 'package:yjeek_driver/features/orders/view/release_scheduled_order_screen.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_completed_order_detail.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_order.dart';
import 'package:yjeek_driver/navigation/orders_nav_signal.dart';
import 'package:yjeek_driver/routes/route_names.dart';

/// Orders screen — Instant + Scheduled tabs.
/// Instant + Scheduled New load from `/drivers/jobs/board`.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({
    super.key,
    this.initialSegment = 0,
  });

  /// 0 = Instant, 1 = Scheduled
  final int initialSegment;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  // Shared palette for Instant (existing) + Scheduled (Figma)
  static const Color _screenBg = Color(0xFFF9F9F9);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF6B756E);
  static const Color _textMuted = Color(0xFF9E9E9E);
  static const Color _green = Color(0xFF4DB04F);
  static const Color _greenDark = Color(0xFF2E7D32);
  static const Color _greenPillBg = Color(0xFFE8F5E9);
  static const Color _red = Color(0xFFD32F2F);
  static const Color _redPillBg = Color(0xFFFFEBEE);
  static const Color _cardBorder = Color(0xFFE0E0E0);
  static const Color _segmentBg = Color(0xFFF0F0F0);
  static const Color _progressTrack = Color(0xFFE8F0E9);
  static const Color _chipBorder = Color(0xFFE0E0E0);
  static const Color _rejectRed = Color(0xFFFF3B30);
  static const Color _onTrackBadgeBg = Color(0xFFE3F0FD);
  static const Color _onTrackBadgeText = Color(0xFF4A90E2);
  static const Color _trackLinkBlue = Color(0xFF1976D2);
  static const Color _releaseText = Color(0xFF424242);

  static const double _hPad = 16;

  late int _segment; // 0 Instant, 1 Scheduled
  int _scheduledFilter =
      0; // 0 New, 1 Require confirmation, 2 On track, 3 Completed
  bool _showReleaseScreen = false;
  bool _showRejectScreen = false;
  bool _showDeliverToCustomer = false;
  String _activeJobId = '';
  String _releaseOrderId = '#YJK-...52';
  String _rejectOrderId = '#YJK-...50';
  String _rejectJobId = '';

  late List<_ConfirmScheduledOrder> _confirmOrdersList;

  static const _initialConfirmOrders = [
    _ConfirmScheduledOrder(
      id: '#YJK-...52',
      jobId: '',
      route: 'Lulu Express → Seef',
      window: 'Today · 6–8 PM',
      respondIn: 'Respond within 19 min',
    ),
  ];

  static const _onTrackOrders = [
    ScheduledDeliveryOrder(
      orderId: '#YJK-...52',
      vendorName: 'Lulu Express',
      vendorAddress: 'Seef, Bldg 428, Road 2825',
      category: 'Electronics · Perfume',
      customerName: 'Sara A.',
      customerPhone: '+973 3300 0000',
      customerAddress: 'Adliya, Bldg 23, Road 2825, Flat 82',
      scheduledWindow: 'Today · 6–8 PM',
      pickupDeadlineNotice: 'Pick up by 5:45 PM to stay on schedule.',
      distance: '1.4 km',
      eta: '~8 min',
      items: [
        ScheduledOrderItem(quantity: '1×', name: 'Wireless earbuds'),
        ScheduledOrderItem(quantity: '1×', name: 'Perfume 50 ml'),
        ScheduledOrderItem(quantity: '1×', name: 'Phone case'),
      ],
      isFragileHighValue: true,
      paymentType: ScheduledPaymentType.prepaid,
      earnings: '2.600',
      tip: '0.300',
      totalDeliveryTime: '22 min',
      deliveryDistance: '4.2 km',
      deliveryEta: '~18 min',
      orderTypeLabel: 'Scheduled · Normal',
      cardRouteLabel: 'Lulu Express → Adliya',
      cardStatusLine: 'Heading to vendor · pickup by 5:45 PM',
    ),
    ScheduledDeliveryOrder(
      orderId: '#YJK-...48',
      vendorName: 'VEERA',
      vendorAddress: 'Juffair, Bldg 120, Road 4012',
      category: 'Fashion · Accessories',
      customerName: 'Ahmed K.',
      customerPhone: '+973 3900 1122',
      customerAddress: 'Juffair, Bldg 45, Road 3801, Flat 9',
      scheduledWindow: 'Today · 7–9 PM',
      pickupDeadlineNotice: 'Pick up by 7:10 PM to stay on schedule.',
      distance: '2.1 km',
      eta: '~12 min',
      items: [
        ScheduledOrderItem(quantity: '1×', name: 'Leather wallet'),
        ScheduledOrderItem(quantity: '2×', name: 'Sunglasses'),
      ],
      isFragileHighValue: false,
      paymentType: ScheduledPaymentType.cash,
      cashAmount: 'BHD 12.500',
      earnings: '2.100',
      tip: '0.200',
      totalDeliveryTime: '28 min',
      deliveryDistance: '5.1 km',
      deliveryEta: '~22 min',
      orderTypeLabel: 'Scheduled · Normal',
      cardRouteLabel: 'VEERA → Juffair',
      cardStatusLine: 'Heading to vendor · pickup by 7:10 PM',
    ),
  ];

  static const _completedOrders = [
    ScheduledCompletedOrderDetail(
      orderId: '#YJK-...52',
      cardRouteLabel: 'Vapeology → Adliya',
      scheduledWindow: 'Today · 6–8 PM',
      deliveredAtLabel: 'Delivered 1:48 PM ·',
      vendorName: 'Vapeology',
      vendorAddress: 'Seef · Bldg 210',
      distance: '1.4 km',
      eta: '~6 min',
      categoryBadge: 'Vape · 18+',
      isVapeRestricted: true,
    ),
    ScheduledCompletedOrderDetail(
      orderId: '#YJK-...39',
      cardRouteLabel: 'Lulu Express → Seef',
      scheduledWindow: 'Yesterday · 6–8 PM',
      deliveredAtLabel: 'Delivered 7:42 PM ·',
      vendorName: 'Lulu Express',
      vendorAddress: 'Seef Mall · Ground Floor',
      distance: '2.1 km',
      eta: '~8 min',
      categoryBadge: 'Groceries',
      isVapeRestricted: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _segment = widget.initialSegment.clamp(0, 1);
    _confirmOrdersList =
        List<_ConfirmScheduledOrder>.from(_initialConfirmOrders);
    OrdersNavSignal.pendingSegment.addListener(_onNavSignal);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumeNavSignal();
      if (!mounted) return;
      if (_segment == 0) {
        context.read<OrderProvider>().loadInstantJobsBoard();
      } else {
        context.read<OrderProvider>().loadScheduledNewJobsBoard();
      }
    });
  }

  Future<void> _onDoubleConfirm(_ConfirmScheduledOrder order) async {
    final provider = context.read<OrderProvider>();
    if (provider.isConfirmingOrder) return;

    final jobId = order.jobId.trim().isNotEmpty ? order.jobId.trim() : order.id;
    if (jobId.isEmpty || jobId.startsWith('#')) {
      // Keep local mock behavior when no real job id is available.
      setState(() {
        _confirmOrdersList.removeWhere(
          (item) => item.id == order.id && item.jobId == order.jobId,
        );
        _scheduledFilter = 2; // On track
        _segment = 1;
      });
      return;
    }

    final result = await provider.confirmOrder(jobId);
    if (!mounted) return;

    if (result != null) {
      setState(() {
        _confirmOrdersList.removeWhere(
          (item) =>
              item.jobId == jobId ||
              item.id == order.id ||
              item.id == result.order.displayOrderNumber,
        );
        _scheduledFilter = 2; // On track
        _segment = 1;
      });
      AppHelpers.showSnackBar(
        context,
        result.progressLabel.isNotEmpty
            ? result.progressLabel
            : 'Order confirmed',
      );
      return;
    }

    AppHelpers.showSnackBar(
      context,
      provider.confirmOrderError ?? 'Failed to confirm order',
      isError: true,
    );
  }

  void _acceptNewOrder(_NewScheduledOrder order) {
    context.read<OrderProvider>().removeScheduledNewJob(
          order.jobId.isNotEmpty ? order.jobId : order.id,
        );
    setState(() {
      _confirmOrdersList.insert(
        0,
        _ConfirmScheduledOrder(
          id: order.id,
          jobId: order.jobId,
          route: order.route,
          window: order.window,
          respondIn: order.respondIn,
        ),
      );
      _scheduledFilter = 1; // Require confirmation
      _segment = 1;
      _showRejectScreen = false;
      _showReleaseScreen = false;
      _showDeliverToCustomer = false;
    });
  }

  void _openReject(_NewScheduledOrder order) {
    setState(() {
      _rejectOrderId = order.id;
      _rejectJobId = order.jobId.isNotEmpty ? order.jobId : order.id;
      _showRejectScreen = true;
      _showReleaseScreen = false;
      _showDeliverToCustomer = false;
      _scheduledFilter = 0;
      _segment = 1;
    });
  }

  void _closeReject() {
    setState(() {
      _showRejectScreen = false;
      _scheduledFilter = 0; // Back to New
      _segment = 1;
    });
  }

  void _submitReject(String reason, String note) {
    context.read<OrderProvider>().removeScheduledNewJob(_rejectJobId);
    setState(() {
      _showRejectScreen = false;
      _scheduledFilter = 0; // Stay on New
      _segment = 1;
    });
  }

  void _openRelease(String orderId) {
    setState(() {
      _releaseOrderId = orderId;
      _showReleaseScreen = true;
      _showRejectScreen = false;
      _showDeliverToCustomer = false;
      _scheduledFilter = 1;
      _segment = 1;
    });
  }

  void _closeRelease() {
    setState(() => _showReleaseScreen = false);
  }

  void _submitRelease(String reason, String note) {
    setState(() {
      _confirmOrdersList.removeWhere((order) => order.id == _releaseOrderId);
      _showReleaseScreen = false;
      _scheduledFilter = 1; // Stay on Require confirmation
      _segment = 1;
    });
  }

  void _openDeliverToCustomer(String jobId) {
    setState(() {
      _activeJobId = jobId;
      _showDeliverToCustomer = true;
      _showRejectScreen = false;
      _showReleaseScreen = false;
      _segment = 0; // Instant
    });
  }

  void _closeDeliverToCustomer() {
    setState(() {
      _showDeliverToCustomer = false;
      _activeJobId = '';
      _segment = 0; // Back to Instant
    });
  }

  @override
  void dispose() {
    OrdersNavSignal.pendingSegment.removeListener(_onNavSignal);
    super.dispose();
  }

  void _onNavSignal() => _consumeNavSignal();

  void _consumeNavSignal() {
    final pending = OrdersNavSignal.pendingSegment.value;
    if (pending == null || !mounted) return;
    final scheduledFilter = OrdersNavSignal.pendingScheduledFilter.value;
    setState(() {
      _segment = pending.clamp(0, 1);
      if (_segment == 1) {
        _scheduledFilter = scheduledFilter ?? 0;
      }
      _showRejectScreen = false;
      _showReleaseScreen = false;
      _showDeliverToCustomer = false;
    });
    OrdersNavSignal.clear();
    if (_segment == 0) {
      context.read<OrderProvider>().loadInstantJobsBoard();
    } else if (_scheduledFilter == 0) {
      context.read<OrderProvider>().loadScheduledNewJobsBoard();
    }
  }

  void _openScheduledTrack(ScheduledDeliveryOrder order) {
    Navigator.pushNamed(
      context,
      RouteNames.goToVendorScheduled,
      arguments: order,
    );
  }

  void _openCompletedOrderDetail(ScheduledCompletedOrderDetail order) {
    Navigator.pushNamed(
      context,
      RouteNames.scheduledCompletedOrderDetail,
      arguments: order,
    );
  }

  void selectSegment(int index) {
    final next = index.clamp(0, 1);
    setState(() => _segment = next);
    if (next == 0) {
      context.read<OrderProvider>().loadInstantJobsBoard();
    } else if (_scheduledFilter == 0) {
      context.read<OrderProvider>().loadScheduledNewJobsBoard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersProvider = context.watch<OrderProvider>();

    if (_showDeliverToCustomer) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: DeliverToCustomerScreen(
          jobId: _activeJobId,
          onBack: _closeDeliverToCustomer,
        ),
      );
    }

    if (_showRejectScreen) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: RejectScheduledOrderScreen(
          orderId: _rejectOrderId,
          onBack: _closeReject,
          onKeepOrder: _closeReject,
          onSubmitDecline: _submitReject,
        ),
      );
    }

    if (_showReleaseScreen) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: ReleaseScheduledOrderScreen(
          orderId: _releaseOrderId,
          onBack: _closeRelease,
          onKeepOrder: _closeRelease,
          onSubmitRelease: _submitRelease,
        ),
      );
    }

    final scheduledFilters = [
      'New (${ordersProvider.scheduledNewCount})',
      'Require confirmation (${_confirmOrdersList.length})',
      'On track (2)',
      'Completed (2)',
    ];

    return Scaffold(
      backgroundColor: _screenBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Orders',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                      height: 1.15,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SegmentedTabs(
                    selectedIndex: _segment,
                    onChanged: selectSegment,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _segment == 0
                  ? _InstantOrdersBody(
                      onContinue: _openDeliverToCustomer,
                    )
                  : _ScheduledOrdersBody(
                      filters: scheduledFilters,
                      selectedFilter: _scheduledFilter,
                      onFilterChanged: (i) {
                        setState(() => _scheduledFilter = i);
                        if (i == 0) {
                          context
                              .read<OrderProvider>()
                              .loadScheduledNewJobsBoard();
                        }
                      },
                      newOrders: ordersProvider.scheduledNewJobs
                          .map(_NewScheduledOrder.fromJob)
                          .toList(growable: false),
                      isLoadingNew: ordersProvider.isLoadingScheduledNewBoard,
                      newError: ordersProvider.scheduledNewBoardError,
                      onRefreshNew: () => context
                          .read<OrderProvider>()
                          .loadScheduledNewJobsBoard(),
                      confirmOrders: _confirmOrdersList,
                      onTrackOrders: _onTrackOrders,
                      onTrackOrderTap: _openScheduledTrack,
                      completedOrders: _completedOrders,
                      onCompletedOrderTap: _openCompletedOrderDetail,
                      onDoubleConfirm: _onDoubleConfirm,
                      onRelease: _openRelease,
                      onAcceptNew: _acceptNewOrder,
                      onRejectNew: _openReject,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Instant (API-backed, same design) ──────────────────────────────────────

class _InstantOrdersBody extends StatelessWidget {
  const _InstantOrdersBody({required this.onContinue});

  final ValueChanged<String> onContinue;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final isLoading = provider.isLoadingInstantBoard;
    final error = provider.instantBoardError;
    final activeJobs = provider.instantActiveJobs;
    final completedJobs = provider.instantCompletedJobs;
    final hasJobs = activeJobs.isNotEmpty || completedJobs.isNotEmpty;

    if (isLoading && !hasJobs && error == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: _OrdersScreenState._green,
          strokeWidth: 2.5,
        ),
      );
    }

    if (error != null && !hasJobs) {
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
              color: _OrdersScreenState._textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () =>
                  context.read<OrderProvider>().loadInstantJobsBoard(),
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      color: _OrdersScreenState._green,
      onRefresh: () => context.read<OrderProvider>().loadInstantJobsBoard(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          const Text(
            'Active',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _OrdersScreenState._textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (activeJobs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'No active orders',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _OrdersScreenState._textMuted,
                ),
              ),
            )
          else
            ...activeJobs.map(
              (job) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ActiveOrderCard(
                  job: job,
                  onContinue: () => onContinue(job.id),
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            'Completed',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _OrdersScreenState._textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (completedJobs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'No completed orders',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _OrdersScreenState._textMuted,
                ),
              ),
            )
          else
            ...completedJobs.map(
              (job) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CompletedOrderCard(job: job),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Scheduled filters (New / Require confirmation / On track) ───────────────

class _NewScheduledOrder {
  const _NewScheduledOrder({
    required this.id,
    required this.route,
    required this.window,
    required this.respondIn,
    this.jobId = '',
  });

  factory _NewScheduledOrder.fromJob(JobsBoardJob job) {
    return _NewScheduledOrder(
      id: job.displayOrderId,
      jobId: job.id,
      route: job.displayRoute,
      window: job.scheduledWindowLabel,
      respondIn: job.respondWithinLabel,
    );
  }

  final String id;
  final String jobId;
  final String route;
  final String window;
  final String respondIn;
}

class _ConfirmScheduledOrder {
  const _ConfirmScheduledOrder({
    required this.id,
    this.jobId = '',
    required this.route,
    required this.window,
    required this.respondIn,
  });

  final String id;
  final String jobId;
  final String route;
  final String window;
  final String respondIn;
}

class _ScheduledOrdersBody extends StatelessWidget {
  const _ScheduledOrdersBody({
    required this.filters,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.newOrders,
    required this.isLoadingNew,
    required this.newError,
    required this.onRefreshNew,
    required this.confirmOrders,
    required this.onTrackOrders,
    required this.onTrackOrderTap,
    required this.completedOrders,
    required this.onCompletedOrderTap,
    required this.onDoubleConfirm,
    required this.onRelease,
    required this.onAcceptNew,
    required this.onRejectNew,
  });

  final List<String> filters;
  final int selectedFilter;
  final ValueChanged<int> onFilterChanged;
  final List<_NewScheduledOrder> newOrders;
  final bool isLoadingNew;
  final String? newError;
  final Future<void> Function() onRefreshNew;
  final List<_ConfirmScheduledOrder> confirmOrders;
  final List<ScheduledDeliveryOrder> onTrackOrders;
  final ValueChanged<ScheduledDeliveryOrder> onTrackOrderTap;
  final List<ScheduledCompletedOrderDetail> completedOrders;
  final ValueChanged<ScheduledCompletedOrderDetail> onCompletedOrderTap;
  final ValueChanged<_ConfirmScheduledOrder> onDoubleConfirm;
  final ValueChanged<String> onRelease;
  final ValueChanged<_NewScheduledOrder> onAcceptNew;
  final ValueChanged<_NewScheduledOrder> onRejectNew;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 14),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final selected = selectedFilter == index;
              return GestureDetector(
                onTap: () => onFilterChanged(index),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? _OrdersScreenState._green
                        : _OrdersScreenState._surface,
                    borderRadius: BorderRadius.circular(20),
                    border: selected
                        ? null
                        : Border.all(color: _OrdersScreenState._chipBorder),
                  ),
                  child: Text(
                    filters[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : _OrdersScreenState._textPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Expanded(child: _buildFilterList()),
      ],
    );
  }

  Widget _buildFilterList() {
    switch (selectedFilter) {
      case 1:
        if (confirmOrders.isEmpty) {
          return const Center(
            child: Text(
              'No orders needing confirmation',
              style: TextStyle(
                fontSize: 14,
                color: _OrdersScreenState._textMuted,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: confirmOrders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _RequireConfirmCard(
            data: confirmOrders[index],
            onDoubleConfirm: () => onDoubleConfirm(confirmOrders[index]),
            onRelease: () => onRelease(confirmOrders[index].id),
          ),
        );
      case 2:
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: onTrackOrders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _OnTrackCard(
            data: onTrackOrders[index],
            onTap: () => onTrackOrderTap(onTrackOrders[index]),
          ),
        );
      case 3:
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: completedOrders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _CompletedScheduledCard(
            data: completedOrders[index],
            onTap: () => onCompletedOrderTap(completedOrders[index]),
          ),
        );
      case 0:
      default:
        if (isLoadingNew && newOrders.isEmpty && newError == null) {
          return const Center(
            child: CircularProgressIndicator(
              color: _OrdersScreenState._green,
              strokeWidth: 2.5,
            ),
          );
        }

        if (newError != null && newOrders.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            children: [
              Text(
                newError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _OrdersScreenState._textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: onRefreshNew,
                  child: const Text('Retry'),
                ),
              ),
            ],
          );
        }

        if (newOrders.isEmpty) {
          return RefreshIndicator(
            color: _OrdersScreenState._green,
            onRefresh: onRefreshNew,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
              children: const [
                Text(
                  'No new scheduled orders',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: _OrdersScreenState._textMuted,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: _OrdersScreenState._green,
          onRefresh: onRefreshNew,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: newOrders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _NewScheduledCard(
              data: newOrders[index],
              onAccept: () => onAcceptNew(newOrders[index]),
              onReject: () => onRejectNew(newOrders[index]),
            ),
          ),
        );
    }
  }
}

class _NewScheduledCard extends StatelessWidget {
  const _NewScheduledCard({
    required this.data,
    required this.onAccept,
    required this.onReject,
  });

  final _NewScheduledOrder data;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: _OrdersScreenState._surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _OrdersScreenState._cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.id,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _OrdersScreenState._textPrimary,
                  ),
                ),
              ),
              const _StatusPill(
                label: 'NEW',
                background: _OrdersScreenState._greenPillBg,
                foreground: _OrdersScreenState._greenDark,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data.route,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _OrdersScreenState._textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Window',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: _OrdersScreenState._textMuted,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  data.window,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _OrdersScreenState._green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            data.respondIn,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _OrdersScreenState._textMuted,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: Material(
                    color: _OrdersScreenState._green,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: onAccept,
                      borderRadius: BorderRadius.circular(12),
                      child: const Center(
                        child: Text(
                          'Accept',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: Material(
                    color: _OrdersScreenState._surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: _OrdersScreenState._cardBorder,
                      ),
                    ),
                    child: InkWell(
                      onTap: onReject,
                      borderRadius: BorderRadius.circular(12),
                      child: const Center(
                        child: Text(
                          'Reject',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _OrdersScreenState._rejectRed,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequireConfirmCard extends StatelessWidget {
  const _RequireConfirmCard({
    required this.data,
    required this.onDoubleConfirm,
    required this.onRelease,
  });

  final _ConfirmScheduledOrder data;
  final VoidCallback onDoubleConfirm;
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context) {
    final isConfirming = context.watch<OrderProvider>().isConfirmingOrder;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: _OrdersScreenState._surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _OrdersScreenState._cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.id,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _OrdersScreenState._textPrimary,
                  ),
                ),
              ),
              const _StatusPill(
                label: 'ACCEPTED',
                background: _OrdersScreenState._greenPillBg,
                foreground: _OrdersScreenState._greenDark,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data.route,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _OrdersScreenState._textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Window',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: _OrdersScreenState._textMuted,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  data.window,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _OrdersScreenState._green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            data.respondIn,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _OrdersScreenState._textMuted,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: Material(
                    color: _OrdersScreenState._green,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: isConfirming ? null : onDoubleConfirm,
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: isConfirming
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Double-confirm',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: Material(
                    color: _OrdersScreenState._surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: _OrdersScreenState._cardBorder,
                      ),
                    ),
                    child: InkWell(
                      onTap: isConfirming ? null : onRelease,
                      borderRadius: BorderRadius.circular(12),
                      child: const Center(
                        child: Text(
                          'Release',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _OrdersScreenState._releaseText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OnTrackCard extends StatelessWidget {
  const _OnTrackCard({
    required this.data,
    required this.onTap,
  });

  final ScheduledDeliveryOrder data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: _OrdersScreenState._surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _OrdersScreenState._cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.orderId,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _OrdersScreenState._textPrimary,
                  ),
                ),
              ),
              const _StatusPill(
                label: 'ON TRACK',
                background: _OrdersScreenState._onTrackBadgeBg,
                foreground: _OrdersScreenState._onTrackBadgeText,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data.cardRouteLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _OrdersScreenState._textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Window',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: _OrdersScreenState._textMuted,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  data.scheduledWindow,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _OrdersScreenState._green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            data.cardStatusLine,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _OrdersScreenState._textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tap to track delivery',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _OrdersScreenState._trackLinkBlue,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: _OrdersScreenState._trackLinkBlue,
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
}

class _CompletedScheduledCard extends StatelessWidget {
  const _CompletedScheduledCard({
    required this.data,
    required this.onTap,
  });

  final ScheduledCompletedOrderDetail data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: _OrdersScreenState._surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _OrdersScreenState._cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data.orderId,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _OrdersScreenState._textPrimary,
                      ),
                    ),
                  ),
                  const _StatusPill(
                    label: 'DELIVERED',
                    background: _OrdersScreenState._greenPillBg,
                    foreground: _OrdersScreenState._greenDark,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                data.cardRouteLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _OrdersScreenState._textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Window',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: _OrdersScreenState._textMuted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      data.scheduledWindow,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _OrdersScreenState._green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                data.deliveredAtLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: _OrdersScreenState._textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared Instant widgets (unchanged visuals) ─────────────────────────────

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _OrdersScreenState._segmentBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentTab(
              label: 'Instant',
              selected: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _SegmentTab(
              label: 'Scheduled',
              selected: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _OrdersScreenState._surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected
                ? _OrdersScreenState._textPrimary
                : _OrdersScreenState._textMuted,
          ),
        ),
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({
    required this.job,
    required this.onContinue,
  });

  final JobsBoardJob job;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final eta = job.etaLabel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _OrdersScreenState._surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _OrdersScreenState._green, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusPill(
                label: job.displayStatusLabel,
                background: _OrdersScreenState._greenPillBg,
                foreground: _OrdersScreenState._greenDark,
              ),
              const Spacer(),
              if (eta.isNotEmpty)
                Text(
                  eta,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _OrdersScreenState._green,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            job.displayRoute,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _OrdersScreenState._textPrimary,
              height: 1.3,
            ),
          ),
          if (job.activeSubtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              job.activeSubtitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: _OrdersScreenState._textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: job.progressValue,
              minHeight: 6,
              backgroundColor: _OrdersScreenState._progressTrack,
              color: _OrdersScreenState._green,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  job.arrivingLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _OrdersScreenState._textPrimary,
                  ),
                ),
              ),
              SizedBox(
                height: 36,
                child: Material(
                  color: _OrdersScreenState._green,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: onContinue,
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Center(
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompletedOrderCard extends StatelessWidget {
  const _CompletedOrderCard({required this.job});

  final JobsBoardJob job;

  @override
  Widget build(BuildContext context) {
    final isDelivered = !job.isCancelled;
    final amount = isDelivered ? job.earningsLabel : null;
    final meta = job.completedMeta;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _OrdersScreenState._surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _OrdersScreenState._cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusPill(
            label: isDelivered ? 'DELIVERED' : 'CANCELLED',
            background: isDelivered
                ? _OrdersScreenState._greenPillBg
                : _OrdersScreenState._redPillBg,
            foreground: isDelivered
                ? _OrdersScreenState._greenDark
                : _OrdersScreenState._red,
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  job.completedRoute,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _OrdersScreenState._textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
              if (amount != null) ...[
                const SizedBox(width: 8),
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _OrdersScreenState._green,
                  ),
                ),
              ],
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              meta,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: _OrdersScreenState._textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: foreground,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

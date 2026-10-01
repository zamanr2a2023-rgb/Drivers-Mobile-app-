import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/services/map_service.dart';
import 'package:yjeek_driver/core/widgets/app_google_map.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';
import 'package:yjeek_driver/navigation/bottom_nav_bar.dart';
import 'package:yjeek_driver/navigation/orders_nav_signal.dart';
import 'package:yjeek_driver/routes/route_names.dart';

extension _GoToCustomerSu on num {
  double h(BuildContext context) =>
      this * MediaQuery.sizeOf(context).height / 812;
}

/// Local UI-only "Go to customer" screen for the instant delivery flow.
class GoToCustomerScreen extends StatelessWidget {
  const GoToCustomerScreen({super.key});

  static const Color _headerGreen = Color(0xFF4DB04F);
  static const Color _screenBg = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF6B7B6E);
  static const Color _cardBorder = Color(0xFFE0E0E0);
  static const Color _iconGreenBg = Color(0xFFE8F5E9);
  static const Color _iconGreen = Color(0xFF2E7D32);
  static const Color _codBg = Color(0xFFFFF0DE);
  static const Color _codOrange = Color(0xFFE67E22);
  static const Color _reportBg = Color(0xFFFFF8F3);
  static const Color _reportBorder = Color(0xFFF5A623);
  static const Color _navigateBlack = Color(0xFF1A1A1A);

  static const String _cashIconAsset =
      'assets/images/cash_on_delivery_icon.png';

  void _handleBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteNames.mainNavigation,
          (route) => false,
        );
        return;
      case 1:
        OrdersNavSignal.openInstant();
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteNames.mainNavigation,
          (route) => false,
        );
        return;
      case 2:
        Navigator.pushNamed(context, RouteNames.earnings);
        return;
      case 3:
        Navigator.pushNamed(context, RouteNames.notifications);
        return;
      case 4:
        Navigator.pushNamed(context, RouteNames.profile);
        return;
    }
  }

  String _orderId(BuildContext context) {
    final job = context.watch<OrderProvider>().currentJobDetail;
    final number = job?.order.displayOrderNumber.trim() ?? '';
    if (number.isNotEmpty) return number;
    return job?.id.trim() ?? '';
  }

  String _customerName(BuildContext context) {
    return context
            .watch<OrderProvider>()
            .currentJobDetail
            ?.order
            .customer
            .displayName
            .trim() ??
        '';
  }

  String _customerPhone(BuildContext context) {
    return context
            .watch<OrderProvider>()
            .currentJobDetail
            ?.order
            .customer
            .displayPhone
            .trim() ??
        '';
  }

  String _customerAddress(BuildContext context) {
    return context
            .watch<OrderProvider>()
            .currentJobDetail
            ?.order
            .address
            .shortLabel
            .trim() ??
        '';
  }

  String _deliveryNote(BuildContext context) {
    return context
            .watch<OrderProvider>()
            .currentJobDetail
            ?.order
            .kitchenNote
            ?.trim() ??
        '';
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

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
                  padding: EdgeInsets.zero,
                  children: [
                    const _GoToCustomerMap(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                      child: Column(
                        children: [
                          _buildCustomerCard(context),
                          const SizedBox(height: 10),
                          _buildCashCard(context),
                          const SizedBox(height: 14),
                          _buildReportNavigateRow(context),
                          const SizedBox(height: 12),
                          _buildArrivedButton(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: 1,
            onTap: (index) => _handleBottomNavTap(context, index),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _headerGreen,
      padding: const EdgeInsets.fromLTRB(8, 10, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: Icon(
              Icons.near_me_outlined,
              color: Colors.white.withValues(alpha: 0.95),
              size: 22,
            ),
          ),
          const SizedBox(width: 2),
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
                  context
                          .watch<OrderProvider>()
                          .currentJobDetail
                          ?.distanceEtaLabel ??
                      '—',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFCFE3D5),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              'Drop-off',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFCFE3D5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context) {
    final name = _customerName(context);
    final phone = _customerPhone(context);
    final address = _customerAddress(context);
    final note = _deliveryNote(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _iconGreenBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: _iconGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? '—' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  phone.isEmpty ? '—' : phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _textMuted,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address.isEmpty ? '—' : address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _textMuted,
                    height: 1.25,
                  ),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Note:  $note',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _textMuted,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _iconGreenBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.phone_rounded,
              color: _iconGreen,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashCard(BuildContext context) {
    final job = context.watch<OrderProvider>().currentJobDetail;
    if (job == null || !job.requiresCashCollection) {
      return const SizedBox.shrink();
    }
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

  Widget _buildReportNavigateRow(BuildContext context) {
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
                    'orderId': _orderId(context),
                    'customerName': _customerName(context),
                    'address': _customerAddress(context),
                  },
                ),
                borderRadius: BorderRadius.circular(14),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      color: _codOrange,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Report',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _codOrange,
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
                onTap: () => MapService.openNavigationOrShowError(
                  context,
                  address: _customerAddress(context),
                ),
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

  Widget _buildArrivedButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: _headerGreen,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () =>
              Navigator.pushNamed(context, RouteNames.cashCompleteDelivery),
          borderRadius: BorderRadius.circular(14),
          child: const Center(
            child: Text(
              'Arrived at customer',
              style: TextStyle(
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

class _GoToCustomerMap extends StatelessWidget {
  const _GoToCustomerMap();

  @override
  Widget build(BuildContext context) {
    return AppGoogleMap(height: 390.h(context));
  }
}

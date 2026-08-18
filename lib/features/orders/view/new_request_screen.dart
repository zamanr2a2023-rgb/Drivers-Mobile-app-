import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/widgets/app_google_map.dart';
import 'package:yjeek_driver/features/dashboard/provider/dashboard_provider.dart';
import 'package:yjeek_driver/features/orders/model/job_offer_model.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';
import 'package:yjeek_driver/navigation/orders_nav_signal.dart';
import 'package:yjeek_driver/routes/route_names.dart';

class _NewRequestScreenScale {
  static const Size _designSize = Size(390, 844);
  static Size _screenSize = _designSize;

  static void update(Size size) {
    if (size.width > 0 && size.height > 0) {
      _screenSize = size;
    }
  }

  static double width(num value) =>
      value.toDouble() * (_screenSize.width / _designSize.width);

  static double height(num value) =>
      value.toDouble() * (_screenSize.height / _designSize.height);
}

extension _NewRequestScreenUnits on num {
  double get w => _NewRequestScreenScale.width(this);

  double get h => _NewRequestScreenScale.height(this);
}

class NewRequestScreen extends StatefulWidget {
  const NewRequestScreen({super.key});

  @override
  State<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _transparent = Color(0x00000000);
  static const Color _textDark = Color(0xFF1B1B1B);
  static const Color _textMuted = Color(0xFF6D776D);
  static const Color _green = Color(0xFF4CAF50);
  static const Color _greenDark = Color(0xFF126233);
  static const Color _greenBanner = Color(0xFFE5F5E8);
  static const Color _cardBorder = Color(0xFFE1E8E0);
  static const Color _routeCardBg = Color(0xFFF2F8F1);
  static const Color _cashCardBg = Color(0xFFFFEEDB);
  static const Color _orange = Color(0xFFF28A0B);
  static const Color _orangeText = Color(0xFFE67A00);
  static const Color _timerBg = Color(0xFFFFEEDB);
  static const Color _handle = Color(0xFFDDE6D9);
  static const Color _blackDot = Color(0xFF1B1B1B);
  static const Color _routeLine = Color(0xFFD4DDD2);
  static const Color _shadow = Color(0x0F000000);
  static const Color _boltFill = Color(0xFFFFC400);
  static const Color _boltStroke = Color(0xFFFF9800);

  static const String _calendarIcon = 'assets/images/calendar_jul_17.png';
  Timer? _countdownTicker;

  @override
  void initState() {
    super.initState();
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OrderProvider>().loadJobOffers();
    });
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    _NewRequestScreenScale.update(media.size);
    final orders = context.watch<OrderProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final offer = orders.currentOffer;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: _white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: _white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _white,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: _green,
            onRefresh: () => context.read<OrderProvider>().loadJobOffers(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double mapHeight = 374.h.clamp(300.0, 430.0).toDouble();

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      children: [
                        SizedBox(height: 8.h),
                        Center(
                          child: SizedBox(
                            width: 358.w,
                            height: 50.h,
                            child: _buildScheduledCard(context),
                          ),
                        ),
                        SizedBox(
                          height: mapHeight,
                          width: double.infinity,
                          child: const _RequestMapSection(),
                        ),
                        _RequestBottomSheet(
                          bottomInset: media.padding.bottom,
                          isLoading: orders.isLoadingOffers,
                          error: orders.offersError,
                          offer: offer,
                          autoAcceptEnabled: dashboard.isAutoAcceptEnabled,
                          onRetry: () =>
                              context.read<OrderProvider>().loadJobOffers(),
                          onAccept: offer == null
                              ? null
                              : () async {
                                  final provider =
                                      context.read<OrderProvider>();
                                  final result =
                                      await provider.acceptJob(offer.id);
                                  if (!context.mounted) return;

                                  if (result == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          provider.acceptJobError ??
                                              'Failed to accept job',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.pushNamed(
                                    context,
                                    RouteNames.orderDeliveryNewRequest,
                                  );
                                },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _openOrdersScheduled(BuildContext context) {
    OrdersNavSignal.openScheduled();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushNamed(
      RouteNames.orders,
      arguments: const {'segment': 'scheduled'},
    );
  }

  Widget _buildScheduledCard(BuildContext context) {
    return Material(
      color: _white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _openOrdersScheduled(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: double.infinity,
          padding: const EdgeInsets.fromLTRB(15, 0, 11, 0),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _cardBorder, width: 1),
            boxShadow: const [
              BoxShadow(
                color: _shadow,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Image.asset(
                  _calendarIcon,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.calendar_today,
                    color: _textDark,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 21),
              const Expanded(
                child: Text(
                  '2 scheduled orders today',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'View',
                style: TextStyle(
                  color: _green,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                color: _green,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaitingCard extends StatelessWidget {
  const _WaitingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 7, 15, 7),
      decoration: BoxDecoration(
        color: _NewRequestScreenState._white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: _NewRequestScreenState._shadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Center(
              child: _RequestBoltIcon(width: 11, height: 17),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waiting for requests...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _NewRequestScreenState._textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Stay near busy (orange) areas for more orders',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _NewRequestScreenState._textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestMapSection extends StatelessWidget {
  const _RequestMapSection();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        const Positioned.fill(child: AppGoogleMap()),
        Positioned(
          left: 14.w,
          right: 20.w,
          top: 13.h,
          height: 51.h,
          child: const _WaitingCard(),
        ),
      ],
    );
  }
}

class _RequestBottomSheet extends StatelessWidget {
  const _RequestBottomSheet({
    required this.bottomInset,
    required this.isLoading,
    required this.error,
    required this.offer,
    required this.autoAcceptEnabled,
    required this.onRetry,
    required this.onAccept,
  });

  final double bottomInset;
  final bool isLoading;
  final String? error;
  final JobOfferModel? offer;
  final bool autoAcceptEnabled;
  final VoidCallback onRetry;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = bottomInset + 12.h;

    return ColoredBox(
      color: _NewRequestScreenState._white,
      child: Padding(
        padding: EdgeInsets.fromLTRB(0, 8.h, 0, bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(left: 18.w),
                decoration: BoxDecoration(
                  color: _NewRequestScreenState._handle,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            SizedBox(height: 13.h),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: CircularProgressIndicator(
                    color: _NewRequestScreenState._green,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            else if (error != null && offer == null)
              Padding(
                padding: EdgeInsets.fromLTRB(18.w, 24, 18.w, 12),
                child: Column(
                  children: [
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _NewRequestScreenState._textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (offer == null)
              Padding(
                padding: EdgeInsets.fromLTRB(18.w, 28, 18.w, 20),
                child: const Text(
                  'Waiting for delivery requests…',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _NewRequestScreenState._textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else ...[
              Builder(
                builder: (context) {
                  final activeOffer = offer!;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (autoAcceptEnabled)
                        Center(
                          child: SizedBox(
                            width: 358.w,
                            height: 35.h,
                            child: _AutoAcceptBanner(
                              timerText: activeOffer.timerLabel,
                            ),
                          ),
                        ),
                      SizedBox(height: autoAcceptEnabled ? 20.h : 0),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18.w),
                        child: _RequestHeader(timerText: activeOffer.timerLabel),
                      ),
                      SizedBox(height: 16.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18.w),
                        child: _PriceAndDistance(offer: activeOffer),
                      ),
                      SizedBox(height: 14.h),
                      Center(
                        child: SizedBox(
                          width: 358.w,
                          child: _RouteInfoCard(offer: activeOffer),
                        ),
                      ),
                      if (activeOffer.isCash) ...[
                        SizedBox(height: 14.h),
                        Center(
                          child: SizedBox(
                            width: 358.w,
                            height: 52.h,
                            child: _CashCard(
                              collectLabel: activeOffer.cashCollectLabel,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 18.h),
                      Center(
                        child: SizedBox(
                          width: 358.w,
                          height: 40.h,
                          child: ElevatedButton(
                            onPressed: onAccept,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _NewRequestScreenState._green,
                              foregroundColor: _NewRequestScreenState._white,
                              disabledBackgroundColor:
                                  _NewRequestScreenState._green,
                              elevation: 0,
                              shadowColor: _NewRequestScreenState._transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'Accept now',
                              style: TextStyle(
                                color: _NewRequestScreenState._white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AutoAcceptBanner extends StatelessWidget {
  const _AutoAcceptBanner({required this.timerText});

  final String timerText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 0, 12, 0),
      decoration: BoxDecoration(
        color: _NewRequestScreenState._greenBanner,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 20,
            child: Center(
              child: _RequestBoltIcon(width: 10, height: 15),
            ),
          ),
          SizedBox(width: 7),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Auto-Accept ON - accepting automatically in $timerText',
                maxLines: 1,
                style: TextStyle(
                  color: _NewRequestScreenState._greenDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestHeader extends StatelessWidget {
  const _RequestHeader({required this.timerText});

  final String timerText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'New delivery request',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _NewRequestScreenState._textDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
        Container(
          width: 69,
          height: 27,
          decoration: BoxDecoration(
            color: _NewRequestScreenState._timerBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: _NewRequestScreenState._orange,
                size: 15,
              ),
              const SizedBox(width: 4),
              Text(
                timerText,
                style: const TextStyle(
                  color: _NewRequestScreenState._orange,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceAndDistance extends StatelessWidget {
  const _PriceAndDistance({required this.offer});

  final JobOfferModel offer;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    offer.earningsLabel,
                    maxLines: 1,
                    style: const TextStyle(
                      color: _NewRequestScreenState._greenDark,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
              if (offer.tipAmount > 0) ...[
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    'incl. tip',
                    style: TextStyle(
                      color: _NewRequestScreenState._textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              offer.distanceLabel,
              style: const TextStyle(
                color: _NewRequestScreenState._textDark,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              offer.etaCategoryLabel,
              style: const TextStyle(
                color: _NewRequestScreenState._textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RouteInfoCard extends StatelessWidget {
  const _RouteInfoCard({required this.offer});

  final JobOfferModel offer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 12, 12),
      decoration: BoxDecoration(
        color: _NewRequestScreenState._routeCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 12,
            height: 72.h,
            child: const _RouteDots(),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.vendorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _NewRequestScreenState._textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  offer.pickupSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _NewRequestScreenState._textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  offer.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _NewRequestScreenState._textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  offer.dropoffSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _NewRequestScreenState._textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteDots extends StatelessWidget {
  const _RouteDots();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: 11,
          bottom: 11,
          child: Container(
            width: 2,
            color: _NewRequestScreenState._routeLine,
          ),
        ),
        const Positioned(
          top: 0,
          child: _Dot(color: _NewRequestScreenState._green),
        ),
        const Positioned(
          bottom: 0,
          child: _Dot(color: _NewRequestScreenState._blackDot),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 11,
      height: 11,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _CashCard extends StatelessWidget {
  const _CashCard({required this.collectLabel});

  final String collectLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 0, 14, 0),
      decoration: BoxDecoration(
        color: _NewRequestScreenState._cashCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const _CashIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Collect cash on delivery',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _NewRequestScreenState._orangeText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  collectLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _NewRequestScreenState._orangeText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CashIcon extends StatelessWidget {
  const _CashIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 17,
      height: 13,
      child: CustomPaint(
        painter: _CashIconPainter(),
      ),
    );
  }
}

class _RequestBoltIcon extends StatelessWidget {
  const _RequestBoltIcon({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: const CustomPaint(painter: _BoltPainter()),
    );
  }
}

class _BoltPainter extends CustomPainter {
  const _BoltPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.68, size.height * 0.02)
      ..lineTo(size.width * 0.11, size.height * 0.56)
      ..lineTo(size.width * 0.47, size.height * 0.56)
      ..lineTo(size.width * 0.31, size.height * 0.98)
      ..lineTo(size.width * 0.91, size.height * 0.39)
      ..lineTo(size.width * 0.55, size.height * 0.39)
      ..close();
    final fill = Paint()
      ..color = _NewRequestScreenState._boltFill
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = _NewRequestScreenState._boltStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeJoin = StrokeJoin.miter
      ..strokeCap = StrokeCap.square;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CashIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _NewRequestScreenState._orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.05,
          size.height * 0.12,
          size.width * 0.90,
          size.height * 0.76,
        ),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.50),
      size.height * 0.18,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

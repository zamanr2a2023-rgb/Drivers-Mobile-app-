import 'package:flutter/material.dart';
import 'package:yjeek_driver/core/widgets/app_google_map.dart';
import 'package:yjeek_driver/features/orders/model/job_detail_model.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_order.dart';
import 'package:yjeek_driver/navigation/bottom_nav_bar.dart';
import 'package:yjeek_driver/navigation/orders_nav_signal.dart';
import 'package:yjeek_driver/routes/route_names.dart';

String scheduledLiveJobId(
  ScheduledDeliveryOrder order,
  OrderProvider provider,
) {
  final fromJob = provider.currentJobDetail?.id.trim() ?? '';
  if (fromJob.isNotEmpty && !fromJob.startsWith('#')) return fromJob;
  return order.liveJobId;
}

bool isScheduledLiveJobId(String jobId) =>
    jobId.isNotEmpty && !jobId.startsWith('#');

ScheduledDeliveryOrder scheduledOrderFromJob(
  ScheduledDeliveryOrder order,
  JobDetailModel? job,
) {
  if (job == null) return order;
  return order.mergedWithJob(job);
}

void scheduledHandleBottomNavTap(BuildContext context, int index) {
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

Widget scheduledBottomNav(BuildContext context) {
  return BottomNavBar(
    currentIndex: 1,
    onTap: (index) => scheduledHandleBottomNavTap(context, index),
  );
}

void scheduledReturnToOnTrack(BuildContext context) {
  OrdersNavSignal.openScheduledOnTrack();
  Navigator.popUntil(
    context,
    (route) => route.settings.name == RouteNames.mainNavigation,
  );
}

class ScheduledMapPlaceholder extends StatelessWidget {
  const ScheduledMapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppGoogleMap(height: 200);
  }
}

class ScheduledDashedBorderPainter extends CustomPainter {
  const ScheduledDashedBorderPainter({
    required this.color,
    required this.radius,
    this.strokeWidth = 1.5,
    this.dashWidth = 6,
    this.dashGap = 4,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant ScheduledDashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

Widget scheduledReportNavigateRow({
  VoidCallback? onReport,
  VoidCallback? onNavigate,
}) {
  const orange = Color(0xFFE67E22);
  return Row(
    children: [
      Expanded(
        child: SizedBox(
          height: 48,
          child: Material(
            color: const Color(0xFFFFF8F3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFF5A623), width: 1.2),
            ),
            child: InkWell(
              onTap: onReport,
              borderRadius: BorderRadius.circular(14),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag_outlined, color: orange, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Report',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: orange,
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
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onNavigate,
              borderRadius: BorderRadius.circular(14),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.near_me, color: Colors.white, size: 18),
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

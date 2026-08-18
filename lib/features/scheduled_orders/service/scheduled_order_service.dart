import 'package:yjeek_driver/features/orders/service/order_service.dart';
import 'package:yjeek_driver/features/scheduled_orders/model/scheduled_order_model.dart';

class ScheduledOrderService {
  ScheduledOrderService({OrderService? orderService})
      : _orders = orderService ?? OrderService();

  final OrderService _orders;

  static const _sections = [
    'new',
    'require_confirmation',
    'on_track',
  ];

  /// Loads scheduled jobs from the board (new, require confirmation, on track).
  Future<List<ScheduledOrderModel>> getScheduledOrders() async {
    final results = <ScheduledOrderModel>[];

    for (final section in _sections) {
      final board = await _orders.getJobsBoard(
        type: 'scheduled',
        section: section,
      );
      results.addAll(
        board.jobs.map(
          (job) => ScheduledOrderModel.fromBoardJob(job, section: section),
        ),
      );
    }

    return results;
  }
}

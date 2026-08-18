import 'package:flutter/foundation.dart';

/// Bumps when a bottom-nav tab is opened so that tab reloads live data.
class TabRefreshSignal {
  TabRefreshSignal._();

  static const int home = 0;
  static const int orders = 1;
  static const int earnings = 2;
  static const int performance = 3;
  static const int account = 4;

  static final List<ValueNotifier<int>> ticks = List<ValueNotifier<int>>.generate(
    5,
    (_) => ValueNotifier<int>(0),
  );

  static void refresh(int index) {
    if (index < 0 || index >= ticks.length) return;
    ticks[index].value++;
  }
}

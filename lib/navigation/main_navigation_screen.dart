import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/constants/app_colors.dart';
import 'package:yjeek_driver/features/content/view/app_open_banner_popup.dart';
import 'package:yjeek_driver/features/dashboard/view/dashboard_screen.dart';
import 'package:yjeek_driver/features/earnings/view/earnings_screen.dart';
import 'package:yjeek_driver/features/notifications/provider/notification_provider.dart';
import 'package:yjeek_driver/features/orders/view/orders_screen.dart';
import 'package:yjeek_driver/features/performance/view/performance_screen.dart';
import 'package:yjeek_driver/features/profile/view/profile_screen.dart';
import 'package:yjeek_driver/navigation/bottom_nav_bar.dart';
import 'package:yjeek_driver/navigation/orders_nav_signal.dart';
import 'package:yjeek_driver/navigation/tab_refresh_signal.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final _screens = const [
    DashboardScreen(),
    OrdersScreen(),
    EarningsScreen(),
    PerformanceScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    OrdersNavSignal.pendingSegment.addListener(_onOrdersNavSignal);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
      AppOpenBannerPopup.maybeShow(context);
    });
  }

  @override
  void dispose() {
    OrdersNavSignal.pendingSegment.removeListener(_onOrdersNavSignal);
    AppOpenBannerPopup.resetSession();
    super.dispose();
  }

  void _onOrdersNavSignal() {
    if (OrdersNavSignal.pendingSegment.value == null) return;
    if (!mounted) return;
    setState(() => _currentIndex = 1); // Orders tab active
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        sizing: StackFit.expand,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          TabRefreshSignal.refresh(index);
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/features/settings/provider/settings_provider.dart';
import 'package:yjeek_driver/l10n/l10n.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const Color _activeColor = Color(0xFF4CAF50);
  static const Color _inactiveColor = Color(0xFF6B7C6B);

  static const String _homeIcon = 'assets/images/Home-icon.png';
  static const String _ordersIcon = 'assets/images/Order_icon.png';
  static const String _earningsIcon = 'assets/images/Earnings_icon.png';
  static const String _performanceIcon = 'assets/images/Performans_icon.png';
  static const String _accountIcon = 'assets/images/Account_icon.png';

  Widget _navIcon(String assetPath, bool isSelected) {
    return Image.asset(
      assetPath,
      width: 24,
      height: 24,
      color: isSelected ? _activeColor : _inactiveColor,
      colorBlendMode: BlendMode.srcIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE8EEE8), width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: _activeColor,
        unselectedItemColor: _inactiveColor,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        items: [
          BottomNavigationBarItem(
            icon: _navIcon(_homeIcon, false),
            activeIcon: _navIcon(_homeIcon, true),
            label: L10n.tr('Home'),
          ),
          BottomNavigationBarItem(
            icon: _navIcon(_ordersIcon, false),
            activeIcon: _navIcon(_ordersIcon, true),
            label: L10n.tr('Orders'),
          ),
          BottomNavigationBarItem(
            icon: _navIcon(_earningsIcon, false),
            activeIcon: _navIcon(_earningsIcon, true),
            label: L10n.tr('Earnings'),
          ),
          BottomNavigationBarItem(
            icon: _navIcon(_performanceIcon, false),
            activeIcon: _navIcon(_performanceIcon, true),
            label: L10n.tr('Performance'),
          ),
          BottomNavigationBarItem(
            icon: _navIcon(_accountIcon, false),
            activeIcon: _navIcon(_accountIcon, true),
            label: L10n.tr('Account'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/constants/app_colors.dart';
import 'package:yjeek_driver/core/constants/app_sizes.dart';
import 'package:yjeek_driver/core/constants/app_strings.dart';
import 'package:yjeek_driver/core/widgets/custom_app_bar.dart';
import 'package:yjeek_driver/features/auth/provider/auth_provider.dart';
import 'package:yjeek_driver/features/dashboard/provider/dashboard_provider.dart';
import 'package:yjeek_driver/features/settings/provider/settings_provider.dart';
import 'package:yjeek_driver/l10n/l10n.dart';
import 'package:yjeek_driver/routes/route_names.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: CustomAppBar(title: L10n.tr('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.language, color: AppColors.primary),
              title: Text(L10n.tr('Language')),
              subtitle: Text(settings.language),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, RouteNames.language),
            ),
          ),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined,
                  color: AppColors.primary),
              title: Text(L10n.tr('Notifications')),
              subtitle: Text(L10n.tr('Push notifications')),
              value: settings.notificationsEnabled,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
              activeThumbColor: AppColors.primary,
              onChanged: settings.toggleNotifications,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined,
                  color: AppColors.primary),
              title: Text(AppStrings.privacyPolicy),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Navigator.pushNamed(context, RouteNames.privacyPolicy),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined,
                  color: AppColors.primary),
              title: Text(L10n.tr('Open-source licenses')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLicensePage(
                context: context,
                applicationName: AppStrings.appName,
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text(AppStrings.logout,
                  style: const TextStyle(color: AppColors.error)),
              onTap: () async {
                context.read<DashboardProvider>().resetOnLogout();
                await context.read<AuthProvider>().logout();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                    context, RouteNames.login, (route) => false);
              },
            ),
          ),
        ],
      ),
    );
  }
}

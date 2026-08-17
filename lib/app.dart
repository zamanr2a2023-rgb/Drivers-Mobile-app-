import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/theme/app_theme.dart';
import 'package:yjeek_driver/features/auth/provider/auth_provider.dart';
import 'package:yjeek_driver/features/chat/provider/chat_provider.dart';
import 'package:yjeek_driver/features/dashboard/provider/dashboard_provider.dart';
import 'package:yjeek_driver/features/earnings/provider/earnings_provider.dart';
import 'package:yjeek_driver/features/food_delivery/provider/food_delivery_provider.dart';
import 'package:yjeek_driver/features/incidents_safety/provider/incident_provider.dart';
import 'package:yjeek_driver/features/notifications/provider/notification_provider.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';
import 'package:yjeek_driver/features/profile/provider/profile_provider.dart';
import 'package:yjeek_driver/features/scheduled_orders/provider/scheduled_order_provider.dart';
import 'package:yjeek_driver/features/settings/provider/settings_provider.dart';
import 'package:yjeek_driver/l10n/app_locales.dart';
import 'package:yjeek_driver/l10n/l10n.dart';
import 'package:yjeek_driver/routes/app_navigator.dart';
import 'package:yjeek_driver/routes/app_routes.dart';
import 'package:yjeek_driver/routes/route_names.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => FoodDeliveryProvider()),
        ChangeNotifierProvider(create: (_) => ScheduledOrderProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => EarningsProvider()),
        ChangeNotifierProvider(create: (_) => IncidentProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..initialize(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          // Depend on revision so translated strings rebuild.
          final _ = settings.revision;
          return MaterialApp(
            title: L10n.tr('Yjeek Champ'),
            debugShowCheckedModeBanner: false,
            navigatorKey: appNavigatorKey,
            theme: AppTheme.lightTheme,
            locale: settings.locale,
            supportedLocales: AppLocales.supported,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: RouteNames.splash,
            onGenerateRoute: AppRoutes.generateRoute,
            builder: (context, child) {
              return Directionality(
                textDirection:
                    settings.isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}

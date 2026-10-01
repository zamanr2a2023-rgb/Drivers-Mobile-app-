import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/features/auth/provider/auth_provider.dart';
import 'package:yjeek_driver/routes/route_names.dart';
import 'package:yjeek_driver/services/push_notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();
    final startedAt = DateTime.now();

    await auth.restoreSession();

    // Keep splash visible briefly without delaying past the restore work.
    final elapsed = DateTime.now().difference(startedAt);
    const minSplash = Duration(milliseconds: 1200);
    if (elapsed < minSplash) {
      await Future.delayed(minSplash - elapsed);
    }

    if (!mounted) return;

    final nextRoute = auth.isAuthenticated
        ? RouteNames.mainNavigation
        : RouteNames.login;

    Navigator.pushReplacementNamed(context, nextRoute);
    PushNotificationService.instance.consumePendingOpen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4CAF50),
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/splash_screen.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}

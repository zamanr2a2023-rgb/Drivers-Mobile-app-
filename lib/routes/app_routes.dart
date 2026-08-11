import 'package:flutter/material.dart';
import 'package:yjeek_driver/core/constants/app_colors.dart';
import 'package:yjeek_driver/features/auth/model/otp_screen_args.dart';
import 'package:yjeek_driver/features/auth/view/account_not_registered_screen.dart';
import 'package:yjeek_driver/features/auth/view/login_screen.dart';
import 'package:yjeek_driver/features/auth/view/otp_screen.dart';
import 'package:yjeek_driver/l10n/l10n.dart';
import 'package:yjeek_driver/features/chat/view/dispatch_chat_screen.dart';
import 'package:yjeek_driver/features/dashboard/view/cant_go_online_screen.dart';
import 'package:yjeek_driver/features/dashboard/view/dashboard_screen.dart';
import 'package:yjeek_driver/features/dashboard/view/go_online_screen.dart';
import 'package:yjeek_driver/features/dashboard/view/update_required_screen.dart';
import 'package:yjeek_driver/features/earnings/view/earnings_screen.dart';
import 'package:yjeek_driver/features/earnings/view/payout_screen.dart';
import 'package:yjeek_driver/features/earnings/view/transaction_history_screen.dart';
import 'package:yjeek_driver/features/food_delivery/view/delivery_success_screen.dart';
import 'package:yjeek_driver/features/food_delivery/view/dropoff_details_screen.dart';
import 'package:yjeek_driver/features/food_delivery/view/food_delivery_screen.dart';
import 'package:yjeek_driver/features/food_delivery/view/pickup_details_screen.dart';
import 'package:yjeek_driver/features/incidents_safety/view/cant_find_address_screen.dart';
import 'package:yjeek_driver/features/incidents_safety/view/cant_reach_customer_screen.dart';
import 'package:yjeek_driver/features/incidents_safety/view/damage_at_pickup_screen.dart';
import 'package:yjeek_driver/features/incidents_safety/view/damage_in_transit_screen.dart';
import 'package:yjeek_driver/features/incidents_safety/view/dispatch_cant_reach_chat_screen.dart';
import 'package:yjeek_driver/features/incidents_safety/view/incident_ui.dart';
import 'package:yjeek_driver/features/incidents_safety/view/incidents_screen.dart';
import 'package:yjeek_driver/features/incidents_safety/view/report_at_dropoff_screen.dart';
import 'package:yjeek_driver/features/incidents_safety/view/report_at_pickup_screen.dart';
import 'package:yjeek_driver/features/incidents_safety/view/report_issue_screen.dart';
import 'package:yjeek_driver/features/incidents_safety/view/safety_help_screen.dart';
import 'package:yjeek_driver/features/incidents_safety/view/vehicle_breakdown_screen.dart';
import 'package:yjeek_driver/features/incidents_safety/view/vendor_not_ready_screen.dart';
import 'package:yjeek_driver/features/incidents_safety/view/verify_handover_screen.dart';
import 'package:yjeek_driver/features/incidents_safety/view/wrong_missing_items_screen.dart';
import 'package:yjeek_driver/features/notifications/view/notifications_screen.dart';
import 'package:yjeek_driver/features/orders/view/accept_order_screen.dart';
import 'package:yjeek_driver/features/orders/view/cash_complete_delivery_screen.dart';
import 'package:yjeek_driver/features/orders/view/cash_delivery_completed_screen.dart';
import 'package:yjeek_driver/features/orders/view/complete_delivery_screen.dart';
import 'package:yjeek_driver/features/orders/view/delivery_completed_screen.dart';
import 'package:yjeek_driver/features/orders/view/confirm_pickup_screen.dart';
import 'package:yjeek_driver/features/orders/view/go_to_customer_screen.dart';
import 'package:yjeek_driver/features/orders/view/go_to_restaurant_screen.dart';
import 'package:yjeek_driver/features/orders/view/go_to_vendor_scheduled_screen.dart';
import 'package:yjeek_driver/features/orders/view/luxury_delivery_completed_screen.dart';
import 'package:yjeek_driver/features/orders/view/restricted_deliver_to_customer_screen.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_complete_delivery_screen.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_deliver_to_customer_screen.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_completed_screen.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_completed_order_detail.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_completed_order_detail_screen.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_delivery_order.dart';
import 'package:yjeek_driver/features/orders/view/secure_delivery_luxury_screen.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_pickup_screen.dart';
import 'package:yjeek_driver/features/orders/view/secure_pickup_luxury_screen.dart';
import 'package:yjeek_driver/features/orders/view/age_restricted_delivery_screen.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_vape_deliver_to_customer_screen.dart';
import 'package:yjeek_driver/features/orders/view/return_the_order_screen.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_vape_delivery_completed_screen.dart';
import 'package:yjeek_driver/features/orders/view/scheduled_vape_pickup_screen.dart';
import 'package:yjeek_driver/features/orders/view/new_request_screen.dart';
import 'package:yjeek_driver/features/orders/view/reject_scheduled_order_screen.dart';
import 'package:yjeek_driver/features/orders/view/order_delivery_new_request_screen.dart';
import 'package:yjeek_driver/features/orders/view/order_completed_screen.dart';
import 'package:yjeek_driver/features/orders/view/order_details_screen.dart';
import 'package:yjeek_driver/features/orders/view/orders_screen.dart';
import 'package:yjeek_driver/features/performance/view/performance_screen.dart';
import 'package:yjeek_driver/features/profile/view/change_number_screen.dart';
import 'package:yjeek_driver/features/profile/view/documents_screen.dart';
import 'package:yjeek_driver/features/profile/view/edit_profile_screen.dart';
import 'package:yjeek_driver/features/profile/view/profile_screen.dart';
import 'package:yjeek_driver/features/profile/view/upload_cpr_screen.dart';
import 'package:yjeek_driver/features/profile/view/upload_driving_license_screen.dart';
import 'package:yjeek_driver/features/profile/view/upload_passport_screen.dart';
import 'package:yjeek_driver/features/profile/view/upload_profile_photo_screen.dart';
import 'package:yjeek_driver/features/profile/view/upload_vehicle_registration_screen.dart';
import 'package:yjeek_driver/features/profile/view/upload_visa_screen.dart';
import 'package:yjeek_driver/features/profile/view/verify_change_number_screen.dart';
import 'package:yjeek_driver/features/profile/view/vehicle_info_screen.dart';
import 'package:yjeek_driver/features/scheduled_orders/view/age_verification_screen.dart';
import 'package:yjeek_driver/features/scheduled_orders/view/restricted_order_screen.dart';
import 'package:yjeek_driver/features/scheduled_orders/view/scheduled_order_details_screen.dart';
import 'package:yjeek_driver/features/scheduled_orders/view/scheduled_orders_screen.dart';
import 'package:yjeek_driver/features/settings/view/language_screen.dart';
import 'package:yjeek_driver/features/settings/view/privacy_policy_screen.dart';
import 'package:yjeek_driver/features/settings/view/settings_screen.dart';
import 'package:yjeek_driver/features/splash/view/splash_screen.dart';
import 'package:yjeek_driver/navigation/main_navigation_screen.dart';
import 'package:yjeek_driver/routes/route_names.dart';

class AppRoutes {
  AppRoutes._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return _page(const SplashScreen());
      case RouteNames.login:
        return _page(const LoginScreen());
      case RouteNames.otp:
        final args = settings.arguments;
        if (args is OtpScreenArgs) {
          return _page(
            OtpScreen(
              phone: args.phone,
              countryCode: args.countryCode,
              expiresInSeconds: args.expiresInSeconds,
              phoneDisplay: args.phoneDisplay,
              debugDevCode: args.debugDevCode,
            ),
          );
        }
        return _page(OtpScreen(phoneDisplay: args as String?));
      case RouteNames.accountNotRegistered:
        final phoneDisplay = settings.arguments is String
            ? (settings.arguments as String).trim()
            : null;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AccountNotRegisteredScreen(
            phoneDisplay: (phoneDisplay != null && phoneDisplay.isNotEmpty)
                ? phoneDisplay
                : null,
          ),
        );
      case RouteNames.mainNavigation:
        return _page(const MainNavigationScreen());
      case RouteNames.dashboard:
        return _page(const DashboardScreen());
      case RouteNames.goOnline:
        return _page(const GoOnlineScreen());
      case RouteNames.cantGoOnline:
        return _page(const CantGoOnlineScreen());
      case RouteNames.updateRequired:
        return _page(const UpdateRequiredScreen());
      case RouteNames.orders:
        final ordersArgs = settings.arguments;
        final initialSegment = ordersArgs is int
            ? ordersArgs
            : (ordersArgs is Map && ordersArgs['segment'] == 'scheduled')
                ? 1
                : 0;
        return _page(OrdersScreen(initialSegment: initialSegment));
      case RouteNames.orderDetails:
        final args = settings.arguments as String?;
        return _page(OrderDetailsScreen(orderId: args));
      case RouteNames.newRequest:
        return _page(const NewRequestScreen());
      case RouteNames.orderDeliveryNewRequest:
        return _page(const OrderDeliveryNewRequestScreen());
      case RouteNames.goToRestaurant:
        final goArgs = settings.arguments;
        final restaurantArgs = goArgs is GoToRestaurantArgs
            ? goArgs
            : GoToRestaurantArgs(
                orderId: goArgs is Map
                    ? '${goArgs['orderId'] ?? '#YJK-...41'}'
                    : '#YJK-...41',
                restaurantName: goArgs is Map
                    ? '${goArgs['restaurantName'] ?? 'The Green Kitchen'}'
                    : 'The Green Kitchen',
                pickupLocation: goArgs is Map
                    ? '${goArgs['pickupLocation'] ?? 'Seef District'}'
                    : 'Seef District',
                distance: goArgs is Map
                    ? '${goArgs['distance'] ?? '1.1 km'}'
                    : '1.1 km',
                estimatedTime: goArgs is Map
                    ? '${goArgs['estimatedTime'] ?? '~5 min'}'
                    : '~5 min',
              );
        return MaterialPageRoute(
          builder: (context) => GoToRestaurantScreen(
            args: restaurantArgs,
            onBack: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
        );
      case RouteNames.confirmPickup:
        final confirmArgs = settings.arguments;
        final pickupArgs = confirmArgs is ConfirmPickupArgs
            ? confirmArgs
            : ConfirmPickupArgs(
                orderId: confirmArgs is Map
                    ? '${confirmArgs['orderId'] ?? '#YJK-...41'}'
                    : '#YJK-...41',
                restaurantName: confirmArgs is Map
                    ? '${confirmArgs['restaurantName'] ?? 'The Green Kitchen'}'
                    : 'The Green Kitchen',
              );
        return MaterialPageRoute(
          builder: (context) => ConfirmPickupScreen(
            args: pickupArgs,
            onBack: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
        );
      case RouteNames.rejectOrder:
        final rejectOrderId = settings.arguments as String? ?? '#YJK-...41';
        return MaterialPageRoute(
          builder: (context) => RejectScheduledOrderScreen(
            orderId: rejectOrderId,
            onBack: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            onKeepOrder: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            onSubmitDecline: (_, __) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
        );
      case RouteNames.deliverToCustomer:
        return _page(const GoToCustomerScreen());
      case RouteNames.cashCompleteDelivery:
        return _page(const CashCompleteDeliveryScreen());
      case RouteNames.cashDeliveryCompleted:
        return _page(const CashDeliveryCompletedScreen());
      case RouteNames.completeDelivery:
        return MaterialPageRoute(
          builder: (context) => CompleteDeliveryScreen(
            onBack: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
        );
      case RouteNames.deliveryCompleted:
        return _page(const DeliveryCompletedScreen());
      case RouteNames.acceptOrder:
        return _page(const AcceptOrderScreen());
      case RouteNames.orderCompleted:
        final args = settings.arguments as double?;
        return _page(OrderCompletedScreen(earning: args ?? 0));
      case RouteNames.foodDelivery:
        return _page(const FoodDeliveryScreen());
      case RouteNames.pickupDetails:
        return _page(const PickupDetailsScreen());
      case RouteNames.dropoffDetails:
        return _page(const DropoffDetailsScreen());
      case RouteNames.deliverySuccess:
        return _page(const DeliverySuccessScreen());
      case RouteNames.scheduledOrders:
        return _page(const ScheduledOrdersScreen());
      case RouteNames.scheduledOrderDetails:
        return _page(const ScheduledOrderDetailsScreen());
      case RouteNames.goToVendorScheduled:
        return _scheduledOrderPage(
          settings,
          (order) => GoToVendorScheduledScreen(order: order),
        );
      case RouteNames.scheduledPickup:
        return _scheduledOrderPage(
          settings,
          (order) => ScheduledPickupScreen(order: order),
        );
      case RouteNames.securePickupLuxury:
        return _scheduledOrderPage(
          settings,
          (order) => SecurePickupLuxuryScreen(order: order),
        );
      case RouteNames.scheduledVapePickup:
        return _scheduledOrderPage(
          settings,
          (order) => ScheduledVapePickupScreen(order: order),
        );
      case RouteNames.scheduledVapeDeliverToCustomer:
        return _scheduledOrderPage(
          settings,
          (order) => ScheduledVapeDeliverToCustomerScreen(order: order),
        );
      case RouteNames.restrictedDeliverToCustomer:
        return _scheduledOrderPage(
          settings,
          (order) => RestrictedDeliverToCustomerScreen(order: order),
        );
      case RouteNames.secureDeliveryLuxury:
        return _scheduledOrderPage(
          settings,
          (order) => SecureDeliveryLuxuryScreen(order: order),
        );
      case RouteNames.scheduledVapeDeliveryCompleted:
        return _scheduledOrderPage(
          settings,
          (order) => ScheduledVapeDeliveryCompletedScreen(order: order),
        );
      case RouteNames.returnTheOrder:
        return _scheduledOrderPage(
          settings,
          (order) => ReturnTheOrderScreen(order: order),
        );
      case RouteNames.scheduledDeliverToCustomer:
        return _scheduledOrderPage(
          settings,
          (order) => ScheduledDeliverToCustomerScreen(order: order),
        );
      case RouteNames.scheduledCompleteDelivery:
        return _scheduledOrderPage(
          settings,
          (order) => ScheduledCompleteDeliveryScreen(order: order),
        );
      case RouteNames.scheduledDeliveryCompleted:
        return _scheduledOrderPage(
          settings,
          (order) => ScheduledDeliveryCompletedScreen(order: order),
        );
      case RouteNames.luxuryDeliveryCompleted:
        return _scheduledOrderPage(
          settings,
          (order) => LuxuryDeliveryCompletedScreen(order: order),
        );
      case RouteNames.scheduledCompletedOrderDetail:
        return _scheduledCompletedOrderDetailPage(settings);
      case RouteNames.restrictedOrder:
        return _page(const RestrictedOrderScreen());
      case RouteNames.ageVerification:
        return _page(const AgeVerificationScreen());
      case RouteNames.ageRestrictedDelivery:
        return _scheduledOrderPage(
          settings,
          (order) => AgeRestrictedDeliveryScreen(order: order),
        );
      case RouteNames.notifications:
        return _page(const NotificationsScreen());
      case RouteNames.earnings:
        return _page(const EarningsScreen());
      case RouteNames.payout:
        return _page(const PayoutScreen());
      case RouteNames.transactionHistory:
        return _page(const TransactionHistoryScreen());
      case RouteNames.incidents:
        return _page(const IncidentsScreen());
      case RouteNames.reportIssue:
        return _page(const ReportIssueScreen());
      case RouteNames.reportAtPickup:
        return _page(ReportAtPickupScreen(args: _incidentArgs(settings)));
      case RouteNames.reportAtDropoff:
        return _page(ReportAtDropoffScreen(args: _incidentArgs(settings)));
      case RouteNames.vendorNotReady:
        return _page(VendorNotReadyScreen(args: _incidentArgs(settings)));
      case RouteNames.damageAtPickup:
        return _page(DamageAtPickupScreen(args: _incidentArgs(settings)));
      case RouteNames.cantReachCustomer:
        return _page(CantReachCustomerScreen(args: _incidentArgs(settings)));
      case RouteNames.cantFindAddress:
        return _page(CantFindAddressScreen(args: _incidentArgs(settings)));
      case RouteNames.vehicleBreakdown:
        return _page(VehicleBreakdownScreen(args: _incidentArgs(settings)));
      case RouteNames.damageInTransit:
        return _page(DamageInTransitScreen(args: _incidentArgs(settings)));
      case RouteNames.wrongMissingItems:
        return _page(WrongMissingItemsScreen(args: _incidentArgs(settings)));
      case RouteNames.verifyHandover:
        return _page(VerifyHandoverScreen(args: _incidentArgs(settings)));
      case RouteNames.safetyHelp:
        return _page(SafetyHelpScreen(jobId: _safetyHelpJobId(settings)));
      case RouteNames.dispatchChat:
        return _page(const DispatchChatScreen());
      case RouteNames.dispatchCantReachChat:
        return _page(
          DispatchCantReachChatScreen(args: _incidentArgs(settings)),
        );
      case RouteNames.profile:
        return _page(const ProfileScreen());
      case RouteNames.performance:
        return _page(const PerformanceScreen());
      case RouteNames.documents:
        return _page(const DocumentsScreen());
      case RouteNames.uploadCpr:
        return _page(const UploadCprScreen());
      case RouteNames.uploadDrivingLicense:
        return _page(const UploadDrivingLicenseScreen());
      case RouteNames.uploadVehicleRegistration:
        return _page(const UploadVehicleRegistrationScreen());
      case RouteNames.uploadProfilePhoto:
        return _page(const UploadProfilePhotoScreen());
      case RouteNames.uploadPassport:
        return _page(const UploadPassportScreen());
      case RouteNames.uploadVisa:
        return _page(const UploadVisaScreen());
      case RouteNames.changeNumber:
        return _page(const ChangeNumberScreen());
      case RouteNames.verifyChangeNumber:
        final args = settings.arguments;
        final VerifyChangeNumberArgs verifyArgs;
        if (args is VerifyChangeNumberArgs) {
          verifyArgs = args;
        } else if (args is String) {
          final digits = args.replaceAll(RegExp(r'\D'), '');
          final phone = digits.startsWith('973') && digits.length > 8
              ? digits.substring(3)
              : digits;
          verifyArgs = VerifyChangeNumberArgs(
            phone: phone,
            countryCode: '+973',
            phoneDisplay: args,
          );
        } else {
          verifyArgs = const VerifyChangeNumberArgs(
            phone: '',
            countryCode: '+973',
            phoneDisplay: '+973 3300 0000',
          );
        }
        return _page(VerifyChangeNumberScreen(args: verifyArgs));
      case RouteNames.editProfile:
        return _page(const EditProfileScreen());
      case RouteNames.vehicleInfo:
        return _page(const VehicleInfoScreen());
      case RouteNames.settings:
        return _page(const SettingsScreen());
      case RouteNames.language:
        return _page(const LanguageScreen());
      case RouteNames.privacyPolicy:
        return _page(const PrivacyPolicyScreen());
      default:
        return _page(const UnknownRouteScreen());
    }
  }

  static IncidentContextArgs _incidentArgs(RouteSettings settings) {
    final args = settings.arguments;
    if (args is IncidentContextArgs) return args;
    if (args is Map) {
      return IncidentContextArgs(
        orderId: '${args['orderId'] ?? '#YJK-…41'}',
        vendorName:
            '${args['vendorName'] ?? args['restaurantName'] ?? 'The Green Kitchen'}',
        customerName: '${args['customerName'] ?? 'Sara A.'}',
        area: '${args['area'] ?? 'Adliya'}',
        address: '${args['address'] ?? 'Adliya · Bldg 23, Road 2825, Flat 82'}',
        pin: '${args['pin'] ?? 'Pin: 26.22051, 50.58472'}',
      );
    }
    return const IncidentContextArgs();
  }

  static String? _safetyHelpJobId(RouteSettings settings) {
    final args = settings.arguments;
    if (args is String && args.trim().isNotEmpty) return args.trim();
    if (args is Map) {
      final jobId = args['jobId']?.toString().trim();
      if (jobId != null && jobId.isNotEmpty) return jobId;
    }
    return null;
  }

  static MaterialPageRoute<dynamic> _page(
    Widget child, {
    RouteSettings? settings,
  }) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => child,
    );
  }

  static MaterialPageRoute<dynamic> _scheduledOrderPage(
    RouteSettings settings,
    Widget Function(ScheduledDeliveryOrder order) builder,
  ) {
    final order = settings.arguments;
    if (order is! ScheduledDeliveryOrder) {
      return _page(const UnknownRouteScreen());
    }
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => builder(order),
    );
  }

  static MaterialPageRoute<dynamic> _scheduledCompletedOrderDetailPage(
    RouteSettings settings,
  ) {
    final order = settings.arguments;
    if (order is! ScheduledCompletedOrderDetail) {
      return _page(const UnknownRouteScreen());
    }
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => ScheduledCompletedOrderDetailScreen(order: order),
    );
  }
}

class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(L10n.tr('Page Not Found'))),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: AppColors.textLight.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(L10n.tr('The page you are looking for does not exist.')),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                RouteNames.mainNavigation,
                (route) => false,
              ),
              child: Text(L10n.tr('Go to Home')),
            ),
          ],
        ),
      ),
    );
  }
}

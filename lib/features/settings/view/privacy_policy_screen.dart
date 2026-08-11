import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/constants/app_colors.dart';
import 'package:yjeek_driver/core/constants/app_sizes.dart';
import 'package:yjeek_driver/core/widgets/custom_app_bar.dart';
import 'package:yjeek_driver/features/settings/provider/settings_provider.dart';
import 'package:yjeek_driver/l10n/l10n.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _policyText = '''
Yjeek Driver App — Privacy Policy

Last updated: January 2026

1. Information We Collect
We collect information you provide directly, including your name, phone number, email, vehicle details, and location data while you are online and delivering orders.

2. How We Use Your Information
We use your information to facilitate deliveries, process payments, improve our services, and communicate with you about your account and orders.

3. Location Data
When you are online, we collect your location to match you with nearby delivery requests and provide real-time tracking to customers.

4. Data Sharing
We do not sell your personal information. We may share data with vendors, customers (limited to delivery needs), and service providers who assist our operations.

5. Data Security
We implement industry-standard security measures to protect your personal information.

6. Your Rights
You may request access, correction, or deletion of your personal data by contacting support@yjeek.com.

7. Contact Us
For privacy-related questions, email us at privacy@yjeek.com.
''';

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();
    return Scaffold(
      appBar: CustomAppBar(title: L10n.tr('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        child: Text(
          L10n.tr(_policyText.trim()),
          style: const TextStyle(
            color: AppColors.textDark,
            height: 1.6,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/constants/app_colors.dart';
import 'package:yjeek_driver/core/constants/app_sizes.dart';
import 'package:yjeek_driver/core/constants/app_strings.dart';
import 'package:yjeek_driver/core/utils/app_helpers.dart';
import 'package:yjeek_driver/core/utils/validators.dart';
import 'package:yjeek_driver/core/widgets/custom_app_bar.dart';
import 'package:yjeek_driver/core/widgets/custom_button.dart';
import 'package:yjeek_driver/core/widgets/custom_text_field.dart';
import 'package:yjeek_driver/features/earnings/provider/earnings_provider.dart';
import 'package:yjeek_driver/features/settings/provider/settings_provider.dart';
import 'package:yjeek_driver/l10n/l10n.dart';

class PayoutScreen extends StatefulWidget {
  const PayoutScreen({super.key});

  @override
  State<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends State<PayoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _requestPayout() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text.trim());
    final provider = context.read<EarningsProvider>();
    if (amount > provider.totalBalance) {
      AppHelpers.showSnackBar(
        context,
        L10n.tr('Amount exceeds available balance'),
        isError: true,
      );
      return;
    }
    final success = await provider.requestPayout(amount);
    if (!mounted) return;
    if (success) {
      AppHelpers.showSnackBar(context, L10n.tr('Payout requested successfully!'));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();
    final provider = context.watch<EarningsProvider>();

    return Scaffold(
      appBar: CustomAppBar(title: L10n.tr('Request Payout')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.account_balance,
                      color: AppColors.primary,
                    ),
                    title: Text(L10n.tr('Bank Account')),
                    subtitle: Text(
                      L10n.tr('**** **** **** 4521 (Placeholder)'),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMd),
                Text(
                  '${L10n.tr('Available:')} ${AppHelpers.formatCurrency(provider.totalBalance)}',
                  style: const TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: AppSizes.paddingSm),
                CustomTextField(
                  controller: _amountController,
                  labelText: L10n.tr('Amount'),
                  hintText: '0.00',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: const Icon(Icons.attach_money),
                  validator: Validators.amount,
                ),
                const Spacer(),
                CustomButton(
                  title: AppStrings.requestPayout,
                  isLoading: provider.isLoading,
                  onPressed: _requestPayout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

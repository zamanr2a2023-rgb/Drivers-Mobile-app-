import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/constants/app_colors.dart';
import 'package:yjeek_driver/core/constants/app_sizes.dart';
import 'package:yjeek_driver/core/utils/app_helpers.dart';
import 'package:yjeek_driver/core/utils/date_formatter.dart';
import 'package:yjeek_driver/core/widgets/app_loader.dart';
import 'package:yjeek_driver/core/widgets/custom_app_bar.dart';
import 'package:yjeek_driver/core/widgets/status_badge.dart';
import 'package:yjeek_driver/features/earnings/provider/earnings_provider.dart';
import 'package:yjeek_driver/features/settings/provider/settings_provider.dart';
import 'package:yjeek_driver/l10n/l10n.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EarningsProvider>().loadEarnings();
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();
    final provider = context.watch<EarningsProvider>();

    return Scaffold(
      appBar: CustomAppBar(title: L10n.tr('Transaction History')),
      body: provider.isLoading
          ? const AppLoader()
          : ListView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
              itemCount: provider.transactions.length,
              itemBuilder: (context, index) {
                final txn = provider.transactions[index];
                final isPayout = txn.type == 'Payout';
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSizes.paddingSm),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (isPayout ? AppColors.error : AppColors.success).withValues(alpha: 0.12),
                      child: Icon(
                        isPayout ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isPayout ? AppColors.error : AppColors.success,
                        size: 20,
                      ),
                    ),
                    title: Text(txn.type, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${txn.id} · ${DateFormatter.formatDateTime(txn.date)}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isPayout ? '-' : '+'}${AppHelpers.formatCurrency(txn.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPayout ? AppColors.error : AppColors.success,
                          ),
                        ),
                        StatusBadge(status: txn.status),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

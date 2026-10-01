import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/constants/app_sizes.dart';
import 'package:yjeek_driver/core/constants/app_strings.dart';
import 'package:yjeek_driver/core/utils/app_helpers.dart';
import 'package:yjeek_driver/core/utils/validators.dart';
import 'package:yjeek_driver/core/widgets/custom_app_bar.dart';
import 'package:yjeek_driver/core/widgets/custom_button.dart';
import 'package:yjeek_driver/core/widgets/custom_text_field.dart';
import 'package:yjeek_driver/features/incidents_safety/provider/incident_provider.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _issueType = 'Delivery delay';

  static const _issueTypes = [
    'Delivery delay',
    'Customer issue',
    'Vehicle problem',
    'App issue',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await context.read<IncidentProvider>().submitReport(
          _issueType,
          _descriptionController.text.trim(),
        );
    if (!mounted) return;
    if (success) {
      AppHelpers.showSnackBar(context, 'Report submitted successfully');
      Navigator.pop(context);
    } else {
      AppHelpers.showSnackBar(
        context,
        'Failed to submit report',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();

    return Scaffold(
      appBar: const CustomAppBar(title: 'Report Issue'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Issue Type', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSizes.paddingSm),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _issueType,
                        items: _issueTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) => setState(() => _issueType = val!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMd),
                CustomTextField(
                  controller: _descriptionController,
                  labelText: 'Description',
                  hintText: 'Describe the issue...',
                  validator: (v) => Validators.required(v, fieldName: 'Description'),
                ),
                const Spacer(),
                CustomButton(
                  title: AppStrings.submit,
                  isLoading: provider.isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

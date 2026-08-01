import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/constants/app_colors.dart';
import 'package:yjeek_driver/core/constants/app_sizes.dart';
import 'package:yjeek_driver/core/models/map_location.dart';
import 'package:yjeek_driver/core/utils/app_helpers.dart';
import 'package:yjeek_driver/core/widgets/custom_app_bar.dart';
import 'package:yjeek_driver/core/widgets/custom_button.dart';
import 'package:yjeek_driver/features/incidents_safety/model/incident_model.dart';
import 'package:yjeek_driver/features/incidents_safety/provider/incident_provider.dart';
import 'package:yjeek_driver/features/orders/provider/order_provider.dart';
import 'package:yjeek_driver/routes/route_names.dart';
import 'package:yjeek_driver/services/location_service.dart';

class SafetyHelpScreen extends StatefulWidget {
  const SafetyHelpScreen({super.key, this.jobId});

  /// Optional job id from route args. Falls back to the active job.
  final String? jobId;

  @override
  State<SafetyHelpScreen> createState() => _SafetyHelpScreenState();
}

class _SafetyHelpScreenState extends State<SafetyHelpScreen> {
  final LocationService _locationService = LocationService();
  final TextEditingController _noteController = TextEditingController(
    text: 'Emergency — no active job context',
  );

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String? _resolveJobId(BuildContext context) {
    final fromArgs = widget.jobId?.trim();
    if (fromArgs != null && fromArgs.isNotEmpty) return fromArgs;

    final orders = context.read<OrderProvider>();
    final detailId = orders.currentJobDetail?.id.trim();
    if (detailId != null && detailId.isNotEmpty) return detailId;

    if (orders.instantActiveJobs.isNotEmpty) {
      final activeId = orders.instantActiveJobs.first.id.trim();
      if (activeId.isNotEmpty) return activeId;
    }

    return null;
  }

  Future<void> _sendSos() async {
    final incidentProvider = context.read<IncidentProvider>();
    final jobId = _resolveJobId(context);
    final note = _noteController.text.trim();

    final JobSosResult? result;
    if (jobId != null) {
      final location = await _locationService.getCurrentMapLocation();
      if (!mounted) return;

      final lat = location?.latitude ?? kBahrainFallbackLatLng.latitude;
      final lng = location?.longitude ?? kBahrainFallbackLatLng.longitude;

      result = await incidentProvider.sendJobSos(
        jobId: jobId,
        note: note.isEmpty ? 'Feeling unsafe at drop-off' : note,
        latitude: lat,
        longitude: lng,
      );
    } else {
      result = await incidentProvider.sendDriverSos(
        note: note.isEmpty ? 'Emergency — no active job context' : note,
      );
    }

    if (!mounted) return;

    if (result != null) {
      AppHelpers.showSnackBar(context, result.message);
    } else {
      AppHelpers.showSnackBar(
        context,
        incidentProvider.sosError ?? 'Failed to send SOS',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();

    return Scaffold(
      appBar: const CustomAppBar(title: 'Safety Help'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLg),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingLg),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.emergency_outlined, size: 48, color: AppColors.error),
                    SizedBox(height: AppSizes.paddingMd),
                    Text(
                      'Emergency Support',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: AppSizes.paddingSm),
                    Text(
                      'If you are in immediate danger, call emergency services first.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.paddingMd),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'SOS note',
                  hintText: 'Describe what is happening…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingLg),
              CustomButton(
                title: 'Call Support',
                backgroundColor: AppColors.error,
                isLoading: provider.isSendingSos,
                onPressed: _sendSos,
              ),
              const SizedBox(height: AppSizes.paddingSm),
              CustomButton(
                title: 'Report Safety Issue',
                onPressed: () => Navigator.pushNamed(context, RouteNames.reportIssue),
              ),
              const SizedBox(height: AppSizes.paddingSm),
              CustomButton(
                title: 'Open Dispatch Chat',
                outlined: true,
                onPressed: () => Navigator.pushNamed(context, RouteNames.dispatchChat),
              ),
              const SizedBox(height: AppSizes.paddingLg),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, RouteNames.incidents),
                child: const Text('View all incident options'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

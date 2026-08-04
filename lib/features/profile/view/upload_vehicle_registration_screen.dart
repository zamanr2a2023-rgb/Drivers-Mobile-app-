import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yjeek_driver/core/constants/app_assets.dart';
import 'package:yjeek_driver/features/profile/service/profile_service.dart';
import 'package:yjeek_driver/features/profile/view/doc_upload_ui.dart';
import 'package:yjeek_driver/services/api_service.dart';

/// DU3 · Upload — Vehicle registration
class UploadVehicleRegistrationScreen extends StatefulWidget {
  const UploadVehicleRegistrationScreen({super.key});

  @override
  State<UploadVehicleRegistrationScreen> createState() =>
      _UploadVehicleRegistrationScreenState();
}

class _UploadVehicleRegistrationScreenState
    extends State<UploadVehicleRegistrationScreen> {
  final ProfileService _profileService = ProfileService();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _frontUploaded = false;
  bool _backUploaded = false;
  bool _frontViewUploaded = false;
  bool _sideViewUploaded = false;
  bool _plateBackUploaded = false;
  bool _insuranceUploaded = false;
  int _vehicleType = 0; // 0 Car, 1 Motorcycle
  int? _year;

  String? _frontPhotoUrl;
  String? _backPhotoUrl;
  String? _sidePhotoUrl;
  Uint8List? _frontViewBytes;
  Uint8List? _sideViewBytes;
  Uint8List? _plateBackBytes;

  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _plateController = TextEditingController();
  final _insuranceExpiryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVehicle();
    });
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _plateController.dispose();
    _insuranceExpiryController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final vehicle = await _profileService.getVehicle();
      if (!mounted) return;

      setState(() {
        _vehicleType = vehicle.vehicleTypeIndex;
        _year = vehicle.year;
        _makeController.text = vehicle.make ?? '';
        _modelController.text = vehicle.model ?? '';
        _colorController.text = vehicle.color ?? '';
        _plateController.text = vehicle.plateNumber ?? '';
        _insuranceExpiryController.text = vehicle.insuranceExpiryDisplay;
        _frontPhotoUrl = vehicle.frontPhotoUrl;
        _sidePhotoUrl = vehicle.sidePhotoUrl;
        _backPhotoUrl = vehicle.backPhotoUrl;
        _frontViewUploaded = vehicle.hasFrontPhoto;
        _sideViewUploaded = vehicle.hasSidePhoto;
        _plateBackUploaded = vehicle.hasBackPhoto;
        _frontViewBytes = null;
        _sideViewBytes = null;
        _plateBackBytes = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      showDocSnack(context, e.message);
    } catch (_) {
      if (!mounted) return;
      showDocSnack(context, 'Failed to load vehicle');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickPhoto({
    required void Function(Uint8List bytes) onPicked,
  }) async {
    final bytes = await pickDocPhoto(context);
    if (bytes != null) setState(() => onPicked(bytes));
  }

  Future<void> _pick(void Function() markUploaded) async {
    final bytes = await pickDocPhoto(context);
    if (bytes != null) setState(markUploaded);
  }

  String get _apiVehicleType => _vehicleType == 1 ? 'BIKE' : 'CAR';

  /// Converts "DD / MM / YYYY" (or similar) to API format "YYYY-MM-DD".
  String? _insuranceExpiryForApi() {
    final raw = _insuranceExpiryController.text.trim();
    if (raw.isEmpty) return null;

    final iso = DateTime.tryParse(raw);
    if (iso != null) {
      return '${iso.year.toString().padLeft(4, '0')}-'
          '${iso.month.toString().padLeft(2, '0')}-'
          '${iso.day.toString().padLeft(2, '0')}';
    }

    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 8) {
      final d = digits.substring(0, 2);
      final m = digits.substring(2, 4);
      final y = digits.substring(4, 8);
      return '$y-$m-$d';
    }
    return raw;
  }

  Future<String?> _resolvePhotoUrl({
    required Uint8List? bytes,
    required String? existingUrl,
    required String filename,
  }) async {
    if (bytes == null || bytes.isEmpty) {
      final url = existingUrl?.trim();
      return (url != null && url.isNotEmpty) ? url : null;
    }

    return _profileService.uploadFile(
      bytes: bytes,
      category: 'vehicle-photos',
      filename: filename,
    );
  }

  Future<void> _save() async {
    final plate = _plateController.text.trim();
    if (plate.isEmpty) {
      showDocSnack(context, 'Please enter the vehicle / plate number');
      return;
    }
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final frontUrl = await _resolvePhotoUrl(
        bytes: _frontViewBytes,
        existingUrl: _frontPhotoUrl,
        filename: 'vehicle-front.jpg',
      );
      final sideUrl = await _resolvePhotoUrl(
        bytes: _sideViewBytes,
        existingUrl: _sidePhotoUrl,
        filename: 'vehicle-side.jpg',
      );
      final backUrl = await _resolvePhotoUrl(
        bytes: _plateBackBytes,
        existingUrl: _backPhotoUrl,
        filename: 'vehicle-back.jpg',
      );

      final vehicle = await _profileService.upsertVehicle(
        vehicleType: _apiVehicleType,
        plateNumber: plate,
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        color: _colorController.text.trim(),
        year: _year,
        frontPhotoUrl: frontUrl,
        sidePhotoUrl: sideUrl,
        backPhotoUrl: backUrl,
        insuranceExpiryDate: _insuranceExpiryForApi(),
      );
      if (!mounted) return;

      setState(() {
        _vehicleType = vehicle.vehicleTypeIndex;
        _year = vehicle.year;
        _makeController.text = vehicle.make ?? '';
        _modelController.text = vehicle.model ?? '';
        _colorController.text = vehicle.color ?? '';
        _plateController.text = vehicle.plateNumber ?? '';
        _insuranceExpiryController.text = vehicle.insuranceExpiryDisplay;
        _frontPhotoUrl = vehicle.frontPhotoUrl;
        _sidePhotoUrl = vehicle.sidePhotoUrl;
        _backPhotoUrl = vehicle.backPhotoUrl;
        _frontViewUploaded = vehicle.hasFrontPhoto;
        _sideViewUploaded = vehicle.hasSidePhoto;
        _plateBackUploaded = vehicle.hasBackPhoto;
        _frontViewBytes = null;
        _sideViewBytes = null;
        _plateBackBytes = null;
      });

      showDocSnack(context, 'Vehicle registration saved');
      Navigator.maybePop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      showDocSnack(context, e.message);
    } catch (_) {
      if (!mounted) return;
      showDocSnack(context, 'Failed to save vehicle');
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DocColors.screenBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DocHeader(title: 'Vehicle registration'),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: DocColors.green,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Card, details, photos and insurance.',
                            style: TextStyle(
                              fontSize: 13,
                              color: DocColors.textMuted,
                              height: 16 / 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const DocSectionHeader(text: 'Registration card'),
                          const SizedBox(height: 12),
                          DocUploadBox(
                            title: 'Front side',
                            uploaded: _frontUploaded,
                            onTap: _isSaving
                                ? () {}
                                : () => _pick(() => _frontUploaded = true),
                          ),
                          const SizedBox(height: 12),
                          DocUploadBox(
                            title: 'Back side',
                            uploaded: _backUploaded,
                            onTap: _isSaving
                                ? () {}
                                : () => _pick(() => _backUploaded = true),
                          ),
                          const SizedBox(height: 12),
                          const DocSectionHeader(text: 'Vehicle details'),
                          const SizedBox(height: 12),
                          _buildVehicleTypeSelector(),
                          const SizedBox(height: 12),
                          DocTextField(
                            label: 'Make',
                            hint: 'Toyota',
                            controller: _makeController,
                          ),
                          const SizedBox(height: 12),
                          DocTextField(
                            label: 'Model',
                            hint: 'Hilux',
                            controller: _modelController,
                          ),
                          const SizedBox(height: 12),
                          DocTextField(
                            label: 'Color',
                            hint: 'White',
                            controller: _colorController,
                          ),
                          const SizedBox(height: 12),
                          DocTextField(
                            label: 'Vehicle / plate number',
                            hint: '1234',
                            controller: _plateController,
                          ),
                          const SizedBox(height: 12),
                          const DocSectionHeader(text: 'Vehicle photos'),
                          const SizedBox(height: 12),
                          DocUploadBox(
                            title: 'Front view',
                            helper: 'Show the whole vehicle',
                            uploaded: _frontViewUploaded,
                            onTap: _isSaving
                                ? () {}
                                : () => _pickPhoto(
                                      onPicked: (bytes) {
                                        _frontViewBytes = bytes;
                                        _frontViewUploaded = true;
                                      },
                                    ),
                          ),
                          const SizedBox(height: 12),
                          DocUploadBox(
                            title: 'Side view',
                            uploaded: _sideViewUploaded,
                            onTap: _isSaving
                                ? () {}
                                : () => _pickPhoto(
                                      onPicked: (bytes) {
                                        _sideViewBytes = bytes;
                                        _sideViewUploaded = true;
                                      },
                                    ),
                          ),
                          const SizedBox(height: 12),
                          DocUploadBox(
                            title: 'Plate / back',
                            helper: 'Optional',
                            uploaded: _plateBackUploaded,
                            onTap: _isSaving
                                ? () {}
                                : () => _pickPhoto(
                                      onPicked: (bytes) {
                                        _plateBackBytes = bytes;
                                        _plateBackUploaded = true;
                                      },
                                    ),
                          ),
                          const SizedBox(height: 12),
                          const DocSectionHeader(text: 'Insurance'),
                          const SizedBox(height: 12),
                          DocUploadBox(
                            title: 'Insurance document',
                            uploaded: _insuranceUploaded,
                            onTap: _isSaving
                                ? () {}
                                : () =>
                                    _pick(() => _insuranceUploaded = true),
                          ),
                          const SizedBox(height: 12),
                          DocTextField(
                            label: 'Insurance expiry date',
                            hint: 'DD / MM / YYYY',
                            keyboardType: TextInputType.datetime,
                            controller: _insuranceExpiryController,
                          ),
                          const SizedBox(height: 22),
                          if (_isSaving)
                            const SizedBox(
                              height: 50,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: DocColors.green,
                                ),
                              ),
                            )
                          else
                            DocPrimaryButton(
                              label: 'Save',
                              onPressed: _save,
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'VEHICLE TYPE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: DocColors.textMuted,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _typeOption(0, AppAssets.vehicleCar, 'Car'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _typeOption(1, AppAssets.vehicleBike, 'Motorcycle'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _typeOption(int index, String iconAsset, String label) {
    final selected = _vehicleType == index;
    return GestureDetector(
      onTap: _isSaving ? null : () => setState(() => _vehicleType = index),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? DocColors.green : DocColors.white,
          borderRadius: BorderRadius.circular(10),
          border: selected ? null : Border.all(color: DocColors.fieldBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconAsset, width: 18, height: 18, fit: BoxFit.contain),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : DocColors.textField,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

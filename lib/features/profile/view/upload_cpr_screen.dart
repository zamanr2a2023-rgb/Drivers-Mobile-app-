import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yjeek_driver/features/profile/service/profile_service.dart';
import 'package:yjeek_driver/features/profile/view/doc_upload_ui.dart';
import 'package:yjeek_driver/services/api_service.dart';

/// DU1 · Upload — CPR / National ID
class UploadCprScreen extends StatefulWidget {
  const UploadCprScreen({super.key});

  @override
  State<UploadCprScreen> createState() => _UploadCprScreenState();
}

class _UploadCprScreenState extends State<UploadCprScreen> {
  static const String _frontType = 'CPR_FRONT';

  final ProfileService _profileService = ProfileService();
  final _cprNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _birthDateController = TextEditingController();

  Uint8List? _frontBytes;
  String? _frontImageUrl;
  bool _frontUploaded = false;
  bool _backUploaded = false;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExisting();
    });
  }

  @override
  void dispose() {
    _cprNumberController.dispose();
    _expiryController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final docs = await _profileService.getDocuments();
      if (!mounted) return;

      for (final doc in docs.documents) {
        if (doc.type.toUpperCase() != _frontType) continue;
        setState(() {
          _cprNumberController.text = doc.documentNumber?.trim() ?? '';
          _expiryController.text = _formatExpiryForDisplay(doc.expiryDate);
          _frontImageUrl = doc.imageUrl?.trim();
          _frontUploaded =
              (_frontImageUrl != null && _frontImageUrl!.isNotEmpty);
        });
        return;
      }

      for (final item in docs.checklist) {
        if (item.key.toLowerCase() != 'cpr') continue;
        for (final entry in item.items) {
          if (entry.type.toUpperCase() != _frontType) continue;
          setState(() {
            _cprNumberController.text = entry.documentNumber?.trim() ?? '';
            _expiryController.text = _formatExpiryForDisplay(entry.expiryDate);
            _frontImageUrl = entry.imageUrl?.trim();
            _frontUploaded =
                (_frontImageUrl != null && _frontImageUrl!.isNotEmpty) ||
                    entry.status.toUpperCase() != 'MISSING';
          });
          return;
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      showDocSnack(context, e.message);
    } catch (_) {
      if (!mounted) return;
      showDocSnack(context, 'Failed to load CPR document');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _formatExpiryForDisplay(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final iso = DateTime.tryParse(raw.trim());
    if (iso == null) return raw.trim();
    final d = iso.day.toString().padLeft(2, '0');
    final m = iso.month.toString().padLeft(2, '0');
    final y = iso.year.toString().padLeft(4, '0');
    return '$d / $m / $y';
  }

  /// Converts "DD / MM / YYYY" (or similar) to API format "YYYY-MM-DD".
  String? _expiryForApi() {
    final raw = _expiryController.text.trim();
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

  Future<void> _pickFront() async {
    final bytes = await pickDocPhoto(context);
    if (bytes == null || !mounted) return;
    setState(() {
      _frontBytes = bytes;
      _frontUploaded = true;
      _frontImageUrl = null;
    });
  }

  Future<void> _pickBack() async {
    final bytes = await pickDocPhoto(context);
    if (bytes == null || !mounted) return;
    setState(() => _backUploaded = true);
  }

  Future<void> _save() async {
    final number = _cprNumberController.text.trim();
    final expiry = _expiryForApi();
    final hasFront =
        (_frontBytes != null && _frontBytes!.isNotEmpty) ||
            (_frontImageUrl != null && _frontImageUrl!.trim().isNotEmpty);

    if (!hasFront) {
      showDocSnack(context, 'Please upload the CPR front side');
      return;
    }
    if (number.isEmpty) {
      showDocSnack(context, 'Please enter the CPR number');
      return;
    }
    if (expiry == null || expiry.isEmpty) {
      showDocSnack(context, 'Please enter the CPR expiry date');
      return;
    }
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      String imageUrl = _frontImageUrl?.trim() ?? '';
      if (_frontBytes != null && _frontBytes!.isNotEmpty) {
        imageUrl = await _profileService.uploadFile(
          bytes: _frontBytes!,
          category: 'documents',
          filename: 'cpr-front.jpg',
        );
      }

      if (imageUrl.isEmpty) {
        throw ApiException('Please upload the CPR front side');
      }

      final saved = await _profileService.upsertAccountDocument(
        type: _frontType,
        documentNumber: number,
        imageUrl: imageUrl,
        expiryDate: expiry,
      );

      if (!mounted) return;
      setState(() {
        _frontBytes = null;
        _frontImageUrl = saved.imageUrl?.trim();
        _frontUploaded =
            (_frontImageUrl != null && _frontImageUrl!.isNotEmpty);
        _cprNumberController.text = saved.documentNumber?.trim() ?? number;
        _expiryController.text = _formatExpiryForDisplay(saved.expiryDate);
      });

      showDocSnack(context, 'CPR / National ID saved');
      Navigator.maybePop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      showDocSnack(context, e.message);
    } catch (_) {
      if (!mounted) return;
      showDocSnack(context, 'Failed to save CPR document');
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
            const DocHeader(title: 'CPR / National ID'),
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
                            'Upload clear photos of the front and back of your CPR.',
                            style: TextStyle(
                              fontSize: 13,
                              color: DocColors.textMuted,
                              height: 16 / 13,
                            ),
                          ),
                          const SizedBox(height: 14),
                          DocUploadBox(
                            title: 'Front side',
                            uploaded: _frontUploaded,
                            height: 138,
                            photoBytes: _frontBytes,
                            onTap: _isSaving ? () {} : _pickFront,
                          ),
                          const SizedBox(height: 14),
                          DocUploadBox(
                            title: 'Back side',
                            uploaded: _backUploaded,
                            height: 138,
                            onTap: _isSaving ? () {} : _pickBack,
                          ),
                          const SizedBox(height: 14),
                          DocTextField(
                            label: 'CPR number',
                            hint: '000000000',
                            controller: _cprNumberController,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 14),
                          DocTextField(
                            label: 'CPR expiry date',
                            hint: 'DD / MM / YYYY',
                            controller: _expiryController,
                            keyboardType: TextInputType.datetime,
                          ),
                          const SizedBox(height: 14),
                          DocTextField(
                            label: 'Birth date',
                            hint: 'DD / MM / YYYY',
                            controller: _birthDateController,
                            keyboardType: TextInputType.datetime,
                          ),
                          const SizedBox(height: 22),
                          DocPrimaryButton(
                            label: _isSaving ? 'Saving…' : 'Save',
                            onPressed: _isSaving ? null : _save,
                            color: _isSaving
                                ? const Color(0xFFB7C5B7)
                                : DocColors.green,
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
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yjeek_driver/features/profile/service/profile_service.dart';
import 'package:yjeek_driver/features/profile/view/doc_upload_ui.dart';
import 'package:yjeek_driver/services/api_service.dart';

/// DU7 · Upload — Passport
class UploadPassportScreen extends StatefulWidget {
  const UploadPassportScreen({super.key});

  @override
  State<UploadPassportScreen> createState() => _UploadPassportScreenState();
}

class _UploadPassportScreenState extends State<UploadPassportScreen> {
  static const String _docType = 'PASSPORT';

  final ProfileService _profileService = ProfileService();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();

  Uint8List? _photoBytes;
  String? _imageUrl;
  String? _nationality;
  bool _photoUploaded = false;
  bool _isLoading = false;
  bool _isSaving = false;

  static const _nationalities = [
    'Bahraini',
    'Bangladeshi',
    'Egyptian',
    'Filipino',
    'Indian',
    'Nepalese',
    'Pakistani',
    'Sri Lankan',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExisting();
    });
  }

  @override
  void dispose() {
    _numberController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final docs = await _profileService.getDocuments();
      if (!mounted) return;

      for (final doc in docs.documents) {
        if (doc.type.toUpperCase() != _docType) continue;
        _applyLoaded(
          documentNumber: doc.documentNumber,
          nationality: doc.nationality,
          imageUrl: doc.imageUrl,
          expiryDate: doc.expiryDate,
        );
        return;
      }

      for (final item in docs.checklist) {
        if (item.key.toLowerCase() != 'passport') continue;
        for (final entry in item.items) {
          if (entry.type.toUpperCase() != _docType) continue;
          _applyLoaded(
            documentNumber: entry.documentNumber,
            nationality: entry.nationality,
            imageUrl: entry.imageUrl,
            expiryDate: entry.expiryDate,
            markUploadedIfNotMissing: entry.status.toUpperCase() != 'MISSING',
          );
          return;
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      showDocSnack(context, e.message);
    } catch (_) {
      if (!mounted) return;
      showDocSnack(context, 'Failed to load passport');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _applyLoaded({
    String? documentNumber,
    String? nationality,
    String? imageUrl,
    String? expiryDate,
    bool markUploadedIfNotMissing = false,
  }) {
    final url = imageUrl?.trim();
    final nation = nationality?.trim();
    setState(() {
      _numberController.text = documentNumber?.trim() ?? '';
      _expiryController.text = _formatExpiryForDisplay(expiryDate);
      _imageUrl = (url != null && url.isNotEmpty) ? url : null;
      _photoUploaded =
          (_imageUrl != null && _imageUrl!.isNotEmpty) || markUploadedIfNotMissing;
      if (nation != null && nation.isNotEmpty) {
        _nationality = _nationalities.contains(nation) ? nation : 'Other';
      }
    });
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

  Future<void> _pick() async {
    final bytes = await pickDocPhoto(context);
    if (bytes == null || !mounted) return;
    setState(() {
      _photoBytes = bytes;
      _photoUploaded = true;
      _imageUrl = null;
    });
  }

  Future<void> _save() async {
    final number = _numberController.text.trim();
    final nationality = _nationality?.trim() ?? '';
    final expiry = _expiryForApi();
    final hasPhoto =
        (_photoBytes != null && _photoBytes!.isNotEmpty) ||
            (_imageUrl != null && _imageUrl!.trim().isNotEmpty);

    if (!hasPhoto) {
      showDocSnack(context, 'Please upload the passport photo page');
      return;
    }
    if (nationality.isEmpty) {
      showDocSnack(context, 'Please select nationality');
      return;
    }
    if (number.isEmpty) {
      showDocSnack(context, 'Please enter the passport number');
      return;
    }
    if (expiry == null || expiry.isEmpty) {
      showDocSnack(context, 'Please enter the expiry date');
      return;
    }
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      String imageUrl = _imageUrl?.trim() ?? '';
      if (_photoBytes != null && _photoBytes!.isNotEmpty) {
        imageUrl = await _profileService.uploadFile(
          bytes: _photoBytes!,
          category: 'documents',
          filename: 'passport.jpg',
        );
      }

      if (imageUrl.isEmpty) {
        throw ApiException('Please upload the passport photo page');
      }

      final saved = await _profileService.upsertAccountDocument(
        type: _docType,
        documentNumber: number,
        nationality: nationality,
        imageUrl: imageUrl,
        expiryDate: expiry,
      );

      if (!mounted) return;
      setState(() {
        _photoBytes = null;
        _imageUrl = saved.imageUrl?.trim();
        _photoUploaded = (_imageUrl != null && _imageUrl!.isNotEmpty);
        _numberController.text = saved.documentNumber?.trim() ?? number;
        _expiryController.text = _formatExpiryForDisplay(saved.expiryDate);
        final nation = saved.nationality?.trim();
        if (nation != null && nation.isNotEmpty) {
          _nationality = _nationalities.contains(nation) ? nation : 'Other';
        }
      });

      showDocSnack(context, 'Passport saved');
      Navigator.maybePop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      showDocSnack(context, e.message);
    } catch (_) {
      if (!mounted) return;
      showDocSnack(context, 'Failed to save passport');
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
            const DocHeader(title: 'Passport'),
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
                            'Photo page of your passport.',
                            style: TextStyle(
                              fontSize: 13,
                              color: DocColors.textMuted,
                              height: 16 / 13,
                            ),
                          ),
                          const SizedBox(height: 14),
                          DocUploadBox(
                            title: 'Passport photo page',
                            uploaded: _photoUploaded,
                            photoBytes: _photoBytes,
                            onTap: _isSaving ? () {} : _pick,
                          ),
                          const SizedBox(height: 14),
                          _buildNationalityField(),
                          const SizedBox(height: 14),
                          DocTextField(
                            label: 'Passport number',
                            hint: 'A0000000',
                            controller: _numberController,
                          ),
                          const SizedBox(height: 14),
                          DocTextField(
                            label: 'Expiry date',
                            hint: 'DD / MM / YYYY',
                            controller: _expiryController,
                            keyboardType: TextInputType.datetime,
                          ),
                          const SizedBox(height: 14),
                          const DocTipBanner(
                            text:
                                'Passport must be valid for at least 6 months.',
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

  Widget _buildNationalityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NATIONALITY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: DocColors.textMuted,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: DocColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: DocColors.fieldBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _nationality,
              isExpanded: true,
              hint: const Text(
                'Select nationality',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: DocColors.textMuted,
                ),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: DocColors.textMuted,
              ),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DocColors.textField,
              ),
              items: _nationalities
                  .map(
                    (n) => DropdownMenuItem<String>(value: n, child: Text(n)),
                  )
                  .toList(),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _nationality = value),
            ),
          ),
        ),
      ],
    );
  }
}

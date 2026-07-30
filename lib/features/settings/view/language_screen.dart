import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/features/profile/service/profile_service.dart';
import 'package:yjeek_driver/features/profile/view/doc_upload_ui.dart';
import 'package:yjeek_driver/features/settings/provider/settings_provider.dart';
import 'package:yjeek_driver/services/api_service.dart';

/// DA3 · Language
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  static const _languages = [
    (primary: 'English', secondary: 'English', value: 'English', code: 'en'),
    (primary: 'العربية', secondary: 'Arabic', value: 'Arabic', code: 'ar'),
  ];

  final ProfileService _profileService = ProfileService();

  late String _selected;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final current = context.read<SettingsProvider>().language;
    _selected = _languages.any((l) => l.value == current)
        ? current
        : _languages.first.value;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentLanguage();
    });
  }

  String _valueForCode(String? code) {
    final normalized = code?.trim().toLowerCase() ?? '';
    for (final lang in _languages) {
      if (lang.code == normalized) return lang.value;
    }
    return _languages.first.value;
  }

  String get _selectedCode {
    for (final lang in _languages) {
      if (lang.value == _selected) return lang.code;
    }
    return _languages.first.code;
  }

  Future<void> _loadCurrentLanguage() async {
    try {
      final personal = await _profileService.getPersonalAccount();
      if (!mounted) return;
      setState(() => _selected = _valueForCode(personal.language));
    } catch (_) {
      // Keep local selection on failure.
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final savedCode = await _profileService.updateLanguage(_selectedCode);
      if (!mounted) return;

      final displayValue = _valueForCode(savedCode);
      context.read<SettingsProvider>().setLanguage(displayValue);
      showDocSnack(context, 'Language set to $displayValue');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      showDocSnack(context, e.message);
    } catch (_) {
      if (!mounted) return;
      showDocSnack(context, 'Failed to update language');
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DocColors.accountBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DocHeader(title: 'Language'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLanguageCard(),
                    const SizedBox(height: 14),
                    _buildInfoBanner(),
                    const SizedBox(height: 22),
                    if (_isSaving)
                      const SizedBox(
                        height: 52,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: DocColors.pillGreen,
                          ),
                        ),
                      )
                    else
                      DocPrimaryButton(
                        label: 'Save',
                        color: DocColors.pillGreen,
                        radius: 28,
                        height: 52,
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

  Widget _buildLanguageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: DocColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DocColors.accountBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _languages.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: DocColors.accountBorder,
              ),
            _buildLanguageRow(_languages[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguageRow(
    ({String primary, String secondary, String value, String code}) lang,
  ) {
    final selected = _selected == lang.value;
    return InkWell(
      onTap: _isSaving ? null : () => setState(() => _selected = lang.value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.primary,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: DocColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lang.secondary,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B756E),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? DocColors.pillGreen : DocColors.white,
                shape: BoxShape.circle,
                border: selected
                    ? null
                    : Border.all(color: DocColors.accountBorder, width: 1.5),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DocColors.bannerGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('🌐', style: TextStyle(fontSize: 14, height: 1.1)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'The language applies across the whole app.',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 15 / 12.5,
                color: DocColors.bannerGreenText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

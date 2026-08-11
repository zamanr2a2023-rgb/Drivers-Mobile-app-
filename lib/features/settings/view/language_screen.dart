import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/features/content/model/app_language_option.dart';
import 'package:yjeek_driver/features/profile/view/doc_upload_ui.dart';
import 'package:yjeek_driver/features/settings/provider/settings_provider.dart';
import 'package:yjeek_driver/l10n/l10n.dart';
import 'package:yjeek_driver/services/api_service.dart';

/// DA3 · Language — options from `GET /content/languages`,
/// strings from `GET /content/translations`, preference via
/// `PATCH /drivers/account/language`.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late String _selected;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _selected = settings.languageCode;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    final settings = context.read<SettingsProvider>();
    if (!settings.isInitialized) {
      await settings.initialize();
    }
    await settings.loadLanguages();
    if (!mounted) return;
    setState(() => _selected = settings.languageCode);
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final settings = context.read<SettingsProvider>();
      final savedCode = await settings.setLanguage(_selected);
      if (!mounted) return;

      String display = savedCode == 'ar' ? 'Arabic' : 'English';
      for (final lang in settings.languages) {
        if (lang.code == savedCode) {
          display = lang.englishLabel;
          break;
        }
      }

      showDocSnack(
        context,
        L10n.trParams('Language set to {name}', {'name': display}),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      showDocSnack(context, e.message);
    } catch (_) {
      if (!mounted) return;
      showDocSnack(context, L10n.tr('Failed to update language'));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final languages = settings.languages.isNotEmpty
        ? settings.languages
        : AppLanguageOption.fallback;
    final loadingList =
        settings.languagesLoading && settings.languages.isEmpty;

    return Scaffold(
      backgroundColor: DocColors.accountBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DocHeader(title: L10n.tr('Language')),
            Expanded(
              child: loadingList
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: DocColors.pillGreen,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLanguageCard(languages),
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
                              label: L10n.tr('Save'),
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

  Widget _buildLanguageCard(List<AppLanguageOption> languages) {
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
          for (var i = 0; i < languages.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: DocColors.accountBorder,
              ),
            _buildLanguageRow(languages[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguageRow(AppLanguageOption lang) {
    final selected = _selected == lang.code;
    return InkWell(
      onTap: _isSaving ? null : () => setState(() => _selected = lang.code),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.nativeName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: DocColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lang.name,
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
        children: [
          const Text('🌐', style: TextStyle(fontSize: 14, height: 1.1)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              L10n.tr('The language applies across the whole app.'),
              style: const TextStyle(
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

import 'package:flutter/material.dart';
import 'package:yjeek_driver/core/constants/storage_keys.dart';
import 'package:yjeek_driver/features/content/model/app_language_option.dart';
import 'package:yjeek_driver/features/content/service/content_service.dart';
import 'package:yjeek_driver/features/profile/service/profile_service.dart';
import 'package:yjeek_driver/l10n/app_locales.dart';
import 'package:yjeek_driver/l10n/l10n.dart';
import 'package:yjeek_driver/services/api_service.dart';
import 'package:yjeek_driver/services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    ContentService? contentService,
    ProfileService? profileService,
  })  : _content = contentService ?? ContentService(),
        _profile = profileService ?? ProfileService();

  final ContentService _content;
  final ProfileService _profile;
  final Set<String> _loadingTranslations = {};

  String _languageCode = AppLocales.defaultCode;
  List<AppLanguageOption> _languages = AppLanguageOption.fallback;
  bool _languagesLoading = false;
  bool _notificationsEnabled = true;
  bool _initialized = false;
  int _revision = 0;

  String get languageCode => _languageCode;

  /// Display name for settings tiles (English / Arabic / native).
  String get language {
    for (final lang in _languages) {
      if (lang.code == _languageCode) return lang.englishLabel;
    }
    return _languageCode == 'ar' ? 'Arabic' : 'English';
  }

  Locale get locale => AppLocales.fromCode(_languageCode);

  bool get isRtl => _languageCode == 'ar';

  List<AppLanguageOption> get languages => List.unmodifiable(_languages);

  bool get languagesLoading => _languagesLoading;

  bool get notificationsEnabled => _notificationsEnabled;

  /// Bumps when locale/strings change so MaterialApp rebuilds.
  int get revision => _revision;

  bool get isInitialized => _initialized;

  /// Load saved language, pull backend catalog, and list available languages.
  Future<void> initialize() async {
    if (_initialized) return;

    final storage = await StorageService.getInstance();
    final saved = storage.getString(StorageKeys.languageCode);
    final code = AppLocales.isSupported(saved ?? '')
        ? saved!.toLowerCase()
        : AppLocales.defaultCode;

    _languageCode = code;
    L10n.load(code);
    _initialized = true;
    notifyListeners();

    await Future.wait([
      loadLanguages(),
      ensureTranslationsLoaded(force: true),
      _syncFromAccountIfPossible(),
    ]);
  }

  Future<void> loadLanguages() async {
    _languagesLoading = true;
    notifyListeners();
    try {
      _languages = await _content.fetchLanguages();
    } finally {
      _languagesLoading = false;
      notifyListeners();
    }
  }

  /// Prefetch / refresh backend strings for the current language.
  Future<void> ensureTranslationsLoaded({bool force = false}) async {
    final code = _languageCode;
    if (!force && L10n.hasRemote(code)) return;
    await _loadRemote(code);
    L10n.load(code);
    _revision++;
    notifyListeners();
  }

  /// Apply language locally, load backend strings, persist, and sync account.
  Future<String> setLanguage(
    String code, {
    bool persistRemote = true,
  }) async {
    final normalized = AppLocales.isSupported(code)
        ? code.trim().toLowerCase()
        : AppLocales.defaultCode;

    await _loadRemote(normalized);
    L10n.load(normalized);
    _languageCode = normalized;

    final storage = await StorageService.getInstance();
    await storage.saveString(StorageKeys.languageCode, normalized);

    if (persistRemote && ApiService.instance.accessToken != null) {
      try {
        final saved = await _profile.updateLanguage(normalized);
        if (AppLocales.isSupported(saved)) {
          _languageCode = saved.toLowerCase();
          L10n.load(_languageCode);
          await storage.saveString(StorageKeys.languageCode, _languageCode);
        }
      } catch (_) {
        // Local language still applies if account sync fails.
      }
    }

    _revision++;
    notifyListeners();
    return _languageCode;
  }

  /// Compatibility with older call sites that passed display names.
  @Deprecated('Use setLanguage with language code (en/ar)')
  void setLanguageDisplayName(String displayName) {
    final lower = displayName.trim().toLowerCase();
    final code = lower.startsWith('ar') || lower.contains('عرب') ? 'ar' : 'en';
    // Fire-and-forget local apply without awaiting.
    setLanguage(code, persistRemote: false);
  }

  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  Future<void> _syncFromAccountIfPossible() async {
    if (ApiService.instance.accessToken == null) return;
    try {
      final personal = await _profile.getPersonalAccount();
      final accountLang = personal.language.trim().toLowerCase();
      if (!AppLocales.isSupported(accountLang)) return;
      if (accountLang == _languageCode) return;
      await setLanguage(accountLang, persistRemote: false);
    } catch (_) {
      // Keep local preference.
    }
  }

  Future<void> _loadRemote(String lang) async {
    if (_loadingTranslations.contains(lang)) return;
    _loadingTranslations.add(lang);
    try {
      final strings = await _content.fetchTranslations(lang);
      if (strings.isNotEmpty) {
        L10n.setRemoteTranslations(lang, strings);
      }
    } catch (_) {
      // Keep bundled offline fallbacks.
    } finally {
      _loadingTranslations.remove(lang);
    }
  }
}

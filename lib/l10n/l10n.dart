import 'package:yjeek_driver/l10n/app_locales.dart';
import 'package:yjeek_driver/l10n/translations_ar.dart';

/// Lightweight i18n lookup keyed by English source strings.
///
/// Priority for a given language:
/// 1. Remote catalog from `GET /content/translations?lang=`
/// 2. Bundled Arabic map (offline fallback)
/// 3. English source key
abstract final class L10n {
  static String _code = AppLocales.defaultCode;

  /// Remote overlays keyed by language code.
  static final Map<String, Map<String, String>> _remoteByLang = {};

  static String get code => _code;

  static bool get isArabic => _code == 'ar';

  static bool get isEnglish => _code == 'en';

  static bool get isRtl => _code == 'ar';

  static bool hasRemote(String code) =>
      (_remoteByLang[code.toLowerCase()]?.isNotEmpty ?? false);

  static void load(String code) {
    _code = AppLocales.isSupported(code)
        ? code.toLowerCase()
        : AppLocales.defaultCode;
  }

  /// Replace / merge remote strings for [lang] (from backend).
  static void setRemoteTranslations(String lang, Map<String, String> strings) {
    final code = lang.toLowerCase();
    if (strings.isEmpty) {
      _remoteByLang.remove(code);
      return;
    }
    _remoteByLang[code] = Map<String, String>.from(strings);
  }

  static void clearRemoteTranslations([String? lang]) {
    if (lang == null) {
      _remoteByLang.clear();
      return;
    }
    _remoteByLang.remove(lang.toLowerCase());
  }

  /// Translate an English UI string. Falls back to [english] when missing.
  static String tr(String english) {
    final remote = _remoteByLang[_code];
    final fromRemote = remote?[english];
    if (fromRemote != null && fromRemote.isNotEmpty) return fromRemote;

    if (_code == 'ar') {
      return kArabicTranslations[english] ?? english;
    }
    return english;
  }

  /// Replace `{name}` placeholders after translation.
  static String trParams(String english, Map<String, String> params) {
    var out = tr(english);
    params.forEach((key, value) {
      out = out.replaceAll('{$key}', value);
    });
    return out;
  }
}

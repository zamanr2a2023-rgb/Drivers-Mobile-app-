import 'package:yjeek_driver/core/constants/api_endpoints.dart';
import 'package:yjeek_driver/features/content/model/app_language_option.dart';
import 'package:yjeek_driver/features/dashboard/model/ui_banner_model.dart';
import 'package:yjeek_driver/l10n/app_locales.dart';
import 'package:yjeek_driver/services/api_service.dart';

/// Public content APIs used for localization.
class ContentService {
  ContentService({ApiService? apiService}) : _api = apiService ?? ApiService.instance;

  final ApiService _api;

  /// GET /content/languages — enabled languages from admin localization.
  Future<List<AppLanguageOption>> fetchLanguages() async {
    try {
      final response = await _api.get(ApiEndpoints.contentLanguages);
      if (response['success'] != true) return AppLanguageOption.fallback;

      final data = response['data'];
      if (data is! Map) return AppLanguageOption.fallback;

      final rows = data['languages'];
      if (rows is! List) return AppLanguageOption.fallback;

      final out = <AppLanguageOption>[];
      for (final raw in rows) {
        if (raw is! Map) continue;
        final option = AppLanguageOption.fromJson(Map<String, dynamic>.from(raw));
        if (option.code.isEmpty) continue;
        if (!AppLocales.isSupported(option.code)) continue;
        out.add(option);
      }
      return out.isEmpty ? AppLanguageOption.fallback : out;
    } catch (_) {
      return AppLanguageOption.fallback;
    }
  }

  /// GET /content/translations?lang= — full UI string catalog from backend.
  Future<Map<String, String>> fetchTranslations(String lang) async {
    try {
      final response = await _api.get(ApiEndpoints.contentTranslationsFor(lang));
      if (response['success'] != true) return const {};

      final data = response['data'];
      if (data is! Map) return const {};

      final strings = data['strings'];
      if (strings is! Map) return const {};

      final out = <String, String>{};
      strings.forEach((key, value) {
        if (key is! String) return;
        if (value is String && value.isNotEmpty) {
          out[key] = value;
        }
      });
      return out;
    } catch (_) {
      return const {};
    }
  }

  /// GET /drivers/ui/banners?screen=global — app-open pop-up.
  Future<HomeUiBannersModel> fetchGlobalBanners() async {
    final response = await _api.get(ApiEndpoints.uiBannersGlobal);
    if (response['success'] != true) {
      final message = response['message']?.toString().trim();
      throw ApiException(
        (message != null && message.isNotEmpty)
            ? message
            : 'Failed to load banners',
      );
    }

    try {
      return HomeUiBannersModel.fromJson(response);
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }
}

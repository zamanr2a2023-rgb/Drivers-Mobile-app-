import 'package:flutter/material.dart';

/// Supported app languages (Bahrain launch: English + Arabic).
abstract final class AppLocales {
  static const en = Locale('en');
  static const ar = Locale('ar');

  static const supported = <Locale>[en, ar];

  static const defaultCode = 'en';

  static bool isSupported(String code) => code == 'en' || code == 'ar';

  static Locale fromCode(String? code) {
    final c = (code ?? defaultCode).toLowerCase();
    return c == 'ar' ? ar : en;
  }

  static String codeOf(Locale locale) =>
      locale.languageCode.toLowerCase() == 'ar' ? 'ar' : 'en';
}

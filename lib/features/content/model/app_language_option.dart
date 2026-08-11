class AppLanguageOption {
  const AppLanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
    this.rtl = false,
  });

  final String code;
  final String name;
  final String nativeName;
  final bool rtl;

  /// Label shown in Language settings (native name preferred).
  String get label => nativeName.isNotEmpty ? nativeName : name;

  String get englishLabel => name.isNotEmpty ? name : code.toUpperCase();

  static const fallback = <AppLanguageOption>[
    AppLanguageOption(
      code: 'en',
      name: 'English',
      nativeName: 'English',
    ),
    AppLanguageOption(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      rtl: true,
    ),
  ];

  factory AppLanguageOption.fromJson(Map<String, dynamic> json) {
    final code = json['code']?.toString().trim().toLowerCase() ?? '';
    final name = json['name']?.toString() ?? code.toUpperCase();
    final nativeName = json['nativeName']?.toString() ?? name;
    return AppLanguageOption(
      code: code,
      name: name,
      nativeName: nativeName,
      rtl: json['rtl'] == true || code == 'ar',
    );
  }
}

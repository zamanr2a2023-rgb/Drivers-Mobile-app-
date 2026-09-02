class UiBannerModel {
  const UiBannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.bannerType,
    required this.placementKey,
    required this.tapAction,
    this.targetId,
    this.ctaLabel,
    this.ctaUrl,
    this.sortOrder = 0,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String bannerType;
  final String placementKey;
  final String tapAction;
  final String? targetId;
  final String? ctaLabel;
  final String? ctaUrl;
  final int sortOrder;

  bool get hasImage => imageUrl.trim().isNotEmpty;

  factory UiBannerModel.fromJson(Map<String, dynamic> json) {
    return UiBannerModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString().trim() ?? '',
      subtitle: json['subtitle']?.toString().trim() ?? '',
      imageUrl: json['imageUrl']?.toString().trim() ?? '',
      bannerType: json['bannerType']?.toString() ?? 'STATIC',
      placementKey: json['placementKey']?.toString() ?? '',
      tapAction: json['tapAction']?.toString() ?? '',
      targetId: _nullableString(json['targetId']),
      ctaLabel: _nullableString(json['ctaLabel']),
      ctaUrl: _nullableString(json['ctaUrl']),
      sortOrder: _asInt(json['sortOrder']),
    );
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class HomeUiBannersModel {
  const HomeUiBannersModel({
    required this.app,
    required this.count,
    required this.banners,
    required this.bannersByPlacement,
  });

  final String app;
  final int count;
  final List<UiBannerModel> banners;
  final Map<String, List<UiBannerModel>> bannersByPlacement;

  List<UiBannerModel> forPlacement(String placementKey) {
    final rows = List<UiBannerModel>.from(
      bannersByPlacement[placementKey] ?? const [],
    );
    rows.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return rows.where((banner) => banner.hasImage).toList();
  }

  List<UiBannerModel> get visibleBanners {
    final rows = List<UiBannerModel>.from(banners);
    rows.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return rows.where((banner) => banner.hasImage).toList();
  }

  factory HomeUiBannersModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map) {
      throw const FormatException('Invalid banners response');
    }
    final map = Map<String, dynamic>.from(data);

    final banners = _parseBannerList(map['banners']);
    final byPlacement = <String, List<UiBannerModel>>{};

    final grouped = map['bannersByPlacement'];
    if (grouped is Map) {
      grouped.forEach((key, value) {
        final placement = key.toString();
        if (placement.isEmpty) return;
        byPlacement[placement] = _parseBannerList(value);
      });
    }

    if (byPlacement.isEmpty) {
      for (final banner in banners) {
        if (banner.placementKey.isEmpty) continue;
        byPlacement
            .putIfAbsent(banner.placementKey, () => <UiBannerModel>[])
            .add(banner);
      }
    }

    return HomeUiBannersModel(
      app: map['app']?.toString() ?? 'CHAMP',
      count: _asInt(map['count'], fallback: banners.length),
      banners: banners,
      bannersByPlacement: byPlacement,
    );
  }

  static List<UiBannerModel> _parseBannerList(dynamic raw) {
    if (raw is! List) return const [];
    final out = <UiBannerModel>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final banner = UiBannerModel.fromJson(Map<String, dynamic>.from(item));
      if (banner.id.isEmpty && !banner.hasImage) continue;
      out.add(banner);
    }
    return out;
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

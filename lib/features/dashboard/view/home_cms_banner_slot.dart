import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yjeek_driver/features/dashboard/model/ui_banner_model.dart';
import 'package:yjeek_driver/features/dashboard/provider/dashboard_provider.dart';
import 'package:yjeek_driver/l10n/l10n.dart';
import 'package:yjeek_driver/routes/route_names.dart';

class HomeCmsBannerSlot extends StatelessWidget {
  const HomeCmsBannerSlot({
    super.key,
    required this.placementKey,
    this.showError = false,
    this.height = compactHeight,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 8),
    this.banners,
    this.loading,
    this.error,
    this.onRetry,
  });

  static const String top = 'champ_home_top';
  static const String mid = 'champ_home_mid';
  static const String orders = 'champ_orders_banner';
  static const String earnings = 'champ_earnings_banner';
  static const double compactHeight = 120;
  static const double midHeight = 120;

  final String placementKey;
  final bool showError;
  final double height;
  final EdgeInsetsGeometry padding;
  final List<UiBannerModel>? banners;
  final bool? loading;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final dashboard =
        banners == null ? context.watch<DashboardProvider>() : null;
    final resolvedBanners = banners ?? dashboard!.bannersFor(placementKey);
    final resolvedLoading = loading ??
        ((dashboard?.bannersLoading ?? false) && resolvedBanners.isEmpty);
    final resolvedError = error ?? dashboard?.bannersError;

    if (resolvedLoading && resolvedBanners.isEmpty) {
      return Padding(
        padding: padding,
        child: _BannerSkeleton(height: height),
      );
    }

    if (resolvedBanners.isEmpty) {
      if (!showError || resolvedError == null || resolvedError.isEmpty) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: padding,
        child: _BannerErrorBar(
          message: resolvedError,
          onRetry: onRetry ??
              () => context.read<DashboardProvider>().loadHomeBanners(),
        ),
      );
    }

    return Padding(
      padding: padding,
      child: resolvedBanners.length == 1
          ? _BannerCard(banner: resolvedBanners.first, height: height)
          : _BannerCarousel(banners: resolvedBanners, height: height),
    );
  }
}

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({
    required this.banners,
    required this.height,
  });

  final List<UiBannerModel> banners;
  final double height;

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  late final PageController _controller;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (_, index) => _BannerCard(
              banner: widget.banners[index],
              height: widget.height,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.banners.length, (index) {
            final active = index == _page;
            return Container(
              width: active ? 14 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFD7E3D7),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.banner,
    required this.height,
  });

  final UiBannerModel banner;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onTap(context, banner),
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: double.infinity,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  banner.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _BannerFallback(),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const _BannerSkeleton(height: double.infinity);
                  },
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0x99000000),
                      ],
                    ),
                  ),
                ),
                if (banner.title.isNotEmpty || banner.subtitle.isNotEmpty)
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (banner.title.isNotEmpty)
                          Text(
                            banner.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                        if (banner.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            banner.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context, UiBannerModel banner) async {
    final url = banner.ctaUrl;
    if (url != null && url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri == null) return;
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
      return;
    }

    final action = banner.tapAction.trim().toUpperCase();
    if (action == 'OPEN_CHAMP_SCREEN') {
      final route = _routeForTarget(banner.targetId);
      if (route == null || !context.mounted) return;
      Navigator.pushNamed(context, route);
    }
  }

  String? _routeForTarget(String? targetId) {
    switch (targetId?.trim().toLowerCase()) {
      case 'earnings':
        return RouteNames.earnings;
      case 'orders':
        return RouteNames.orders;
      case 'performance':
        return RouteNames.performance;
      case 'profile':
      case 'account':
        return RouteNames.profile;
      case 'notifications':
        return RouteNames.notifications;
      case 'settings':
        return RouteNames.settings;
      case 'payout':
        return RouteNames.payout;
      default:
        return null;
    }
  }
}

class _BannerSkeleton extends StatelessWidget {
  const _BannerSkeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height == double.infinity ? HomeCmsBannerSlot.compactHeight : height,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E1)),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: Color(0xFF4CAF50),
        ),
      ),
    );
  }
}

class _BannerFallback extends StatelessWidget {
  const _BannerFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8F4DF),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 36,
        color: Color(0xFF2E7D32),
      ),
    );
  }
}

class _BannerErrorBar extends StatelessWidget {
  const _BannerErrorBar({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2D9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD47D)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9A6A1E),
                height: 1.3,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(L10n.tr('Retry')),
          ),
        ],
      ),
    );
  }
}

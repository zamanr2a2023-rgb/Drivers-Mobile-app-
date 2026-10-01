import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yjeek_driver/features/content/service/content_service.dart';
import 'package:yjeek_driver/features/dashboard/model/ui_banner_model.dart';
import 'package:yjeek_driver/l10n/l10n.dart';
import 'package:yjeek_driver/routes/route_names.dart';
import 'package:yjeek_driver/services/api_service.dart';

/// App-open CMS pop-up from `GET /drivers/ui/banners?screen=global`.
class AppOpenBannerPopup {
  AppOpenBannerPopup._();

  static bool _shownThisSession = false;

  static void resetSession() => _shownThisSession = false;

  static Future<void> maybeShow(BuildContext context) async {
    if (_shownThisSession) return;
    _shownThisSession = true;

    try {
      final data = await ContentService().fetchGlobalBanners();
      final banners = data.visibleBanners;
      if (banners.isEmpty || !context.mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => _AppOpenBannerDialog(banners: banners),
      );
    } on ApiException {
      // Empty / error: skip pop-up so home is not blocked.
    } catch (_) {}
  }
}

class _AppOpenBannerDialog extends StatelessWidget {
  const _AppOpenBannerDialog({required this.banners});

  final List<UiBannerModel> banners;

  @override
  Widget build(BuildContext context) {
    final banner = banners.first;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1A1A1A),
              ),
              icon: const Icon(Icons.close_rounded),
              tooltip: L10n.tr('Close'),
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _onTap(context, banner),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.network(
                      banner.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFE8F4DF),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_outlined,
                          size: 40,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const ColoredBox(
                          color: Color(0xFFF3F7F2),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (banner.title.isNotEmpty || banner.subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (banner.title.isNotEmpty)
                            Text(
                              banner.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          if (banner.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              banner.subtitle,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7B6F),
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
        ],
      ),
    );
  }

  Future<void> _onTap(BuildContext context, UiBannerModel banner) async {
    Navigator.of(context).pop();
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
    if (action != 'OPEN_CHAMP_SCREEN') return;
    final route = _routeForTarget(banner.targetId);
    if (route == null || !context.mounted) return;
    Navigator.pushNamed(context, route);
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

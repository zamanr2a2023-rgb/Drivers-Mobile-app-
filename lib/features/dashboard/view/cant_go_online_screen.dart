import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/features/settings/provider/settings_provider.dart';
import 'package:yjeek_driver/l10n/l10n.dart';
import 'package:yjeek_driver/routes/route_names.dart';

class CantGoOnlineScreen extends StatelessWidget {
  const CantGoOnlineScreen({super.key});

  static const Color _subtitleColor = Color(0xFF8A958A);
  static const Color _headerBg = Color(0xFF2F3330);
  static const Color _buttonGreen = Color(0xFF2E7D32);
  static const Color _cardBorder = Color(0xFFE0E5E0);
  static const Color _iconPillBg = Color(0xFFF3F5F3);
  static const Color _iconGrey = Color(0xFF7A847A);
  static const Color _noteBg = Color(0xFFF7F8F7);

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: _headerBg,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              color: _headerBg,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 20,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          if (Navigator.canPop(context)) Navigator.pop(context);
                        },
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                L10n.tr("Can't go online"),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                L10n.tr("Shift won't start yet"),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFFB8BEB8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _iconPillBg,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: _cardBorder),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.wifi_off_rounded,
                          size: 28,
                          color: _iconGrey,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        L10n.tr(
                          'You need an active data connection and GPS to enter the dispatch pool.',
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: _subtitleColor,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _StatusRow(label: L10n.tr('Internet')),
                      const SizedBox(height: 12),
                      _StatusRow(label: L10n.tr('GPS / Location')),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: _noteBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _cardBorder),
                        ),
                        child: Text(
                          L10n.tr(
                            'Your shift does not start until both are confirmed active.',
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: _subtitleColor,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              RouteNames.updateRequired,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _buttonGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            L10n.tr('Retry connection'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label});

  final String label;

  static const Color _textDark = Color(0xFF1E1E1E);
  static const Color _cardBorder = Color(0xFFE0E5E0);
  static const Color _offRed = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: _offRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
          ),
          Text(
            L10n.tr('Off'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _offRed,
            ),
          ),
        ],
      ),
    );
  }
}

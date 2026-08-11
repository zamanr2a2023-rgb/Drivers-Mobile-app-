import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/features/settings/provider/settings_provider.dart';
import 'package:yjeek_driver/l10n/l10n.dart';
import 'package:yjeek_driver/routes/route_names.dart';

class AccountNotRegisteredScreen extends StatelessWidget {
  const AccountNotRegisteredScreen({
    super.key,
    this.phoneDisplay,
  });

  /// Formatted phone shown in the error copy, e.g. `+973 3311 2233`.
  final String? phoneDisplay;

  static const Color _textDark = Color(0xFF1E1E1E);
  static const Color _descriptionColor = Color(0xFF7A7A7A);
  static const Color _backButtonBg = Color(0xFFF3F8F4);
  static const Color _iconBoxBg = Color(0xFFFBE3E5);
  static const Color _infoBoxBg = Color(0xFFF1F8F3);
  static const Color _infoTextColor = Color(0xFF005C2E);
  static const Color _buttonBorder = Color(0xFFD5E2D7);
  static const String _defaultPhoneDisplay = '+973 3300 0000';

  void _goToPhoneInput(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();
    final resolvedPhone = () {
      final fromCtor = phoneDisplay?.trim();
      if (fromCtor != null && fromCtor.isNotEmpty) return fromCtor;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && args.trim().isNotEmpty) return args.trim();
      return _defaultPhoneDisplay;
    }();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => _goToPhoneInput(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: _backButtonBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 16,
                          color: _textDark,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _iconBoxBg,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/number_not_registered_icon.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      L10n.tr('Number not registered'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: 310,
                      child: Text(
                        '$resolvedPhone ${L10n.tr("isn't registered as a Yjeek champ. Please check the number, or apply to drive with Yjeek.")}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: _descriptionColor,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: _infoBoxBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '• ${L10n.tr('Already applied? Your account may still be under review')}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _infoTextColor,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => _goToPhoneInput(context),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _textDark,
                            elevation: 0,
                            side: const BorderSide(
                              color: _buttonBorder,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: Text(
                            L10n.tr('Try another number'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

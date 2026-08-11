import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/features/auth/model/otp_screen_args.dart';
import 'package:yjeek_driver/features/auth/service/auth_service.dart';
import 'package:yjeek_driver/features/settings/provider/settings_provider.dart';
import 'package:yjeek_driver/l10n/l10n.dart';
import 'package:yjeek_driver/routes/route_names.dart';
import 'package:yjeek_driver/services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _background = Color(0xFFF7FBF7);
  static const Color _textDark = Color(0xFF1E1E1E);
  static const Color _subtitleColor = Color(0xFF6B7C6B);
  static const Color _borderColor = Color(0xFFDDE8DD);
  static const Color _placeholderColor = Color(0xFF7D8C7D);
  static const Color _buttonGreen = Color(0xFF4CAF50);
  static const String _countryCode = '+973';

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _phoneDigits =>
      _phoneController.text.replaceAll(RegExp(r'\s'), '');

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digits = value.replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^\d{8}$').hasMatch(digits)) {
      return 'Enter a valid 8-digit phone number';
    }
    return null;
  }

  String? _validateCountryCode() {
    if (_countryCode.trim().isEmpty) {
      return 'Country code is required';
    }
    if (!RegExp(r'^\+\d{1,4}$').hasMatch(_countryCode.trim())) {
      return 'Enter a valid country code';
    }
    return null;
  }

  Future<void> _onSendCode() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final countryCodeError = _validateCountryCode();
    if (countryCodeError != null) {
      _showError(countryCodeError);
      return;
    }

    final phone = _phoneDigits;
    final countryCode = _countryCode.trim();

    setState(() => _isLoading = true);

    try {
      final result = await _authService.sendOtp(
        phone: phone,
        countryCode: countryCode,
      );

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        RouteNames.otp,
        arguments: OtpScreenArgs(
          phone: phone,
          countryCode: countryCode,
          expiresInSeconds: result.expiresInSeconds,
          debugDevCode: kDebugMode ? result.devCode : null,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: _background,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 24,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          L10n.tr('login'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      L10n.tr('Welcome back champ,'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      L10n.tr(
                        'Enter your registered phone number to receive a one-time verification code.',
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: _subtitleColor,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderColor, width: 1),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Text('🇧🇭', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          const Text(
                            _countryCode,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 1,
                            height: 24,
                            color: _borderColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              enabled: !_isLoading,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: _textDark,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(8),
                                _BahrainPhoneFormatter(),
                              ],
                              decoration: const InputDecoration(
                                hintText: '3300 0000',
                                hintStyle: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: _placeholderColor,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              validator: _validatePhone,
                            ),
                          ),
                          const SizedBox(width: 14),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onSendCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _buttonGreen,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _buttonGreen.withValues(
                            alpha: 0.7,
                          ),
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                L10n.tr('Send code'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BahrainPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\s'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 4) buffer.write(' ');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

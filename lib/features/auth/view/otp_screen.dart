import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/features/auth/model/account_not_registered_exception.dart';
import 'package:yjeek_driver/features/auth/model/otp_screen_args.dart';
import 'package:yjeek_driver/features/auth/provider/auth_provider.dart';
import 'package:yjeek_driver/routes/route_names.dart';
import 'package:yjeek_driver/services/push_notification_service.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    this.phoneDisplay,
    this.phone,
    this.countryCode,
    this.expiresInSeconds,
    this.debugDevCode,
  });

  final String? phoneDisplay;
  final String? phone;
  final String? countryCode;
  final int? expiresInSeconds;

  /// Debug-only OTP from API. Never shown in release builds.
  final String? debugDevCode;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const Color _background = Color(0xFFF7FBF7);
  static const Color _textDark = Color(0xFF1E1E1E);
  static const Color _subtitleColor = Color(0xFF6B7C6B);
  static const Color _errorRed = Color(0xFFD71920);
  static const Color _buttonGreen = Color(0xFF4CAF50);
  static const String _defaultPhoneDisplay = '+973 3300 0000';

  static const int _otpLength = 4;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  bool _isWrongCode = false;
  bool _isLoading = false;
  bool _isResending = false;
  String _errorHeading = 'Incorrect code — please try again';
  late int _expiresInSeconds;
  late int _resendSeconds;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
    _expiresInSeconds = widget.expiresInSeconds ?? 24;
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNodes[0].requestFocus();
      _showDebugDevCode(widget.debugDevCode);
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _phoneText {
    if (widget.phoneDisplay != null && widget.phoneDisplay!.isNotEmpty) {
      return widget.phoneDisplay!;
    }
    if (widget.phone != null && widget.countryCode != null) {
      return OtpScreenArgs(
        phone: widget.phone!,
        countryCode: widget.countryCode!,
        expiresInSeconds: widget.expiresInSeconds ?? 0,
      ).phoneDisplay;
    }
    return _defaultPhoneDisplay;
  }

  String? get _phone => widget.phone;
  String? get _countryCode => widget.countryCode;

  String get _otpCode => _controllers.map((c) => c.text).join();

  int get _activeIndex {
    for (var i = 0; i < _otpLength; i++) {
      if (_controllers[i].text.isEmpty) return i;
    }
    return _otpLength - 1;
  }

  void _startResendTimer({int? expiresInSeconds}) {
    if (expiresInSeconds != null) {
      _expiresInSeconds = expiresInSeconds;
    }
    _resendTimer?.cancel();
    _resendSeconds = _expiresInSeconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _resendSeconds--);
    });
  }

  String get _timerText {
    final minutes = (_resendSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_resendSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _onOtpChanged(int index, String value) {
    if (value.length > 1) {
      _controllers[index].text = value[value.length - 1];
      _controllers[index].selection = const TextSelection.collapsed(offset: 1);
      value = _controllers[index].text;
    }

    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    setState(() {
      if (_isWrongCode) {
        _isWrongCode = false;
        _errorHeading = 'Incorrect code — please try again';
      }
    });
  }

  void _focusActiveBox() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNodes[_activeIndex].requestFocus();
    });
  }

  void _showWrongCode([String? message]) {
    setState(() {
      _isWrongCode = true;
      _errorHeading = (message != null && message.trim().isNotEmpty)
          ? message.trim()
          : 'Incorrect code — please try again';
    });
    _focusActiveBox();
  }

  Future<void> _onVerify() async {
    if (_isLoading) return;

    final otp = _otpCode;
    if (otp.length < _otpLength) {
      _showWrongCode('Enter the complete 4-digit code');
      return;
    }

    final phone = _phone;
    final countryCode = _countryCode;
    if (phone == null ||
        phone.isEmpty ||
        countryCode == null ||
        countryCode.isEmpty) {
      _showWrongCode('Phone number is missing. Please go back and try again.');
      return;
    }

    setState(() {
      _isLoading = true;
      _isWrongCode = false;
    });

    try {
      final result = await context.read<AuthProvider>().verifyOtp(
            phone: phone,
            countryCode: countryCode,
            code: otp,
          );

      if (!mounted) return;

      if (result == null) {
        final error = context.read<AuthProvider>().error;
        _showWrongCode(error);
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.mainNavigation,
        (route) => false,
      );
      PushNotificationService.instance.consumePendingOpen();
    } on AccountNotRegisteredException {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.accountNotRegistered,
        (route) => false,
        arguments: _phoneText,
      );
    } catch (_) {
      if (!mounted) return;
      _showWrongCode('Verification failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onResendCode() async {
    if (_isLoading || _isResending || !_isWrongCode) return;

    final phone = _phone;
    final countryCode = _countryCode;
    if (phone == null ||
        phone.isEmpty ||
        countryCode == null ||
        countryCode.isEmpty) {
      _showSnackBar('Phone number is missing. Please go back and try again.');
      return;
    }

    setState(() => _isResending = true);

    try {
      final result = await context.read<AuthProvider>().resendOtp(
            phone: phone,
            countryCode: countryCode,
          );

      if (!mounted) return;

      if (result == null) {
        final error = context.read<AuthProvider>().error;
        _showSnackBar(error ?? 'Failed to resend OTP');
        return;
      }

      for (final controller in _controllers) {
        controller.clear();
      }
      setState(() {
        _isWrongCode = false;
        _errorHeading = 'Incorrect code — please try again';
      });
      _startResendTimer(expiresInSeconds: result.expiresInSeconds);
      _focusNodes[0].requestFocus();
      _showDebugDevCode(result.devCode);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Failed to resend OTP. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _showDebugDevCode(String? devCode) {
    if (!kDebugMode) return;
    if (devCode == null || devCode.trim().isEmpty) return;
    _showSnackBar('Dev OTP: ${devCode.trim()}');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 8),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _activeIndex;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: _background,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = 20.0;
              final availableWidth =
                  constraints.maxWidth - (horizontalPadding * 2);
              const spacing = 14.0;
              final boxWidth =
                  ((availableWidth - (spacing * (_otpLength - 1))) / _otpLength)
                      .clamp(60.0, 78.0);

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _isLoading
                                ? null
                                : () {
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
                            _isWrongCode ? 'Wrong code' : 'Verify number',
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
                        _isWrongCode
                            ? _errorHeading
                            : 'Enter the 4-digit code',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _isWrongCode ? _errorRed : _textDark,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Sent by SMS to $_phoneText',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: _subtitleColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(_otpLength, (index) {
                          return _OtpBox(
                            width: boxWidth,
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            isActive: index == activeIndex,
                            enabled: !_isLoading && !_isResending,
                            onChanged: (value) => _onOtpChanged(index, value),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _isWrongCode
                          ? Row(
                              children: [
                                const Text(
                                  "Didn't get it? ",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _subtitleColor,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _isResending ? null : _onResendCode,
                                  child: Text(
                                    _isResending ? 'Sending...' : 'Resend code',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _isResending
                                          ? _buttonGreen.withValues(alpha: 0.6)
                                          : _buttonGreen,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                const Text(
                                  'Resend code in ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _subtitleColor,
                                  ),
                                ),
                                Text(
                                  _timerText,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: _textDark,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: (_isLoading || _isResending) ? null : _onVerify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _buttonGreen,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                _buttonGreen.withValues(alpha: 0.7),
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
                              : const Text(
                                  'Verify & continue',
                                  style: TextStyle(
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
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.width,
    required this.controller,
    required this.focusNode,
    required this.isActive,
    required this.onChanged,
    this.enabled = true,
  });

  final double width;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isActive;
  final bool enabled;
  final ValueChanged<String> onChanged;

  static const Color _textDark = Color(0xFF1E1E1E);
  static const Color _borderColor = Color(0xFFD0DCD0);
  static const Color _activeGreen = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 62,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? _activeGreen : _borderColor,
            width: isActive ? 2.5 : 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        alignment: Alignment.center,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          maxLength: 1,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _textDark,
            height: 1,
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            isDense: true,
            isCollapsed: true,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

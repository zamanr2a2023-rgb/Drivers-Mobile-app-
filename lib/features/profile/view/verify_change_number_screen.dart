import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/features/auth/provider/auth_provider.dart';
import 'package:yjeek_driver/features/profile/service/profile_service.dart';
import 'package:yjeek_driver/features/profile/view/doc_upload_ui.dart';
import 'package:yjeek_driver/services/api_service.dart';

class VerifyChangeNumberArgs {
  const VerifyChangeNumberArgs({
    required this.phone,
    required this.countryCode,
    required this.phoneDisplay,
    this.expiresInSeconds = 300,
  });

  final String phone;
  final String countryCode;
  final String phoneDisplay;
  final int expiresInSeconds;
}

/// Verify number — opened after "Send code" on Change number.
class VerifyChangeNumberScreen extends StatefulWidget {
  const VerifyChangeNumberScreen({super.key, required this.args});

  final VerifyChangeNumberArgs args;

  @override
  State<VerifyChangeNumberScreen> createState() =>
      _VerifyChangeNumberScreenState();
}

class _VerifyChangeNumberScreenState extends State<VerifyChangeNumberScreen> {
  static const int _otpLength = 4;

  final ProfileService _profileService = ProfileService();

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  bool _isWrongCode = false;
  bool _isVerifying = false;
  bool _isResending = false;
  int _resendSeconds = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
    _startResendTimer(widget.args.expiresInSeconds);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  int get _activeIndex {
    for (var i = 0; i < _otpLength; i++) {
      if (_controllers[i].text.isEmpty) return i;
    }
    return _otpLength - 1;
  }

  void _startResendTimer([int? seconds]) {
    _resendTimer?.cancel();
    final initial = seconds ?? widget.args.expiresInSeconds;
    _resendSeconds = initial > 0 ? initial : 300;
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

    setState(() => _isWrongCode = false);
  }

  Future<void> _onVerify() async {
    final otp = _otpCode;
    if (otp.length < _otpLength) {
      setState(() => _isWrongCode = true);
      return;
    }
    if (_isVerifying) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isVerifying = true;
      _isWrongCode = false;
    });

    try {
      final result = await _profileService.verifyPhoneChange(
        phone: widget.args.phone,
        countryCode: widget.args.countryCode,
        code: otp,
      );
      if (!mounted) return;

      context.read<AuthProvider>().applyTokens(
            accessToken: result.accessToken,
            refreshToken: result.refreshToken,
          );

      showDocSnack(context, result.message);
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isWrongCode = true);
      showDocSnack(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isWrongCode = true);
      showDocSnack(context, 'Failed to verify phone number');
    } finally {
      if (!mounted) return;
      setState(() => _isVerifying = false);
    }
  }

  Future<void> _onResendCode() async {
    // Match login OTP screen: resend is available after a wrong code.
    if (_isVerifying || _isResending || !_isWrongCode) return;

    final phone = widget.args.phone.trim();
    final countryCode = widget.args.countryCode.trim();
    if (phone.isEmpty || countryCode.isEmpty) {
      showDocSnack(context, 'Phone number is missing. Please go back and try again.');
      return;
    }

    setState(() => _isResending = true);

    try {
      final result = await _profileService.resendPhoneChangeOtp(
        phone: phone,
        countryCode: countryCode,
      );
      if (!mounted) return;

      for (final c in _controllers) {
        c.clear();
      }
      setState(() => _isWrongCode = false);
      _startResendTimer(result.expiresInSeconds);
      _focusNodes[0].requestFocus();

      if (kDebugMode) {
        final devCode = result.devCode?.trim();
        if (devCode != null && devCode.isNotEmpty) {
          showDocSnack(context, 'Dev OTP: $devCode');
        } else {
          showDocSnack(context, result.message);
        }
      } else {
        showDocSnack(context, result.message);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      showDocSnack(context, e.message);
    } catch (_) {
      if (!mounted) return;
      showDocSnack(context, 'Failed to resend OTP. Please try again.');
    } finally {
      if (!mounted) return;
      setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _activeIndex;
    final busy = _isVerifying || _isResending;

    return Scaffold(
      backgroundColor: DocColors.accountBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const horizontalPadding = 20.0;
            const spacing = 14.0;
            final availableWidth =
                constraints.maxWidth - (horizontalPadding * 2);
            final boxWidth =
                ((availableWidth - (spacing * (_otpLength - 1))) / _otpLength)
                    .clamp(60.0, 78.0);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DocHeader(
                    title: _isWrongCode ? 'Wrong code' : 'Verify number',
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isWrongCode
                        ? 'Incorrect code — please try again'
                        : 'Enter the 4-digit code',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _isWrongCode
                          ? const Color(0xFFD71920)
                          : DocColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sent by SMS to ${widget.args.phoneDisplay}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7C6B),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_otpLength, (index) {
                      return _OtpBox(
                        width: boxWidth,
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        isActive: index == activeIndex,
                        enabled: !busy,
                        onChanged: (value) => _onOtpChanged(index, value),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  if (_isWrongCode)
                    Row(
                      children: [
                        const Text(
                          "Didn't get it? ",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7C6B),
                          ),
                        ),
                        GestureDetector(
                          onTap: busy ? null : _onResendCode,
                          child: Text(
                            _isResending ? 'Sending…' : 'Resend code',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _isResending
                                  ? DocColors.pillGreen.withValues(alpha: 0.6)
                                  : DocColors.pillGreen,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        const Text(
                          'Resend code in ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7C6B),
                          ),
                        ),
                        Text(
                          _timerText,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: DocColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 22),
                  if (_isVerifying)
                    const SizedBox(
                      height: 52,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: DocColors.pillGreen,
                        ),
                      ),
                    )
                  else
                    DocPrimaryButton(
                      label: 'Verify & continue',
                      color: DocColors.pillGreen,
                      radius: 28,
                      height: 52,
                      onPressed: busy ? null : _onVerify,
                    ),
                ],
              ),
            );
          },
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 62,
      child: Container(
        decoration: BoxDecoration(
          color: DocColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? DocColors.pillGreen : DocColors.accountBorder,
            width: isActive ? 2.5 : 1.5,
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
            color: DocColors.textPrimary,
            height: 1,
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            filled: false,
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

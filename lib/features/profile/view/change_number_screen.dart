import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yjeek_driver/features/profile/service/profile_service.dart';
import 'package:yjeek_driver/features/profile/view/doc_upload_ui.dart';
import 'package:yjeek_driver/features/profile/view/verify_change_number_screen.dart';
import 'package:yjeek_driver/routes/route_names.dart';
import 'package:yjeek_driver/services/api_service.dart';

/// DA2 · Change number
class ChangeNumberScreen extends StatefulWidget {
  const ChangeNumberScreen({super.key});

  @override
  State<ChangeNumberScreen> createState() => _ChangeNumberScreenState();
}

class _ChangeNumberScreenState extends State<ChangeNumberScreen> {
  static const String _countryCode = '+973';

  final ProfileService _profileService = ProfileService();
  final _numberController = TextEditingController();
 //demo number 33000000
  bool _isSending = false;
  String _currentPhoneDisplay = '+973 3300 0000';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentPhone();
    });
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  String get _phoneDigits =>
      _numberController.text.replaceAll(RegExp(r'\D'), '');

  String get _formattedPhone {
    final digits = _phoneDigits;
    if (digits.isEmpty) return '$_countryCode ';
    if (digits.length <= 4) return '$_countryCode $digits';
    return '$_countryCode ${digits.substring(0, 4)} ${digits.substring(4)}';
  }

  String _formatPhone(String countryCode, String phone) {
    final code = countryCode.trim().isEmpty ? _countryCode : countryCode.trim();
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return code;
    if (digits.length <= 4) return '$code $digits';
    return '$code ${digits.substring(0, 4)} ${digits.substring(4)}';
  }

  Future<void> _loadCurrentPhone() async {
    try {
      final personal = await _profileService.getPersonalAccount();
      if (!mounted) return;
      final phone = personal.phone.trim();
      if (phone.isEmpty) return;
      setState(() {
        _currentPhoneDisplay = _formatPhone(personal.countryCode, phone);
      });
    } catch (_) {
      // Keep fallback current number.
    }
  }

  Future<void> _sendCode() async {
    final digits = _phoneDigits;
    if (digits.length < 8) {
      showDocSnack(context, 'Please enter a valid phone number');
      return;
    }
    if (_isSending) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSending = true);

    try {
      final result = await _profileService.sendPhoneChangeOtp(
        phone: digits,
        countryCode: _countryCode,
      );
      if (!mounted) return;

      if (kDebugMode) {
        final devCode = result.devCode?.trim();
        if (devCode != null && devCode.isNotEmpty) {
          showDocSnack(context, 'Dev OTP: $devCode');
        }
      }

      final verified = await Navigator.pushNamed(
        context,
        RouteNames.verifyChangeNumber,
        arguments: VerifyChangeNumberArgs(
          phone: digits,
          countryCode: _countryCode,
          phoneDisplay: _formattedPhone,
          expiresInSeconds: result.expiresInSeconds,
        ),
      );

      if (!mounted) return;
      if (verified == true) {
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      showDocSnack(context, e.message);
    } catch (_) {
      if (!mounted) return;
      showDocSnack(context, 'Failed to send OTP');
    } finally {
      if (!mounted) return;
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DocColors.accountBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DocHeader(title: 'Change number'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentNumberCard(),
                    const SizedBox(height: 14),
                    const Text(
                      'New number',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: DocColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildNewNumberField(),
                    const SizedBox(height: 14),
                    _buildInfoBanner(),
                    const SizedBox(height: 22),
                    if (_isSending)
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
                        label: 'Send code',
                        color: DocColors.pillGreen,
                        radius: 28,
                        height: 52,
                        onPressed: _sendCode,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentNumberCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: DocColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DocColors.accountBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current number',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B756E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _currentPhoneDisplay,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DocColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewNumberField() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: DocColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DocColors.accountBorder, width: 1.2),
      ),
      child: Row(
        children: [
          const Text('🇧🇭', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          const Text(
            '+973',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DocColors.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 1, height: 24, color: DocColors.accountBorder),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _numberController,
              enabled: !_isSending,
              keyboardType: TextInputType.phone,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: DocColors.textPrimary,
              ),
              cursorColor: DocColors.pillGreen,
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: '3XXX XXXX',
                hintStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                  color: Color(0xFF99A199),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DocColors.bannerGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'i',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'We\u2019ll send a 4-digit verification code to the new number.',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 15 / 12.5,
                color: DocColors.bannerGreenText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

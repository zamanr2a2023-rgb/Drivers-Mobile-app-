import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yjeek_driver/core/constants/app_assets.dart';
import 'package:yjeek_driver/services/api_service.dart';
import 'package:yjeek_driver/features/auth/provider/auth_provider.dart';
import 'package:yjeek_driver/features/dashboard/provider/dashboard_provider.dart';
import 'package:yjeek_driver/features/profile/service/profile_service.dart';
import 'package:yjeek_driver/features/profile/view/doc_upload_ui.dart';
import 'package:yjeek_driver/features/settings/provider/settings_provider.dart';
import 'package:yjeek_driver/l10n/l10n.dart';
import 'package:yjeek_driver/navigation/tab_refresh_signal.dart';
import 'package:yjeek_driver/routes/route_names.dart';

/// DE4 · Account
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();

  bool _autoAccept = false;

  bool _isLoadingAccount = false;
  bool _isLoggingOut = false;
  bool _isDeletingAccount = false;

  String _firstName = 'Ahmed';
  String _lastName = 'Khalid';
  double _averageRating = 4.9;
  int _totalOrders = 240;
  int _rpiScore = 88;
  String _accountStatus = 'ACTIVE';

  String _displayCode = 'YJK-DRV-0142';
  String _countryCode = '+973';
  String _phone = '3300 0000';
  String? _avatarUrl;
  Uint8List? _avatarBytes;
  String? _avatarBytesUrl;

  String _language = 'en';
  bool _documentsVerifiedBadge = true;

  String get _initials {
    final a = _firstName.trim();
    final b = _lastName.trim();
    final first = a.isNotEmpty ? a[0].toUpperCase() : '';
    final second = b.isNotEmpty ? b[0].toUpperCase() : '';
    return (first + second).isNotEmpty ? (first + second) : 'MA';
  }

  String get _accountStatusLabel {
    final s = _accountStatus.trim();
    if (s.isEmpty) return L10n.tr('Active');
    final lower = s.toLowerCase();
    final label = '${lower[0].toUpperCase()}${lower.substring(1)}';
    return L10n.tr(label);
  }

  @override
  void initState() {
    super.initState();
    TabRefreshSignal.ticks[TabRefreshSignal.account].addListener(_onTabRefresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAccount();
    });
  }

  @override
  void dispose() {
    TabRefreshSignal.ticks[TabRefreshSignal.account]
        .removeListener(_onTabRefresh);
    super.dispose();
  }

  void _onTabRefresh() {
    if (mounted) _loadAccount();
  }

  Future<void> _loadAccount() async {
    if (_isLoadingAccount) return;
    setState(() => _isLoadingAccount = true);

    try {
      final profile = await _profileService.getDriverProfile();
      if (!mounted) return;

        final nextAvatarUrl = profile.avatarUrl?.trim();
        final avatarChanged = nextAvatarUrl != _avatarUrl;
        setState(() {
          _firstName = profile.firstName.isNotEmpty
              ? profile.firstName
              : _firstName;
          _lastName =
              profile.lastName.isNotEmpty ? profile.lastName : _lastName;
          _averageRating = profile.averageRating;
          _totalOrders = profile.lifetimeDeliveries;
          _rpiScore = profile.rpiScore.round();
          _accountStatus = profile.accountStatus.isNotEmpty
              ? profile.accountStatus
              : _accountStatus;

          _displayCode = profile.displayCode.isNotEmpty
              ? profile.displayCode
              : _displayCode;
          _countryCode = profile.countryCode;
          final phone = profile.phone?.trim();
          if (phone != null && phone.isNotEmpty) {
            _phone = phone;
          }
          _avatarUrl = (nextAvatarUrl != null && nextAvatarUrl.isNotEmpty)
              ? nextAvatarUrl
              : null;
          if (avatarChanged) {
            _avatarBytes = null;
            _avatarBytesUrl = null;
          }

          _autoAccept = profile.isAutoAcceptEnabled;
          _language =
              profile.language.isNotEmpty ? profile.language : _language;
          _documentsVerifiedBadge = profile.isIdVerified;
        });

        await _loadAvatarBytes(_avatarUrl);
    } on ApiException {
      // Keep fallbacks on failure.
    } catch (_) {
      // Keep fallbacks on failure.
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingAccount = false);
    }
  }

  Future<void> _loadAvatarBytes(String? url) async {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      if (!mounted) return;
      setState(() {
        _avatarBytes = null;
        _avatarBytesUrl = null;
      });
      return;
    }

    if (trimmed == _avatarBytesUrl && _avatarBytes != null) return;

    try {
      final uri = Uri.parse(trimmed);
      final client = HttpClient();
      try {
        final request = await client.getUrl(uri).timeout(
          const Duration(seconds: 20),
        );
        final response = await request.close().timeout(
          const Duration(seconds: 20),
        );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw HttpException('Avatar download failed');
        }
        final bytes = await consolidateHttpClientResponseBytes(response);
        if (!mounted) return;
        setState(() {
          _avatarBytes = bytes;
          _avatarBytesUrl = trimmed;
        });
      } finally {
        client.close(force: true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _avatarBytes = null;
        _avatarBytesUrl = null;
      });
    }
  }

  Future<void> _openAndRefresh(String routeName) async {
    await Navigator.pushNamed(context, routeName);
    if (!mounted) return;
    await _loadAccount();
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    context.read<DashboardProvider>().resetOnLogout();
    if (!mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.login,
      (route) => false,
    );
  }

  Future<void> _deleteAccount() async {
    if (_isDeletingAccount || _isLoggingOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L10n.tr('Delete account?')),
        content: Text(
          L10n.tr(
            'This permanently deletes your account. Active deliveries must be finished first.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(L10n.tr('Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC0392B),
            ),
            child: Text(L10n.tr('Delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeletingAccount = true);
    try {
      context.read<DashboardProvider>().resetOnLogout();
      if (!mounted) return;
      await context.read<AuthProvider>().deleteAccount();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.login,
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isDeletingAccount = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFB42318),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDeletingAccount = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.tr('Could not delete account')),
          backgroundColor: const Color(0xFFB42318),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();
    return Scaffold(
      backgroundColor: DocColors.screenBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Text(
                L10n.tr('Account'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: DocColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF4CAF50),
                onRefresh: _loadAccount,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  child: Column(
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 12),
                    _buildInfoCard(),
                    const SizedBox(height: 12),
                    _buildAutoAcceptRow(),
                    const SizedBox(height: 12),
                    _buildSettingsCard(),
                    const SizedBox(height: 12),
                    _buildLogoutButton(),
                    const SizedBox(height: 12),
                    _buildDeleteAccountLink(),
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

  Widget _buildAvatarFallback() {
    return Text(
      _initials,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: DocColors.greenDark,
      ),
    );
  }

  Widget _buildAvatar() {
    final bytes = _avatarBytes;
    final url = _avatarUrl?.trim();
    final hasBytes = bytes != null && bytes.isNotEmpty;
    final hasUrl = url != null && url.isNotEmpty;

    return ClipOval(
      child: Container(
        width: 56,
        height: 56,
        color: DocColors.doneBg,
        alignment: Alignment.center,
        child: hasBytes
            ? Image.memory(
                bytes,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => _buildAvatarFallback(),
              )
            : hasUrl
                ? Image.network(
                    url,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    cacheWidth: 112,
                    cacheHeight: 112,
                    errorBuilder: (_, __, ___) => _buildAvatarFallback(),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return _buildAvatarFallback();
                    },
                  )
                : _buildAvatarFallback(),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DocColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DocColors.cardBorder),
      ),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_firstName $_lastName'.trim(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: DocColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 15, color: DocColors.gold),
                    SizedBox(width: 2),
                    Text(
                      _averageRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: DocColors.gold,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      L10n.trParams('{count} Orders', {'count': '$_totalOrders'}),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: DocColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: DocColors.doneBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'RPI $_rpiScore · $_accountStatusLabel',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: DocColors.greenDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: DocColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DocColors.cardBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  L10n.tr('Champ ID'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: DocColors.textSecondary,
                  ),
                ),
                Text(
                  _displayCode,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: DocColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE8EBE8)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Text(
                  L10n.tr('Contact number'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: DocColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '$_countryCode $_phone',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: DocColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: DocColors.doneBg,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openAndRefresh(RouteNames.changeNumber),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Text(
                        L10n.tr('Change'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: DocColors.greenDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoAcceptRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            size: 20,
            color: DocColors.greenDark,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              L10n.tr('Auto-Accept orders'),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: DocColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _autoAccept = !_autoAccept),
            child: Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _autoAccept
                    ? DocColors.green
                    : const Color(0xFFCCD1CC),
                shape: BoxShape.circle,
              ),
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: DocColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DocColors.cardBorder),
      ),
      child: Column(
        children: [
          _SettingsRow(
            iconAsset: AppAssets.accountDocuments,
            label: L10n.tr('Documents'),
            badge: _documentsVerifiedBadge
                ? L10n.tr('Verified')
                : L10n.tr('Verify'),
            onTap: () => _openAndRefresh(RouteNames.documents),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: Color(0xFFE8EBE8),
          ),
          _SettingsRow(
            icon: Icons.notifications_none_rounded,
            label: L10n.tr('Notifications'),
            onTap: () => _openAndRefresh(RouteNames.notifications),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: Color(0xFFE8EBE8),
          ),
          _SettingsRow(
            icon: Icons.language_rounded,
            label: L10n.tr('Language'),
            badge: context.watch<SettingsProvider>().languageCode.toUpperCase(),
            onTap: () => _openAndRefresh(RouteNames.language),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Material(
      color: const Color(0xFFFBEAEC),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: (_isLoggingOut || _isDeletingAccount) ? null : _logout,
        child: Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFF2D4D7)),
          ),
          child: Row(
            children: [
              Image.asset(AppAssets.accountLogout, width: 18, height: 18),
              const SizedBox(width: 8),
              Text(
                L10n.tr('Log out'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC0392B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountLink() {
    final busy = _isDeletingAccount || _isLoggingOut;
    return GestureDetector(
      onTap: busy ? null : _deleteAccount,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          _isDeletingAccount
              ? L10n.tr('Deleting...')
              : L10n.tr('Delete account'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.onTap,
    this.icon,
    this.iconAsset,
    this.badge,
  });

  final IconData? icon;
  final String? iconAsset;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (iconAsset != null)
                Image.asset(iconAsset!, width: 19, height: 19)
              else
                Icon(icon, size: 19, color: DocColors.greenDark),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: DocColors.textPrimary,
                  ),
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: DocColors.doneBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: DocColors.greenDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: DocColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

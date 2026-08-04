import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yjeek_driver/features/profile/service/profile_service.dart';
import 'package:yjeek_driver/features/profile/view/doc_upload_ui.dart';
import 'package:yjeek_driver/services/api_service.dart';

/// DU5 · Upload — Profile photo
class UploadProfilePhotoScreen extends StatefulWidget {
  const UploadProfilePhotoScreen({super.key});

  @override
  State<UploadProfilePhotoScreen> createState() =>
      _UploadProfilePhotoScreenState();
}

class _UploadProfilePhotoScreenState extends State<UploadProfilePhotoScreen> {
  final ProfileService _profileService = ProfileService();
  final ImagePicker _imagePicker = ImagePicker();

  Uint8List? _photoBytes;
  String? _avatarUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentAvatar();
    });
  }

  Future<void> _loadCurrentAvatar() async {
    try {
      final personal = await _profileService.getPersonalAccount();
      if (!mounted) return;
      final url = personal.avatarUrl?.trim();
      if (url != null && url.isNotEmpty && _photoBytes == null) {
        setState(() => _avatarUrl = url);
      }
    } catch (_) {
      // Keep placeholder if load fails.
    }
  }

  Future<ImageSource?> _chooseSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: DocColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isPermissionError(PlatformException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();
    return code.contains('photo') ||
        code.contains('camera') ||
        code.contains('permission') ||
        message.contains('permission') ||
        message.contains('access') ||
        message.contains('denied') ||
        message.contains('not authorized');
  }

  Future<void> _pick() async {
    final source = await _chooseSource();
    if (source == null || !mounted) return;

    try {
      // Let image_picker trigger the native iOS/Android permission dialog.
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photoBytes = bytes;
        _avatarUrl = null;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      if (_isPermissionError(e)) {
        showDocSnack(
          context,
          source == ImageSource.camera
              ? 'Camera permission is required. Enable Camera in Settings > Yjeek Driver.'
              : 'Photo permission is required. Enable Photos in Settings > Yjeek Driver.',
        );
        return;
      }
      final message = (e.message ?? '').trim();
      showDocSnack(
        context,
        message.isNotEmpty
            ? message
            : source == ImageSource.camera
                ? 'Unable to open camera. Please try again.'
                : 'Unable to access photos. Please try again.',
      );
    } catch (_) {
      if (!mounted) return;
      showDocSnack(
        context,
        source == ImageSource.camera
            ? 'Unable to open camera. Please try again.'
            : 'Unable to access photos. Please try again.',
      );
    }
  }

  Future<void> _save() async {
    final bytes = _photoBytes;
    if (bytes == null) {
      showDocSnack(context, 'Please select a profile photo');
      return;
    }
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final avatarUrl = await _profileService.updateAvatar(bytes: bytes);
      if (!mounted) return;

      setState(() => _avatarUrl = avatarUrl);
      showDocSnack(context, 'Profile photo saved');
      Navigator.maybePop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      showDocSnack(context, e.message);
    } catch (_) {
      if (!mounted) return;
      showDocSnack(context, 'Failed to update avatar');
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  Widget _buildAvatarPreview() {
    if (_photoBytes != null) {
      return Image.memory(
        _photoBytes!,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      );
    }

    final url = _avatarUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Text(
          '🙂',
          style: TextStyle(fontSize: 40),
        ),
      );
    }

    return const Text(
      '🙂',
      style: TextStyle(fontSize: 40),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DocColors.screenBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DocHeader(title: 'Profile photo'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'A clear photo of your face — no sunglasses or hats.',
                      style: TextStyle(
                        fontSize: 13,
                        color: DocColors.textMuted,
                        height: 16 / 13,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Center(
                      child: GestureDetector(
                        onTap: _isSaving ? null : _pick,
                        child: Column(
                          children: [
                            Container(
                              width: 150,
                              height: 150,
                              alignment: Alignment.center,
                              clipBehavior: Clip.antiAlias,
                              decoration: const BoxDecoration(
                                color: DocColors.doneBg,
                                shape: BoxShape.circle,
                              ),
                              child: _buildAvatarPreview(),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap to replace',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: DocColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    if (_isSaving)
                      const SizedBox(
                        height: 50,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: DocColors.green,
                          ),
                        ),
                      )
                    else
                      DocPrimaryButton(
                        label: 'Save',
                        onPressed: _save,
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
}

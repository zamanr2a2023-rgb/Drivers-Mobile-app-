import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class IncidentColors {
  IncidentColors._();

  static const Color screenBg = Color(0xFFF5F7F5);
  static const Color headerGreen = Color(0xFF2E7D33);
  static const Color textPrimary = Color(0xFF1A1F1A);
  static const Color textMuted = Color(0xFF737873);
  static const Color textSubtitle = Color(0xFFDBEDDB);
  static const Color textSubtitleAlt = Color(0xFFEBEBEB);
  static const Color cardBorder = Color(0xFFE6E8E6);
  static const Color white = Color(0xFFFFFFFF);
  static const Color danger = Color(0xFFC9121F);
  static const Color timerOrange = Color(0xFFC74D00);
  static const Color successGreen = Color(0xFF4DB04F);
  static const Color uploadBg = Color(0xFFF7F7F7);
  static const Color uploadBorder = Color(0xFFBFC4BF);
  static const Color infoBg = Color(0xFFF2F4F2);
  static const Color infoText = Color(0xFF55605A);
  static const Color chipUnselected = Color(0xFFCFD4CF);
}

class IncidentContextArgs {
  const IncidentContextArgs({
    this.orderId = '#YJK-…41',
    this.vendorName = 'The Green Kitchen',
    this.customerName = 'Sara A.',
    this.area = 'Adliya',
    this.address = 'Adliya · Bldg 23, Road 2825, Flat 82',
    this.pin = 'Pin: 26.22051, 50.58472',
  });

  final String orderId;
  final String vendorName;
  final String customerName;
  final String area;
  final String address;
  final String pin;

  String get pickupSubtitle => '$vendorName · $orderId';
  String get dropoffSubtitle => '$customerName · $area · $orderId';
  String get customerOrderSubtitle => '$customerName · $orderId';
}

class IncidentHeader extends StatelessWidget {
  const IncidentHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: IncidentColors.headerGreen,
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack ?? () => Navigator.maybePop(context),
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Text(
                subtitle!,
                style: const TextStyle(
                  color: IncidentColors.textSubtitleAlt,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class IncidentCard extends StatelessWidget {
  const IncidentCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: IncidentColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IncidentColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class IncidentPrimaryButton extends StatelessWidget {
  const IncidentPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = IncidentColors.danger,
    this.textColor = Colors.white,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Material(
        color: enabled ? color : color.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class IncidentOutlinedButton extends StatelessWidget {
  const IncidentOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.textColor = IncidentColors.textPrimary,
    this.borderColor = IncidentColors.cardBorder,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color textColor;
  final Color borderColor;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Material(
        color: IncidentColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borderColor, width: 1.5),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class IncidentChip extends StatelessWidget {
  const IncidentChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor = IncidentColors.headerGreen,
    this.filledSelected = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  /// When true, selected chips use a solid fill + white text (design style).
  final bool filledSelected;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color text;

    if (selected && filledSelected) {
      bg = selectedColor;
      border = selectedColor;
      text = Colors.white;
    } else if (selected) {
      bg = selectedColor.withValues(alpha: 0.12);
      border = selectedColor;
      text = selectedColor;
    } else {
      bg = IncidentColors.white;
      border = const Color(0xFFD9DDD9);
      text = const Color(0xFF4A504A);
    }

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: border, width: 1.2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
        ),
      ),
    );
  }
}

class IncidentPhotoUpload extends StatelessWidget {
  const IncidentPhotoUpload({
    super.key,
    required this.hasPhoto,
    required this.onTap,
    this.photoBytes,
    this.helperText = 'Clear photo of the damage / leak',
    this.requiredLabel = true,
  });

  final bool hasPhoto;
  final Uint8List? photoBytes;
  final VoidCallback onTap;
  final String helperText;
  final bool requiredLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: IncidentColors.uploadBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(
          painter: const _DashedBorderPainter(
            color: IncidentColors.uploadBorder,
            radius: 16,
          ),
          child: Container(
            width: double.infinity,
            height: 140,
            alignment: Alignment.center,
            child: hasPhoto && photoBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      photoBytes!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 140,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📷', style: TextStyle(fontSize: 28)),
                      const SizedBox(height: 8),
                      Text(
                        requiredLabel ? 'Add photo · required' : '＋ Add a photo',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: IncidentColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        helperText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: IncidentColors.textMuted,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );

    const dashWidth = 6.0;
    const dashGap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

Future<Uint8List?> pickIncidentPhoto(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: IncidentColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
          ],
        ),
      );
    },
  );

  if (source == null) return null;

  try {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null) return null;
    return picked.readAsBytes();
  } on PlatformException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to access photos. Please try again.')),
      );
    }
    return null;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo selection failed. Please try again.')),
      );
    }
    return null;
  }
}

class IncidentMenuRow extends StatelessWidget {
  const IncidentMenuRow({
    super.key,
    required this.title,
    required this.onTap,
    this.emoji,
    this.iconAsset,
    this.subtitle,
    this.iconBg,
  }) : assert(emoji != null || iconAsset != null);

  final String? emoji;
  final String? iconAsset;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconBg;

  @override
  Widget build(BuildContext context) {
    final Widget iconChild = iconAsset != null
        ? Image.asset(
            iconAsset!,
            width: 28,
            height: 28,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          )
        : Text(emoji!, style: const TextStyle(fontSize: 22));

    return Material(
      color: IncidentColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: IncidentColors.cardBorder),
          ),
          child: Row(
            children: [
              if (iconBg != null)
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: iconChild,
                )
              else
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Center(child: iconChild),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: IncidentColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: IncidentColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: IncidentColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

void showIncidentSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

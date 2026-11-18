import 'package:flutter/material.dart';

import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/phosphor_icons.dart';
import '../../widgets/ledger_parts.dart';
import 'field_service.dart';
import '../../l10n/tr.dart';

/// The photo shown for a field, by what is kept or grown there.
String fieldPhoto(String type) => switch (type) {
      'layers' || 'broilers' => 'images/auth/chicken.jpg',
      'dairy_cattle' || 'dairy_goats' => 'images/auth/milk.png',
      'beef_cattle' || 'sheep' || 'pigs' || 'rabbits' => 'images/auth/cow.jpg',
      'maize' || 'wheat' || 'rice' => 'images/auth/field.png',
      'beans' => 'images/auth/beans.jpg',
      'bananas' || 'avocados' => 'images/auth/banana.png',
      'tomatoes' || 'kales' || 'spinach' => 'images/auth/farm.png',
      _ => 'images/auth/plain.jpg',
    };

/// The illustrated icon for what a field keeps or grows (images/assets/icons).
String fieldIcon(String type, {bool crop = false}) => 'images/assets/icons/${switch (type) {
      'layers' || 'broilers' => 'chicken',
      'fish' => 'fish',
      'dairy_cattle' || 'beef_cattle' => 'cow',
      'dairy_goats' || 'sheep' => 'goat',
      'pigs' => 'pig',
      'rabbits' => 'rabbit',
      'maize' => 'corn',
      'beans' => 'beans',
      'rice' => 'rice',
      'wheat' => 'wheat',
      'tomatoes' => 'tomato',
      'kales' => 'kale',
      'spinach' => 'spinach',
      'bananas' => 'banana',
      'avocados' => 'avocado',
      _ => crop ? 'leaf' : 'livestock',
    }}.png';

/// A field's icon on a soft green tile.
class FieldIconTile extends StatelessWidget {
  final Field field;
  final double width;
  final double height;
  final double radius;
  final double iconSize;

  const FieldIconTile({super.key, required this.field, required this.width, required this.height, this.radius = 16, required this.iconSize});

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: context.appColors.brandSoft, borderRadius: BorderRadius.circular(radius)),
      alignment: Alignment.center,
      child: Image.asset(
        fieldIcon(field.type, crop: field.isCrop),
        width: iconSize,
        height: iconSize,
        cacheWidth: (iconSize * dpr).round(),
        excludeFromSemantics: true,
      ),
    );
  }
}

/// A field photo decoded at the size it is shown (some sources are 7000px tall).
class FieldPhoto extends StatelessWidget {
  final String type;
  final double? width;
  final double? height;
  final BorderRadius? radius;

  const FieldPhoto({super.key, required this.type, this.width, this.height, this.radius});

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final screen = MediaQuery.sizeOf(context).width;
    final image = Image.asset(
      fieldPhoto(type),
      width: width,
      height: height,
      fit: BoxFit.cover,
      cacheWidth: ((width ?? screen) * dpr).round(),
      errorBuilder: (_, _, _) => Container(width: width, height: height, color: context.appColors.surfaceMuted),
    );
    return radius == null ? image : ClipRRect(borderRadius: radius!, child: image);
  }
}

/// A small pill on a field card: its state, size or kind.
class FieldChip extends StatelessWidget {
  final String text;
  final Color? fg;
  final Color? bg;

  const FieldChip(this.text, {super.key, this.fg, this.bg});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg ?? c.surfaceMuted, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: AppType.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: fg ?? c.textPrimary)),
    );
  }
}

/// The chips every field card shows: whether it is active, its size, its kind.
List<Widget> fieldChips(BuildContext context, Field f) {
  final c = context.appColors;
  return [
    f.isActive
        ? FieldChip('Active'.tr, fg: c.goodInk, bg: c.goodTint)
        : FieldChip('Closed'.tr, fg: c.textSecondary),
    if (f.size.isNotEmpty) FieldChip(f.size, fg: c.rainInk, bg: c.rainTint),
    FieldChip(fieldKind(f.type)),
  ];
}

String fieldKind(String type) => switch (type) {
      'dairy_cattle' => 'Dairy'.tr,
      'beef_cattle' => 'Beef'.tr,
      'dairy_goats' => 'Goats'.tr,
      'layers' => 'Layers'.tr,
      'broilers' => 'Broilers'.tr,
      _ => type.isEmpty ? '' : type[0].toUpperCase() + type.substring(1).replaceAll('_', ' '),
    };

/// A field as a card: photo, name, chips and when it started.
class FieldCard extends StatelessWidget {
  final Field field;
  final VoidCallback? onTap;
  final bool compact; // no date line (the scan screen)

  const FieldCard({super.key, required this.field, this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    // The design's photo card (sl-ent--photo), with the field's icon for the
    // photo: the icon left, the name, its
    // state and size as tags, and when it started.
    return SlCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldIconTile(field: field, width: compact ? 88 : 104, height: compact ? 64 : 88, iconSize: compact ? 44 : 60),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(field.name,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: AppType.text, fontSize: 19, height: 24 / 19, fontWeight: FontWeight.w500, color: c.textPrimary)),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  field.isActive
                      ? SlTag('Active'.tr, tone: SlTone.good, icon: SlTag.check)
                      : SlTag('Closed'.tr),
                  if (field.size.isNotEmpty) SlTag(field.size),
                ]),
                if (!compact) ...[
                  const SizedBox(height: 6),
                  Text(field.startedLine, style: AppType.caption.copyWith(color: c.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A round back button that reads on top of a photo.
class PhotoBackButton extends StatelessWidget {
  const PhotoBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      button: true,
      label: 'Back'.tr,
      child: Material(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => Navigator.maybePop(context),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(PhosphorIconsRegular.arrowLeft, color: c.textPrimary, size: 22),
          ),
        ),
      ),
    );
  }
}

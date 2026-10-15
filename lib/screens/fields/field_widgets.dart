import 'package:flutter/material.dart';

import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/phosphor_icons.dart';
import 'field_service.dart';

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
        ? FieldChip('Active', fg: c.goodInk, bg: c.goodTint)
        : FieldChip('Closed', fg: c.textSecondary),
    if (f.size.isNotEmpty) FieldChip(f.size, fg: c.rainInk, bg: c.rainTint),
    FieldChip(fieldKind(f.type)),
  ];
}

String fieldKind(String type) => switch (type) {
      'dairy_cattle' => 'Dairy',
      'beef_cattle' => 'Beef',
      'dairy_goats' => 'Goats',
      'layers' => 'Layers',
      'broilers' => 'Broilers',
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
    return Material(
      color: c.cardBackground,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              FieldPhoto(
                type: field.type,
                width: compact ? 96 : 128,
                height: compact ? 64 : 84,
                radius: BorderRadius.circular(10),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(field.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.titleM.copyWith(color: c.textPrimary)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: fieldChips(context, field)),
                    if (!compact) ...[
                      const SizedBox(height: 8),
                      Text(field.startedLine, style: AppType.caption.copyWith(color: c.textSecondary)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
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
      label: 'Back',
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

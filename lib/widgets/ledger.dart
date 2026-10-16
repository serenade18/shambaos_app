import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'phosphor_icons.dart';

import '../services/app_colors.dart';
import '../services/app_type.dart';
import '../l10n/tr.dart';

/// Shamba Ledger components (see shamba-ledger/components/*/README.md).

// ═══════════════════════════════════════════════════════════
// STATUS TAG — a word, an icon and a tint
// ═══════════════════════════════════════════════════════════
enum SlStatus { good, warn, danger, info, neutral }

class SlStatusTag extends StatelessWidget {
  final String text;
  final SlStatus status;
  final IconData? icon;

  const SlStatusTag(this.text, {super.key, this.status = SlStatus.neutral, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final (Color fg, Color bg, IconData? fallback) = switch (status) {
      SlStatus.good => (c.goodInk, c.goodTint, PhosphorIconsBold.check),
      SlStatus.warn => (c.warnInk, c.warnTint, PhosphorIconsBold.clock),
      SlStatus.danger => (c.dangerInk, c.dangerTint, PhosphorIconsBold.minusCircle),
      SlStatus.info => (c.rainInk, c.rainTint, PhosphorIconsBold.cloudRain),
      SlStatus.neutral => (c.textSecondary, c.surfaceMuted, null),
    };
    final glyph = icon ?? fallback;
    return Container(
      height: 24,
      padding: EdgeInsets.only(left: glyph == null ? 10 : 8, right: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (glyph != null) ...[Icon(glyph, size: 14, color: fg), const SizedBox(width: 5)],
          Text(text, style: AppType.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// KEY FIGURE — the one number a screen is about
// ═══════════════════════════════════════════════════════════
class SlKeyFigure extends StatelessWidget {
  final String label; // written in capitals: "PROFIT · LAST 30 DAYS"
  final String value; // already formatted: "22,500"
  final String? currency; // "KSh"
  final String? unit; // "trays"
  final String? delta; // "KSh 4,200 more"
  final String? deltaRest; // "than the 30 days before"
  final bool? deltaUp; // true: more, false: less, null: no arrow
  final String? caption; // a quiet line under the figure: "From 3 of 5 customers"
  final bool band; // on a shamba fill

  const SlKeyFigure({
    super.key,
    required this.label,
    required this.value,
    this.currency,
    this.unit,
    this.delta,
    this.deltaRest,
    this.deltaUp,
    this.caption,
    this.band = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final ink = band ? c.onShamba : c.textPrimary;
    final muted = band ? c.onShamba : c.textSecondary;
    final deltaColor = band ? c.onShamba : (deltaUp == false ? c.dangerInk : c.goodInk);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppType.eyebrow.copyWith(color: muted)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currency != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 6),
                child: Text(currency!, style: AppType.label.copyWith(color: muted)),
              ),
            Flexible(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: value, style: AppType.figureXl.copyWith(color: ink)),
                  if (unit != null) TextSpan(text: '  $unit', style: AppType.bodyL.copyWith(color: muted)),
                ]),
              ),
            ),
          ],
        ),
        if (delta != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              if (deltaUp != null) ...[
                Icon(deltaUp! ? PhosphorIconsRegular.arrowUpRight : PhosphorIconsRegular.arrowDownRight,
                    size: 18, color: deltaColor),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: delta, style: AppType.body.copyWith(fontWeight: FontWeight.w700, color: deltaColor)),
                    if (deltaRest != null) TextSpan(text: ' $deltaRest', style: AppType.body.copyWith(color: muted)),
                  ]),
                ),
              ),
            ],
          ),
        ],
        if (caption != null) ...[
          const SizedBox(height: 4),
          Text(caption!, style: AppType.caption.copyWith(color: muted)),
        ],
      ],
    );

    if (!band) return content;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: c.shamba, borderRadius: BorderRadius.circular(24)),
      child: content,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// LEDGER — one sheet of ruled rows
// ═══════════════════════════════════════════════════════════
class SlLedger extends StatelessWidget {
  final String? title;
  final Widget? trailing; // an eyebrow period or a quiet "See all" button
  final List<Widget> children;

  const SlLedger({super.key, this.title, this.trailing, required this.children});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      width: double.infinity,
      // The design's ledger sheet: white, 24 radius, a soft shadow, no border.
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x1217211A), blurRadius: 24, offset: Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(title!,
                        style: TextStyle(fontFamily: AppType.text, fontSize: 19, height: 24 / 19, fontWeight: FontWeight.w500, color: c.textPrimary)),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}

/// An `eyebrow` for a ledger head: the period, or a count.
class SlEyebrow extends StatelessWidget {
  final String text;
  const SlEyebrow(this.text, {super.key});

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: AppType.eyebrow.copyWith(color: context.appColors.textSecondary));
}

class SlLedgerRow extends StatelessWidget {
  final String title;
  final String? meta;
  final String? figure;
  final String? unit;
  final Widget? status;
  final Widget? leading;
  final bool loss; // figure in danger-ink
  final bool total; // double rule above, bold
  final VoidCallback? onTap;

  const SlLedgerRow({
    super.key,
    required this.title,
    this.meta,
    this.figure,
    this.unit,
    this.status,
    this.leading,
    this.loss = false,
    this.total = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final row = Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppType.label.copyWith(color: c.textPrimary)),
                if (meta != null && meta!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(meta!, style: AppType.caption.copyWith(color: c.textSecondary)),
                ],
              ],
            ),
          ),
          if (figure != null || status != null) ...[
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (figure != null)
                  Text.rich(TextSpan(children: [
                    TextSpan(
                      text: figure,
                      style: AppType.figureS.copyWith(
                        color: loss ? c.dangerInk : c.textPrimary,
                        fontWeight: total ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    if (unit != null) TextSpan(text: ' $unit', style: AppType.caption.copyWith(color: c.textSecondary)),
                  ])),
                if (figure != null && status != null) const SizedBox(height: 4),
                if (status != null) status!,
              ],
            ),
          ],
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: total
              ? BorderSide(color: c.border, width: 3) // the bookkeeper's rule above a sum
              : BorderSide(color: c.divider),
        ),
      ),
      child: onTap == null ? row : InkWell(onTap: onTap, child: row),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ALERT ROW — something on the farm that needs the farmer
// ═══════════════════════════════════════════════════════════
class SlAlertRow extends StatelessWidget {
  final IconData icon;
  final SlStatus status; // warn, danger or info
  final String text;
  final Widget? tag;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SlAlertRow({
    super.key,
    required this.icon,
    required this.status,
    required this.text,
    this.tag,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final (Color fg, Color bg) = switch (status) {
      SlStatus.danger => (c.dangerInk, c.dangerTint),
      SlStatus.info => (c.rainInk, c.rainTint),
      SlStatus.good => (c.goodInk, c.goodTint),
      _ => (c.warnInk, c.warnTint),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.divider))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, size: 22, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: AppType.body.copyWith(color: c.textPrimary)),
                if (tag != null || actionLabel != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (tag != null) tag!,
                      const Spacer(),
                      if (actionLabel != null)
                        TextButton(
                          onPressed: onAction,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            textStyle: AppType.label.copyWith(fontSize: 14),
                          ),
                          child: Text(actionLabel!),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SEASON STRIP — the year by the rains, with today marked
// ═══════════════════════════════════════════════════════════
class SlSeason {
  final String eyebrow; // "VULI · SHORT RAINS"
  final String title; // "Week 3 of 13"
  final String advice;

  const SlSeason(this.eyebrow, this.title, this.advice);

  /// Rainy months for the central highlands: masika Mar–May, vuli Oct–Dec.
  static const rainMonths = {3, 4, 5, 10, 11, 12};

  static SlSeason of(DateTime today) {
    final m = today.month;
    String weekOf(DateTime start, DateTime end) {
      final week = today.difference(start).inDays ~/ 7 + 1;
      final weeks = (end.difference(start).inDays / 7).ceil();
      return 'Week {week} of {weeks}'.trArgs({'week': week, 'weeks': weeks});
    }

    final y = today.year;
    if (m >= 3 && m <= 5) {
      final start = DateTime(y, 3, 1);
      final week = today.difference(start).inDays ~/ 7 + 1;
      return SlSeason('MASIKA · LONG RAINS'.tr, weekOf(start, DateTime(y, 6, 1)),
          week <= 4 ? 'Planting window open'.tr : 'Weed and top-dress'.tr);
    }
    if (m >= 10) {
      final start = DateTime(y, 10, 1);
      final week = today.difference(start).inDays ~/ 7 + 1;
      return SlSeason('VULI · SHORT RAINS'.tr, weekOf(start, DateTime(y + 1, 1, 1)),
          week <= 4 ? 'Planting window open'.tr : 'Weed and top-dress'.tr);
    }
    if (m <= 2) {
      return SlSeason('KIANGAZI · HOT DRY SEASON'.tr, 'Long rains in {p0} days'.trArgs({'p0': DateTime(y, 3, 1).difference(today).inDays}),
          'Prepare land and buy seed'.tr);
    }
    return SlSeason('KIPUPWE · COOL DRY SEASON'.tr, 'Short rains in {p0} days'.trArgs({'p0': DateTime(y, 10, 1).difference(today).inDays}),
        'Harvest and store the long-rains crop'.tr);
  }
}

class SlSeasonStrip extends StatelessWidget {
  final DateTime? today;
  const SlSeasonStrip({super.key, this.today});

  static const _letters = 'JFMAMJJASOND';

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final now = today ?? DateTime.now();
    final season = SlSeason.of(now);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final position = (now.month - 1 + (now.day - 0.5) / daysInMonth) / 12;
    const gap = 3.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: c.cardBackground,
        border: Border.all(color: c.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 12,
            runSpacing: 4,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(season.eyebrow, style: AppType.eyebrow.copyWith(color: c.textSecondary)),
                  const SizedBox(height: 2),
                  Text(season.title, style: AppType.titleM.copyWith(color: c.textPrimary)),
                ],
              ),
              Text(season.advice, style: AppType.caption.copyWith(color: c.textSecondary)),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            label: 'Today, {date}'.trArgs({'date': DateFormat('d MMMM').format(now)}),
            child: LayoutBuilder(builder: (context, box) {
              final x = position * (box.maxWidth + gap);
              return SizedBox(
                height: 40,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 6,
                      height: 28,
                      child: Row(
                        children: [
                          for (var i = 1; i <= 12; i++) ...[
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: SlSeason.rainMonths.contains(i) ? c.seasonRain : c.surfaceMuted,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            if (i < 12) const SizedBox(width: gap),
                          ],
                        ],
                      ),
                    ),
                    Positioned(
                      left: x - 1.5,
                      top: 0,
                      bottom: 0,
                      width: 3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: c.maize, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          ExcludeSemantics(
            child: Row(
              children: [
                for (var i = 0; i < 12; i++) ...[
                  Expanded(
                    child: Text(
                      _letters[i],
                      textAlign: TextAlign.center,
                      style: AppType.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: i + 1 == now.month ? c.maizeInk : c.textHint,
                      ),
                    ),
                  ),
                  if (i < 11) const SizedBox(width: gap),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _key(c, c.seasonRain, 'Masika, Mar–May'.tr),
              _key(c, c.seasonRain, 'Vuli, Oct–Dec'.tr),
              _key(c, c.surfaceMuted, 'Dry'.tr, outlined: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _key(AppColors c, Color swatch, String label, {bool outlined = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: swatch,
            borderRadius: BorderRadius.circular(3),
            border: outlined ? Border.all(color: c.divider) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppType.caption.copyWith(color: c.textSecondary)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ENTERPRISE TILE — an animal group or crop, with its live figure
// ═══════════════════════════════════════════════════════════
class SlEnterpriseTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? meta;
  final String? figure;
  final String? unit;
  final Widget? status;
  final VoidCallback? onTap;

  const SlEnterpriseTile({
    super.key,
    required this.icon,
    required this.title,
    this.meta,
    this.figure,
    this.unit,
    this.status,
    this.onTap,
  });

  /// The line icon for a catalogue type code.
  static IconData iconFor(String? type) => switch (type) {
        'layers' => PhosphorIconsRegular.egg,
        'broilers' => PhosphorIconsRegular.bird,
        'dairy_cattle' || 'dairy_goats' => PhosphorIconsRegular.drop,
        'beef_cattle' || 'sheep' || 'pigs' || 'rabbits' => PhosphorIconsRegular.cow,
        'fish' => PhosphorIconsRegular.fish,
        'maize' || 'beans' || 'rice' || 'wheat' => PhosphorIconsRegular.grains,
        _ => PhosphorIconsRegular.plant,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Material(
      color: c.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: c.divider)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, size: 26, color: c.brandText),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppType.label.copyWith(color: c.textPrimary)),
                    if (meta != null) ...[
                      const SizedBox(height: 2),
                      Text(meta!, style: AppType.caption.copyWith(color: c.textSecondary)),
                    ],
                  ],
                ),
              ),
              if (figure != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(figure!, style: AppType.figureM.copyWith(color: c.textPrimary)),
                    if (unit != null) Text(unit!, style: AppType.caption.copyWith(color: c.textSecondary)),
                  ],
                )
              else if (status != null)
                status!,
            ],
          ),
        ),
      ),
    );
  }
}

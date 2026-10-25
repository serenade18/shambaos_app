import 'package:flutter/material.dart';

import '../services/app_colors.dart';
import '../l10n/tr.dart';

/// Placeholders drawn in the shape of what is loading: grey blocks in the
/// sheet-sunk colour that pulse softly. Screen readers hear "Loading" once,
/// not every block. With animations turned off on the phone, they hold still.
class Skeleton extends StatefulWidget {
  final Widget child;
  const Skeleton({super.key, required this.child});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  late final _opacity = Tween<double>(begin: 1, end: 0.45).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Loading…'.tr,
      liveRegion: true,
      child: ExcludeSemantics(
        child: still ? widget.child : FadeTransition(opacity: _opacity, child: widget.child),
      ),
    );
  }
}

/// One grey block. Text lines are 12 high; [width] null fills the line.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final bool circle;

  const SkeletonBox({super.key, this.width, this.height = 12, this.radius = 6, this.circle = false});

  @override
  Widget build(BuildContext context) => Container(
        width: circle ? height : width,
        height: height,
        decoration: BoxDecoration(
          color: context.appColors.surfaceMuted,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(radius),
        ),
      );
}

/// A ledger sheet of [rows] loading rows, as SlLedger + SlLedgerRow draw them:
/// an optional icon well, a title and a meta line, an optional figure.
class SkeletonLedger extends StatelessWidget {
  final int rows;
  final bool title;
  final bool leading;
  final bool figure;

  const SkeletonLedger({super.key, this.rows = 4, this.title = false, this.leading = true, this.figure = false});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Skeleton(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: c.cardBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Color(0x1217211A), blurRadius: 24, offset: Offset(0, 8))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (title)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Align(alignment: Alignment.centerLeft, child: SkeletonBox(width: 140, height: 16)),
            ),
          for (var i = 0; i < rows; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: c.divider),
            _row(i),
          ],
        ]),
      ),
    );
  }

  // Line lengths vary a little from row to row, as real names do.
  Widget _row(int i) => Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          if (leading) ...[const SkeletonBox(height: 36, circle: true), const SizedBox(width: 12)],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              FractionallySizedBox(widthFactor: const [0.62, 0.48, 0.7, 0.55][i % 4], child: const SkeletonBox(height: 14)),
              const SizedBox(height: 8),
              FractionallySizedBox(widthFactor: const [0.4, 0.55, 0.35, 0.46][i % 4], child: const SkeletonBox()),
            ]),
          ),
          if (figure) ...[const SizedBox(width: 12), const SkeletonBox(width: 64, height: 14)],
        ]),
      );
}

/// Full-width rounded blocks, for cards and figures: one per height.
class SkeletonBlocks extends StatelessWidget {
  final List<double> heights;
  final double radius;
  final double gap;

  const SkeletonBlocks(this.heights, {super.key, this.radius = 24, this.gap = 12});

  @override
  Widget build(BuildContext context) => Skeleton(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final (i, h) in heights.indexed) ...[
            if (i > 0) SizedBox(height: gap),
            SkeletonBox(height: h, radius: radius),
          ],
        ]),
      );
}

/// Paragraphs of loading text, for a page of words.
class SkeletonText extends StatelessWidget {
  final int paragraphs;
  const SkeletonText({super.key, this.paragraphs = 3});

  @override
  Widget build(BuildContext context) => Skeleton(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SkeletonBox(width: 220, height: 22),
          for (var p = 0; p < paragraphs; p++) ...[
            const SizedBox(height: 24),
            for (var l = 0; l < 4; l++) ...[
              if (l > 0) const SizedBox(height: 10),
              FractionallySizedBox(widthFactor: l == 3 ? 0.6 : 1, child: const SkeletonBox()),
            ],
          ],
        ]),
      );
}

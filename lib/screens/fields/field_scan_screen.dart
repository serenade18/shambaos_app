import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/phosphor_icons.dart';
import 'field_detail_screen.dart';
import 'field_service.dart';
import 'field_widgets.dart';

/// The field's photo with a scanning frame. "Analyse field" gathers the field's
/// satellite health, weather and records, then opens the field page.
class FieldScanScreen extends StatefulWidget {
  final Field field;
  const FieldScanScreen({super.key, required this.field});

  @override
  State<FieldScanScreen> createState() => _FieldScanScreenState();
}

class _FieldScanScreenState extends State<FieldScanScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _sweep =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
  bool _analysing = false;

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  Future<void> _analyse() async {
    setState(() => _analysing = true);
    // At least one sweep, so the result never flashes past.
    final results = await Future.wait([
      FieldService.analyse(widget.field),
      FieldService.tasks(widget.field),
      Future.delayed(const Duration(milliseconds: 1400)),
    ]);
    if (!mounted) return;
    setState(() => _analysing = false);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => FieldDetailScreen(
        field: widget.field,
        metrics: results[0] as List<FieldMetric>,
        tasks: results[1] as List<FieldTask>,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion && _sweep.isAnimating) _sweep.stop();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            FieldPhoto(type: widget.field.type),
            // A soft darkening at the bottom so the card and button stay readable.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0x8C17211A)],
                ),
              ),
            ),
            // The scanning frame.
            Center(
              child: FractionallySizedBox(
                widthFactor: 0.52,
                heightFactor: 0.38,
                child: AnimatedBuilder(
                  animation: _sweep,
                  builder: (_, _) => CustomPaint(painter: _ScanFramePainter(c.shamba, _sweep.value)),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(alignment: Alignment.centerLeft, child: PhotoBackButton()),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FieldCard(field: widget.field, compact: true),
                    ),
                    const SizedBox(height: 120),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _analysing ? null : _analyse,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.cardBackground,
                          foregroundColor: c.textPrimary,
                          disabledBackgroundColor: c.cardBackground,
                          disabledForegroundColor: c.textSecondary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          textStyle: AppType.label.copyWith(fontSize: 16),
                        ),
                        icon: _analysing
                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: c.shamba))
                            : const Icon(PhosphorIconsFill.sparkle, size: 20),
                        label: Text(_analysing ? 'Analysing your field…' : 'Analyse field with AI'),
                      ),
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

/// Green corner brackets with a band of light sweeping down and up inside them.
class _ScanFramePainter extends CustomPainter {
  final Color color;
  final double t;
  _ScanFramePainter(this.color, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final frame = RRect.fromRectAndRadius(rect, const Radius.circular(18));

    // The sweep: a soft band of the brand green, clipped to the frame.
    canvas.save();
    canvas.clipRRect(frame);
    canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.10));
    final bandH = size.height * 0.45;
    final y = -bandH + (size.height + bandH) * t;
    final band = Rect.fromLTWH(0, y, size.width, bandH);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.45), color.withValues(alpha: 0)],
        ).createShader(band),
    );
    canvas.restore();

    // The thin outline and the four strong corners.
    canvas.drawRRect(frame, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.55));
    final corner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = color;
    const r = 18.0;
    final l = size.width * 0.22;
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(0, l)..lineTo(0, r)..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))..lineTo(l, 0)
      ..moveTo(w - l, 0)..lineTo(w - r, 0)..arcToPoint(Offset(w, r), radius: const Radius.circular(r))..lineTo(w, l)
      ..moveTo(w, h - l)..lineTo(w, h - r)..arcToPoint(Offset(w - r, h), radius: const Radius.circular(r))..lineTo(w - l, h)
      ..moveTo(l, h)..lineTo(r, h)..arcToPoint(Offset(0, h - r), radius: const Radius.circular(r))..lineTo(0, h - l);
    canvas.drawPath(path, corner);
  }

  @override
  bool shouldRepaint(_ScanFramePainter old) => old.t != t || old.color != color;
}

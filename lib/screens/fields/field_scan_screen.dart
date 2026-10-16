import 'dart:ui' show ImageFilter;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../auth/auth_ui.dart';
import '../../widgets/phosphor_icons.dart';
import 'field_service.dart';
import 'field_widgets.dart';
import 'photo_check.dart';
import 'scan_result_screen.dart';
import '../../l10n/tr.dart';

/// The AI screen, opened from the centre of the bottom nav: the live camera with a
/// scanning frame. Swipe the card to choose the field, point the camera at the crop
/// or animals, and "Scan with AI" takes the photo and sends it to be checked.
class FieldScanScreen extends StatefulWidget {
  final Field? field; // start on this field; null starts on the first one
  const FieldScanScreen({super.key, this.field});

  @override
  State<FieldScanScreen> createState() => _FieldScanScreenState();
}

class _FieldScanScreenState extends State<FieldScanScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _sweep =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
  final _pages = PageController(viewportFraction: 0.94);

  CameraController? _camera;
  String? _cameraProblem; // why there is no live preview
  Uint8List? _captured; // the photo being checked, frozen on screen

  List<Field>? _fields;
  bool _noFarm = false;
  int _index = 0;
  bool _checking = false;

  Field? get _field => _fields == null || _fields!.isEmpty ? null : _fields![_index];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    _sweep.dispose();
    _pages.dispose();
    super.dispose();
  }

  // The camera is released while the app is in the background, and restarted on return.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final camera = _camera;
    if (state == AppLifecycleState.inactive) {
      _camera = null;
      camera?.dispose();
    } else if (state == AppLifecycleState.resumed && camera == null) {
      _startCamera();
    }
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraProblem = 'This phone has no camera. Choose a photo instead.'.tr);
        return;
      }
      final back = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cameras.first);
      final controller = CameraController(back, ResolutionPreset.high, enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _cameraProblem = null;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() => _cameraProblem = switch (e.code) {
            'CameraAccessDenied' || 'CameraAccessDeniedWithoutPrompt' || 'CameraAccessRestricted' =>
              'Camera access is off. Allow it in your phone settings, or choose a photo.'.tr,
            _ => 'The camera could not start. Choose a photo instead.'.tr,
          });
    } catch (_) {
      if (mounted) setState(() => _cameraProblem = 'The camera could not start. Choose a photo instead.'.tr);
    }
  }

  Future<void> _load() async {
    final (farm, fields) = await FieldService.load();
    if (!mounted) return;
    final start = widget.field == null ? 0 : fields.indexWhere((f) => f.id == widget.field!.id);
    setState(() {
      _noFarm = farm == null;
      _fields = fields.isEmpty && widget.field != null ? [widget.field!] : fields;
      _index = start < 0 ? 0 : start;
    });
    if (_index > 0 && _pages.hasClients) _pages.jumpToPage(_index);
  }

  /// Takes the photo with the camera.
  Future<void> _scan() async {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized || camera.value.isTakingPicture) return;
    try {
      final shot = await camera.takePicture();
      await _check(await shot.readAsBytes());
    } on CameraException {
      _say('Could not take the photo. Try again.'.tr);
    }
  }

  /// Uses a photo the farmer already took.
  Future<void> _pick() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (picked != null) await _check(await picked.readAsBytes());
  }

  Future<void> _check(Uint8List photo) async {
    final field = _field;
    if (field == null) return;
    setState(() {
      _captured = photo;
      _checking = true;
    });
    try {
      final result = await PhotoCheckService.check(field, photo);
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => ScanResultScreen(field: field, photo: photo, check: result),
      ));
    } on FieldLoadError catch (e) {
      _say(e.message);
    }
    if (mounted) {
      setState(() {
        _captured = null;
        _checking = false;
      });
    }
  }

  void _say(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Where the scanning frame sits: 240 by 300 on a 390-wide phone, a little above the middle.
  static Rect _frameRect(Size size) {
    final w = (size.width * 0.62).clamp(200.0, 300.0);
    final h = w * 1.25;
    final cy = size.height * 0.415;
    return Rect.fromCenter(center: Offset(size.width / 2, cy), width: w, height: h);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion && _sweep.isAnimating) _sweep.stop();
    final field = _field;
    final camera = _camera;
    final live = camera != null && camera.value.isInitialized;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF101511),
        body: LayoutBuilder(builder: (context, box) {
          final frame = _frameRect(box.biggest);
          return Stack(
            fit: StackFit.expand,
            children: [
              // What the camera sees, the frozen photo being checked, or why there is no camera.
              if (_captured != null)
                Image.memory(_captured!, fit: BoxFit.cover, gaplessPlayback: true)
              else if (live)
                _Preview(camera)
              else
                _NoCamera(problem: _cameraProblem),
              // A shade at the top so the title reads.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 180 + top,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x9917211A), Color(0x0017211A)],
                    ),
                  ),
                ),
              ),
              // The frame: the rest of the picture dimmed, a light rounded edge,
              // and a band of green sweeping through while the photo is checked.
              if (live || _captured != null)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _sweep,
                    builder: (_, _) => CustomPaint(
                      painter: _ScanFramePainter(frame, c.shamba, _checking && !reduceMotion ? _sweep.value : null),
                    ),
                  ),
                ),
              if (live || _captured != null)
                Positioned(
                  left: 40,
                  right: 40,
                  top: frame.bottom + 16,
                  child: Text(
                    _checking ? 'Checking your photo…'.tr : 'Fill the frame with the leaves, fruit or animal'.tr,
                    textAlign: TextAlign.center,
                    style: AppType.label.copyWith(color: Colors.white),
                  ),
                ),
              // Close and the title.
              Positioned(
                left: 16,
                right: 16,
                top: top + 20,
                child: Row(children: [
                  _glassButton(c, 44, '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>', 'Close'.tr,
                      () => Navigator.canPop(context) ? Navigator.pop(context) : Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Scan with AI'.tr,
                        style: const TextStyle(fontFamily: AppType.text, fontSize: 17, height: 22 / 17, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ]),
              ),
              // The field the photo is for: swipe to choose another.
              Positioned(left: 16, right: 16, bottom: 136 + bottom, child: _picker(c)),
              // Choose a photo, the shutter, Ask Tulip.
              Positioned(
                left: 32,
                right: 32,
                bottom: 32 + bottom,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _glassButton(c, 52, _Icons.image, 'Choose a photo'.tr, _checking || field == null ? null : _pick),
                    _shutter(c, _checking || field == null || !live ? null : _scan),
                    _glassButton(c, 52, _Icons.chat, 'Ask Tulip'.tr, () => Navigator.pushNamed(context, '/chat')),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// The fields to choose from, one frosted card each: swipe to choose.
  Widget _picker(AppColors c) {
    final fields = _fields;
    if (fields == null) {
      return const SizedBox(height: 72, child: Center(child: CircularProgressIndicator(color: Colors.white)));
    }
    if (fields.isEmpty) {
      return _glass(
        c,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_noFarm ? 'Set up your farm first'.tr : 'No fields to scan yet'.tr, style: AppType.label.copyWith(color: c.textPrimary)),
            const SizedBox(height: 2),
            Text(
              _noFarm ? 'Add your farm, then the animals and crops you keep.'.tr : 'Add the animals you keep and the crops you grow.'.tr,
              style: AppType.caption.copyWith(color: c.textSecondary),
            ),
          ]),
        ),
      );
    }
    return SizedBox(
      height: 72,
      child: PageView.builder(
        controller: _pages,
        itemCount: fields.length,
        padEnds: false,
        onPageChanged: _checking ? null : (i) => setState(() => _index = i),
        physics: _checking ? const NeverScrollableScrollPhysics() : null,
        itemBuilder: (_, i) {
          final f = fields[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
              label: fields.length > 1 ? 'Field {p0} of {length}. Swipe to choose another.'.trArgs({'p0': i + 1, 'length': fields.length}) : null,
              child: _glass(
                c,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Image.asset(fieldIcon(f.type, crop: f.isCrop), width: 30, height: 30, excludeFromSemantics: true),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(f.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: AppType.text, fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w700, color: c.textPrimary)),
                        Text(
                          fields.length > 1
                              ? 'Field {p0} of {length}. Swipe to choose another.'.trArgs({'p0': i + 1, 'length': fields.length})
                              : f.size,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.caption.copyWith(color: c.textSecondary),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// A frosted panel over the camera (sl-glass).
  Widget _glass(AppColors c, {required Widget child, double radius = 24}) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Material(color: c.cardBackground.withValues(alpha: 0.86), child: child),
        ),
      );

  /// A round frosted button (sl-iconbtn).
  Widget _glassButton(AppColors c, double size, String icon, String label, VoidCallback? onTap) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Opacity(
          opacity: onTap == null ? 0.6 : 1,
          child: _glass(
            c,
            radius: 999,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(width: size, height: size, child: Center(child: LineIcon(icon, size: 24, color: c.textPrimary))),
            ),
          ),
        ),
      );

  /// The shutter: a white ring round a white disc; a spinner while checking.
  Widget _shutter(AppColors c, VoidCallback? onTap) => Semantics(
        button: true,
        label: 'Take the photo'.tr,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
            alignment: Alignment.center,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: onTap == null && !_checking ? 0.5 : 1), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: _checking ? SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3, color: c.shamba)) : null,
            ),
          ),
        ),
      );
}

/// The scan screen's line icons (Lucide, ISC licence).
class _Icons {
  static const image = '<rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/>';
  static const chat = '<path d="M7.9 20A9 9 0 1 0 4 16.1L2 22Z"/>';
}

/// The live camera image, filling the screen without stretching.
class _Preview extends StatelessWidget {
  final CameraController camera;
  const _Preview(this.camera);

  @override
  Widget build(BuildContext context) {
    final size = camera.value.previewSize;
    if (size == null) return CameraPreview(camera);
    // previewSize is reported in landscape; the screen is portrait.
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(width: size.height, height: size.width, child: CameraPreview(camera)),
      ),
    );
  }
}

/// Shown where the camera would be when it cannot start.
class _NoCamera extends StatelessWidget {
  final String? problem;
  const _NoCamera({this.problem});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF101511),
      alignment: const Alignment(0, -0.2),
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: problem == null
          ? const CircularProgressIndicator(color: Colors.white)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(PhosphorIconsRegular.cameraSlash, size: 48, color: Colors.white70),
                const SizedBox(height: 12),
                Text(problem!, textAlign: TextAlign.center, style: AppType.body.copyWith(color: Colors.white)),
              ],
            ),
    );
  }
}

/// The scanning frame: the picture dimmed outside a rounded rectangle, a light
/// 3 px edge, and, while a photo is checked, a band of green sweeping through.
class _ScanFramePainter extends CustomPainter {
  final Rect frame;
  final Color color;
  final double? t; // the sweep's position, null when still
  _ScanFramePainter(this.frame, this.color, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(frame, const Radius.circular(28));
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(rrect);
    canvas.drawPath(outside, Paint()..color = const Color(0x4017211A));

    if (t != null) {
      canvas.save();
      canvas.clipRRect(rrect);
      final bandH = frame.height * 0.45;
      final y = frame.top - bandH + (frame.height + bandH) * t!;
      final band = Rect.fromLTWH(frame.left, y, frame.width, bandH);
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
    }

    canvas.drawRRect(rrect, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white.withValues(alpha: 0.86));
  }

  @override
  bool shouldRepaint(_ScanFramePainter old) => old.t != t || old.frame != frame || old.color != color;
}

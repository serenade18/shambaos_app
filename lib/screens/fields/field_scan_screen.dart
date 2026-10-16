import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/ledger.dart';
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
  final _pages = PageController(viewportFraction: 0.86);

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

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion && _sweep.isAnimating) _sweep.stop();
    final field = _field;
    final camera = _camera;
    final live = camera != null && camera.value.isInitialized;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // What the camera sees, the frozen photo being checked, or why there is no camera.
            if (_captured != null)
              Image.memory(_captured!, fit: BoxFit.cover, gaplessPlayback: true)
            else if (live)
              _Preview(camera)
            else
              _NoCamera(problem: _cameraProblem),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0x8C17211A)],
                ),
              ),
            ),
            if (live || _captured != null)
              Center(
                child: FractionallySizedBox(
                  widthFactor: 0.62,
                  heightFactor: 0.36,
                  child: AnimatedBuilder(
                    animation: _sweep,
                    builder: (_, _) => CustomPaint(
                      painter: _ScanFramePainter(c.shamba, _checking || !reduceMotion ? _sweep.value : 0.5),
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (Navigator.canPop(context)) const PhotoBackButton(),
                        const Spacer(),
                        _tulipButton(c),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(999)),
                        child: Text(
                          _checking ? 'Checking your photo…'.tr : 'Fill the frame with the leaves, fruit or animal'.tr,
                          style: AppType.caption.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                    const Spacer(),
                    _picker(c),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _roundButton(c, PhosphorIconsRegular.image, 'Choose a photo'.tr,
                            _checking || field == null ? null : _pick),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _checking || field == null || !live ? null : _scan,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: c.cardBackground,
                                foregroundColor: c.textPrimary,
                                disabledBackgroundColor: c.cardBackground.withValues(alpha: 0.7),
                                disabledForegroundColor: c.textSecondary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                textStyle: AppType.label.copyWith(fontSize: 16),
                              ),
                              icon: _checking
                                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: c.shamba))
                                  : const Icon(PhosphorIconsFill.sparkle, size: 20),
                              label: Text(_checking ? 'Checking…'.tr : 'Scan with AI'.tr),
                            ),
                          ),
                        ),
                      ],
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

  /// The fields to choose from, one card each: swipe to choose.
  Widget _picker(AppColors c) {
    final fields = _fields;
    if (fields == null) {
      return Center(child: CircularProgressIndicator(color: c.cardBackground));
    }
    if (fields.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SlLedger(children: [
          SlLedgerRow(
            title: _noFarm ? 'Set up your farm first'.tr : 'No fields to scan yet'.tr,
            meta: _noFarm
                ? 'Add your farm, then the animals and crops you keep.'.tr
                : 'Add the animals you keep and the crops you grow.'.tr,
          ),
        ]),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 96,
          child: PageView.builder(
            controller: _pages,
            itemCount: fields.length,
            onPageChanged: _checking ? null : (i) => setState(() => _index = i),
            physics: _checking ? const NeverScrollableScrollPhysics() : null,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: FieldCard(field: fields[i], compact: true),
            ),
          ),
        ),
        if (fields.length > 1) ...[
          const SizedBox(height: 10),
          Semantics(
            label: 'Field {p0} of {length}. Swipe to choose another.'.trArgs({'p0': _index + 1, 'length': fields.length}),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < fields.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _index ? c.maize : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _roundButton(AppColors c, IconData icon, String label, VoidCallback? onTap) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: c.cardBackground.withValues(alpha: onTap == null ? 0.7 : 1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(width: 56, height: 56, child: Icon(icon, size: 24, color: c.textPrimary)),
        ),
      ),
    );
  }

  /// Tulip, the chat assistant, from the corner of the AI screen.
  Widget _tulipButton(AppColors c) {
    return Material(
      color: c.cardBackground,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.pushNamed(context, '/chat'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIconsRegular.chatCircleText, size: 20, color: c.textPrimary),
              const SizedBox(width: 8),
              Text('Ask Tulip'.tr, style: AppType.label.copyWith(color: c.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
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

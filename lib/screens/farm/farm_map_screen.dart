import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/tr.dart';
import '../../services/app_theme.dart';
import '../../services/app_type.dart';
import '../auth/auth_ui.dart';
import 'boundary_geo.dart';
import 'farm_map_service.dart';
import 'farm_map_view.dart';

enum _Stage { start, draw, walk, saved }

/// Map your farm (FRM-01/03): draw its boundary on satellite imagery, or walk
/// round it marking each corner by GPS. Saving sends it to PATCH /farms/{id};
/// the server works out the area and registers it for weather and satellite
/// data. Pops with true once a boundary is saved.
class FarmMapScreen extends StatefulWidget {
  /// The farm as GET /farms returns it: id, name, county, location, boundary.
  final Map<String, dynamic> farm;
  const FarmMapScreen({super.key, required this.farm});

  static Future<bool?> open(BuildContext context, Map<String, dynamic> farm) =>
      Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => FarmMapScreen(farm: farm)));

  /// Bumped each time a boundary is saved, so Home can reload the farm.
  static final boundarySaved = ValueNotifier<int>(0);

  static String _laterKey(String farmId) => 'farm_map_later_$farmId';

  /// True once the farmer chose "Later" for this farm: sign-in stops offering the map.
  static Future<bool> putOff(String farmId) async =>
      (await SharedPreferences.getInstance()).getBool(_laterKey(farmId)) ?? false;

  static Future<void> _setPutOff(String farmId, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    value ? await prefs.setBool(_laterKey(farmId), true) : await prefs.remove(_laterKey(farmId));
  }

  @override
  State<FarmMapScreen> createState() => _FarmMapScreenState();
}

class _FarmMapScreenState extends State<FarmMapScreen> {
  final _map = FarmMapController();
  late _Stage _stage;
  late List<LngLat> _ring;
  bool _hadBoundary = false;
  bool _mapFailed = false;

  // Walking: the fix, how sure it is, and the path walked since the first corner.
  StreamSubscription<Position>? _gps;
  LngLat? _here;
  double? _accuracy;
  double _walked = 0;
  LngLat? _lastStep;
  String? _gpsProblem;
  bool _locating = false;

  bool _saving = false;
  String? _saveError;
  Map<String, dynamic>? _saved; // the farm as the server returned it

  String get _farmName => '${widget.farm['name'] ?? ''}';
  String get _place {
    final county = '${widget.farm['county'] ?? ''}';
    return county.isEmpty ? _farmName : '$_farmName, $county';
  }

  @override
  void initState() {
    super.initState();
    _ring = fromPolygon(widget.farm['boundary']);
    _hadBoundary = _ring.length >= 3;
    _stage = _hadBoundary ? _Stage.draw : _Stage.start;
    final loc = widget.farm['location'];
    final center = loc is Map ? ((loc['lng'] as num).toDouble(), (loc['lat'] as num).toDouble()) : null;
    FarmMapService.ionToken().then((token) => _map.init(token: token, center: center, ring: _ring));
    _redraw();
  }

  @override
  void dispose() {
    _gps?.cancel();
    super.dispose();
  }

  // ── The shape on the map ─────────────────────────────────
  BoundaryProblem? get _problem => _ring.length < 3 ? null : boundaryProblem(_ring);

  void _redraw() {
    final bad = _ring.length >= 4 ? crossing(_ring) : null;
    _map.setRing(
      _ring,
      closed: _stage == _Stage.saved || (_stage == _Stage.draw && _hadBoundary),
      editable: _stage == _Stage.draw,
      active: _stage == _Stage.saved || _ring.isEmpty ? null : _ring.length - 1,
      bad: bad,
    );
  }

  void _onMapEvent(MapEvent e) {
    switch (e) {
      case MapTap(:final point):
        if (_stage != _Stage.draw || _ring.length >= maxCorners) return;
        setState(() {
          _ring = [..._ring, point];
          _saveError = null;
        });
      case MapMove(:final index, :final point):
        if (index >= _ring.length) return;
        setState(() {
          _ring = [..._ring]..[index] = point;
          _saveError = null;
        });
      case MapFailed():
        setState(() => _mapFailed = true);
    }
    _redraw();
  }

  void _undo() {
    if (_ring.isEmpty) return;
    setState(() {
      _ring = _ring.sublist(0, _ring.length - 1);
      _saveError = null;
    });
    _redraw();
  }

  void _clear() {
    setState(() {
      _ring = [];
      _hadBoundary = false;
      _saveError = null;
    });
    _redraw();
  }

  void _go(_Stage stage) {
    setState(() {
      _stage = stage;
      _saveError = null;
    });
    if (stage == _Stage.walk) {
      _startGps();
    } else {
      _gps?.cancel();
      _gps = null;
    }
    _redraw();
  }

  // ── GPS ──────────────────────────────────────────────────
  /// Asks for location if needed; null when it's allowed, else why not.
  Future<String?> _gpsAllowed() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return 'Turn on location in your phone settings.'.tr;
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        return 'Allow Shamba OS to use your location to walk the boundary.'.tr;
      }
      return null;
    } catch (_) {
      return 'Could not get your location. Go outside and try again.'.tr;
    }
  }

  Future<void> _startGps() async {
    final problem = await _gpsAllowed();
    if (!mounted) return;
    setState(() => _gpsProblem = problem);
    if (problem != null) return;
    var first = true;
    _gps?.cancel();
    _gps = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 1),
    ).listen((pos) {
      final p = (pos.longitude, pos.latitude);
      if (!mounted) return;
      setState(() {
        if (_lastStep != null && _ring.isNotEmpty) _walked += metresBetween(_lastStep!, p);
        _lastStep = p;
        _here = p;
        _accuracy = pos.accuracy;
      });
      _map.showMe(p, pos.accuracy);
      if (first) {
        first = false;
        _map.lookAt(p);
      }
    }, onError: (_) {
      if (mounted) setState(() => _gpsProblem = 'Could not get your location. Go outside and try again.'.tr);
    });
  }

  /// Show where the phone is (the draw tools' locate button).
  Future<void> _locate() async {
    if (_locating) return;
    setState(() => _locating = true);
    final problem = await _gpsAllowed();
    if (problem == null) {
      try {
        final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
        final p = (pos.longitude, pos.latitude);
        _map.showMe(p, pos.accuracy);
        _map.lookAt(p);
      } catch (_) {
        if (mounted) _toast('Could not get your location. Go outside and try again.'.tr);
      }
    } else if (mounted) {
      _toast(problem);
    }
    if (mounted) setState(() => _locating = false);
  }

  void _markCorner() {
    final here = _here;
    if (here == null || _ring.length >= maxCorners) return;
    setState(() {
      if (_ring.isEmpty) _walked = 0;
      _ring = [..._ring, here];
      _saveError = null;
    });
    _redraw();
  }

  /// Not now: don't offer the map at sign-in again (Home still does).
  void _later() {
    FarmMapScreen._setPutOff('${widget.farm['id']}', true);
    Navigator.of(context).pop(false);
  }

  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Ledger.ink, content: Text(text)));

  // ── Saving ───────────────────────────────────────────────
  String? _problemText(BoundaryProblem? p) => switch (p) {
        BoundaryProblem.few => 'Mark at least three corners of the farm.'.tr,
        BoundaryProblem.crosses => 'The boundary crosses itself. Mark the corners in order around the farm.'.tr,
        BoundaryProblem.big => 'That is bigger than 3,000 hectares. Draw each farm separately.'.tr,
        BoundaryProblem.many => 'Use at most 200 corners.'.tr,
        null => null,
      };

  Future<void> _save() async {
    if (_saving || _ring.length < 3 || _problem != null) return;
    _gps?.cancel();
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final res = await FarmMapService.saveBoundary('${widget.farm['id']}', _ring);
    if (!mounted) return;
    if (!res.error && res.data is Map) {
      setState(() {
        _saving = false;
        _saved = Map<String, dynamic>.from(res.data);
        _hadBoundary = true;
        _stage = _Stage.saved;
      });
      FarmMapScreen.boundarySaved.value++;
      FarmMapScreen._setPutOff('${widget.farm['id']}', false);
      _redraw();
      _map.fit();
    } else {
      setState(() {
        _saving = false;
        _saveError = res.message ?? 'Could not save. Check your connection and try again.'.tr;
      });
    }
  }

  // ── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) => Theme(data: AppTheme.light(), child: Builder(builder: _buildScreen));

  Widget _buildScreen(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return PopScope(
      canPop: _stage == _Stage.start || _stage == _Stage.saved || _ring.isEmpty || _hadBoundary,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _confirmLeave();
          return;
        }
        // Backing out of the start screen is the same as "Later".
        if (_stage == _Stage.start && result == null) FarmMapScreen._setPutOff('${widget.farm['id']}', true);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFB9C7A8),
        resizeToAvoidBottomInset: false,
        body: Stack(children: [
          Positioned.fill(child: FarmMapView(controller: _map, onEvent: _onMapEvent)),
          if (_stage == _Stage.start)
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.25, 0.52],
                      colors: [Color(0x0017211A), Color(0x8C17211A)],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(left: 16, right: 16, top: top + 12, child: _topBar()),
          if (_stage == _Stage.draw || _stage == _Stage.walk) Positioned(left: 16, top: top + 76, right: 80, child: _hintPills()),
          if (_stage == _Stage.draw || _stage == _Stage.walk) Positioned(right: 16, top: top + 220, child: _tools()),
          Positioned(left: 0, right: 0, bottom: 0, child: _sheet()),
          if (_mapFailed) Positioned.fill(child: _failed()),
        ]),
      ),
    );
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Ledger.sheet,
        title: Text('Leave without saving?'.tr, style: Ledger.title.copyWith(fontSize: 19, height: 24 / 19)),
        content: Text('The corners you marked will be lost.'.tr, style: Ledger.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Keep mapping'.tr, style: Ledger.link)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Leave'.tr, style: Ledger.link.copyWith(color: Ledger.dangerInk))),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop(false);
  }

  Widget _roundButton({required String label, required Widget icon, VoidCallback? onTap, bool busy = false}) => Semantics(
        button: true,
        label: label,
        child: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(color: Ledger.sheet, shape: BoxShape.circle, boxShadow: Ledger.shadowSoft),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Center(
                child: busy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Ledger.shamba))
                    : Opacity(opacity: onTap == null ? 0.4 : 1, child: icon),
              ),
            ),
          ),
        ),
      );

  Widget _topBar() {
    final (eyebrow, title) = switch (_stage) {
      _Stage.start => (_place.toUpperCase(), 'Map your farm'.tr),
      _Stage.draw => ('DRAW ON THE MAP'.tr, 'Tap each corner in order'.tr),
      _Stage.walk => ('WALK AROUND IT'.tr, 'Stand on a corner, then mark it'.tr),
      _Stage.saved => (_place.toUpperCase(), 'Boundary saved'.tr),
    };
    final close = _stage == _Stage.start || _stage == _Stage.saved;
    return Row(children: [
      _roundButton(
        label: close ? 'Close'.tr : 'Back'.tr,
        icon: LineIcon(close ? LineIcon.x : LineIcon.arrowLeft),
        onTap: () {
          if (_stage == _Stage.saved) {
            Navigator.of(context).pop(true);
          } else if (_stage == _Stage.start) {
            _later();
          } else if (close || _hadBoundary) {
            Navigator.of(context).maybePop();
          } else if (_ring.isNotEmpty) {
            _confirmLeaveStage();
          } else {
            _go(_Stage.start);
          }
        },
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: Ledger.sheet, borderRadius: BorderRadius.circular(999), boxShadow: Ledger.shadowSoft),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(eyebrow, style: Ledger.eyebrow, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(title, style: Ledger.label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    ]);
  }

  Future<void> _confirmLeaveStage() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Ledger.sheet,
        title: Text('Start again?'.tr, style: Ledger.title.copyWith(fontSize: 19, height: 24 / 19)),
        content: Text('The corners you marked will be lost.'.tr, style: Ledger.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Keep mapping'.tr, style: Ledger.link)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Start again'.tr, style: Ledger.link.copyWith(color: Ledger.dangerInk))),
        ],
      ),
    );
    if (leave == true && mounted) {
      _clear();
      _go(_Stage.start);
    }
  }

  Widget _pill(String text, {Widget? icon}) => Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xC717211A), borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[icon, const SizedBox(width: 8)],
          Flexible(child: Text(text, style: const TextStyle(fontFamily: AppType.text, fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w700, color: Colors.white))),
        ]),
      );

  Widget _hintPills() {
    if (_stage == _Stage.draw) {
      return Align(alignment: Alignment.centerLeft, child: _pill('Pinch to zoom. Drag a corner to move it.'.tr));
    }
    final acc = _accuracy;
    return Wrap(spacing: 8, runSpacing: 8, children: [
      _pill(acc == null ? 'Finding you…'.tr : 'GPS within {m} m'.trArgs({'m': acc.round()})),
      _pill('Keep the app open'.tr),
    ]);
  }

  Widget _tools() {
    final tools = <Widget>[
      if (_stage == _Stage.draw)
        _roundButton(label: 'Show where I am'.tr, icon: const LineIcon(_Icons.locate), onTap: _locate, busy: _locating),
      _roundButton(label: 'Undo last corner'.tr, icon: const LineIcon(_Icons.undo), onTap: _ring.isEmpty ? null : _undo),
      if (_stage == _Stage.draw)
        _roundButton(label: 'Start again'.tr, icon: const LineIcon(_Icons.trash), onTap: _ring.isEmpty ? null : _clear),
      if (_stage == _Stage.walk)
        _roundButton(label: 'Switch to drawing'.tr, icon: const LineIcon(_Icons.pen), onTap: () => _go(_Stage.draw)),
    ];
    return Column(children: [
      for (final t in tools) ...[t, const SizedBox(height: 10)],
    ]);
  }

  Widget _sheet() {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 28 + bottom),
      decoration: const BoxDecoration(
        color: Ledger.sheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(Ledger.radiusSheet)),
        boxShadow: Ledger.shadowSheet,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Ledger.rule, borderRadius: BorderRadius.circular(999)))),
        const SizedBox(height: 14),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: switch (_stage) {
            _Stage.start => _startSheet(),
            _Stage.draw => _drawSheet(),
            _Stage.walk => _walkSheet(),
            _Stage.saved => _savedSheet(),
          },
        ),
      ]),
    );
  }

  // 1. Why map, and two ways to do it.
  Widget _startSheet() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text("Draw your farm's boundary".tr, style: Ledger.title),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('With your exact land, weather, soil and satellite crop checks are for your farm, not the whole county.'.tr, style: Ledger.body),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: Ledger.rule, width: 1.5)),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            _choice(_Icons.footprints, 'Walk around it'.tr, 'Mark each corner as you stand on it. Most accurate.'.tr, () => _go(_Stage.walk)),
            const Divider(height: 1, thickness: 1, color: Ledger.rule),
            _choice(_Icons.pen, 'Draw it on the map'.tr, 'Tap the corners from here. Quick.'.tr, () => _go(_Stage.draw)),
          ]),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _later,
          style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48), foregroundColor: Ledger.shambaInk),
          child: Text(
            '${widget.farm['county'] ?? ''}'.isEmpty
                ? 'Later'.tr
                : 'Later. Use {county} county for now'.trArgs({'county': widget.farm['county']}),
            style: Ledger.link.copyWith(fontSize: 16),
          ),
        ),
      ]);

  Widget _choice(String icon, String title, String meta, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: Ledger.shambaTint, shape: BoxShape.circle),
              child: Center(child: LineIcon(icon, size: 20, color: Ledger.shambaInk)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: Ledger.label),
                const SizedBox(height: 2),
                Text(meta, style: Ledger.caption),
              ]),
            ),
            const LineIcon(_Icons.chevronRight, size: 20, color: Ledger.inkMuted),
          ]),
        ),
      );

  Widget _stat(String figure, String label) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(figure, style: const TextStyle(fontFamily: AppType.text, fontSize: 24, height: 28 / 24, fontWeight: FontWeight.w500, color: Ledger.ink, fontFeatures: [FontFeature.tabularFigures()])),
          const SizedBox(height: 2),
          Text(label, style: Ledger.caption),
        ]),
      );

  static final _one = NumberFormat('#,##0.0');
  static final _whole = NumberFormat('#,##0');

  Widget _sizeStats(String cornersLabel) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
        child: Row(children: [
          _stat('${_ring.length}', cornersLabel),
          // No size while the shape can't be measured (too few corners, or it crosses itself).
          _stat(_ring.length < 3 || _problem == BoundaryProblem.crosses ? '–' : _one.format(hectares(_ring)), 'hectares'.tr),
          _stat(_ring.length < 3 || _problem == BoundaryProblem.crosses ? '–' : _one.format(acres(_ring)), 'acres'.tr),
        ]),
      );

  /// The red note when the shape can't be saved, or the server said no.
  Widget? _problemNote() {
    final text = _saveError ?? _problemText(_ring.length >= 3 ? _problem : null);
    if (text == null) return null;
    final cross = _ring.length >= 4 ? crossing(_ring) : null;
    // Edges i→i+1 and j→j+1 cross: corners i+1 and j are the likely swap (shown counting from 1).
    final which = cross == null
        ? null
        : 'Corners {a} and {b} look out of order. Drag them, or undo and tap again.'
            .trArgs({'a': (cross.$1 + 1) % _ring.length + 1, 'b': cross.$2 + 1});
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF7DEDA), borderRadius: BorderRadius.circular(18)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(color: Color(0xFFFFFFFF), shape: BoxShape.circle),
          child: const Center(child: LineIcon(_Icons.alert, size: 20, color: Ledger.dangerInk)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(text, style: Ledger.body.copyWith(color: Ledger.ink, fontWeight: FontWeight.w700)),
            if (which != null) ...[const SizedBox(height: 4), Text(which, style: Ledger.caption)],
          ]),
        ),
      ]),
    );
  }

  // 2. Draw: tap corners, see the size, close and save.
  Widget _drawSheet() {
    final canSave = _ring.length >= 3 && _problem == null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _sizeStats('corners'.tr),
      ?_problemNote(),
      if (_ring.length < 3 && _saveError == null)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
          child: Text(
            _ring.isEmpty ? 'Tap the first corner of your farm on the map.'.tr : 'Tap the next corner, going round in order.'.tr,
            style: Ledger.caption,
          ),
        ),
      Row(children: [
        Expanded(
          flex: 10,
          child: LedgerButton(
            label: 'Undo'.tr,
            kind: LedgerButtonKind.secondary,
            icon: const LineIcon(_Icons.undo, size: 20),
            onPressed: _ring.isEmpty ? null : _undo,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 13,
          child: LedgerButton(
            label: _hadBoundary ? 'Save boundary'.tr : 'Close boundary'.tr,
            busy: _saving,
            onPressed: canSave ? _save : null,
          ),
        ),
      ]),
    ]);
  }

  // 3. Walk: mark the corner you stand on.
  Widget _walkSheet() {
    final back = _here != null && _ring.isNotEmpty ? metresBetween(_here!, _ring.first) : null;
    final next = _ring.length + 1;
    final ready = _here != null && (_accuracy ?? 999) <= 30;
    final note = _gpsProblem ??
        (_here == null
            ? 'Finding where you are. Stand in the open, away from buildings and trees.'.tr
            : !ready
                ? 'Waiting for a closer fix. Stand still for a moment.'.tr
                : _ring.isEmpty
                    ? 'Stand on the first corner of your farm, then tap the button.'.tr
                    : 'Walking to corner {n}. Stand where the boundary turns, then tap the button.'.trArgs({'n': next}));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
        child: Row(children: [
          _stat('${_ring.length}', 'corners marked'.tr),
          _stat(_whole.format(_walked), 'metres walked'.tr),
          _stat(back == null ? '–' : '${_whole.format(back)} m', 'back to start'.tr),
        ]),
      ),
      ?_problemNote(),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
        child: Text(note, style: Ledger.body.copyWith(fontSize: 14, height: 20 / 14, color: _gpsProblem != null ? Ledger.dangerInk : Ledger.inkMuted)),
      ),
      if (_gpsProblem != null)
        LedgerButton(label: 'Try again'.tr, kind: LedgerButtonKind.secondary, onPressed: _startGps)
      else
        LedgerButton(
          label: 'Mark corner {n} here'.trArgs({'n': next}),
          icon: const LineIcon(_Icons.pin, size: 20, color: Colors.white),
          onPressed: ready && _ring.length < maxCorners ? _markCorner : null,
        ),
      const SizedBox(height: 6),
      TextButton(
        onPressed: _ring.length >= 3 && _problem == null && !_saving ? _save : null,
        style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48), foregroundColor: Ledger.shambaInk),
        child: _saving
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Ledger.shamba))
            : Text('Finish: join back to the start'.tr, style: Ledger.link.copyWith(fontSize: 16, color: _ring.length >= 3 ? Ledger.shambaInk : Ledger.inkFaint)),
      ),
    ]);
  }

  // 5. Saved: the size, and whether weather and satellite data are on their way.
  Widget _savedSheet() {
    final saved = _saved ?? const {};
    final ha = double.tryParse('${saved['area_ha'] ?? ''}') ?? hectares(_ring);
    final sync = saved['weather_sync'] is Map ? saved['weather_sync'] as Map : const {};
    final (tagText, tagFg, tagBg, meta) = switch (sync['status']) {
      'registered' => ('Ready'.tr, Ledger.shambaInk, Ledger.shambaTint, 'For your exact land'.tr),
      'failed' || 'skipped' => ('Not yet'.tr, const Color(0xFF9A4A0B), const Color(0xFFF6E3CF), 'Using your county for now'.tr),
      _ => ('Setting up'.tr, const Color(0xFF1F5F82), const Color(0xFFDCEBF2), 'Usually ready in a few minutes'.tr),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text('Your farm is on the map'.tr, style: Ledger.title.copyWith(fontSize: 22, height: 28 / 22)),
      ),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: Ledger.rule, width: 1.5)),
        child: Column(children: [
          _savedRow('Size'.tr, '{n} corners'.trArgs({'n': _ring.length}),
              trailing: Text.rich(TextSpan(children: [
                TextSpan(text: _one.format(ha), style: const TextStyle(fontFamily: AppType.text, fontSize: 17, fontWeight: FontWeight.w700, color: Ledger.ink)),
                TextSpan(text: ' ha · ${_one.format(ha * 2.4710538)} ac', style: Ledger.caption),
              ]))),
          const Divider(height: 1, thickness: 1, color: Ledger.rule),
          _savedRow('Weather, soil and satellite'.tr, sync['scaled'] == true ? 'Small farms are read as 1 hectare for weather data'.tr : meta,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(999)),
                child: Text(tagText, style: Ledger.caption.copyWith(color: tagFg, fontWeight: FontWeight.w700)),
              )),
        ]),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
          flex: 10,
          child: LedgerButton(
            label: 'Edit'.tr,
            kind: LedgerButtonKind.secondary,
            icon: const LineIcon(_Icons.pen, size: 20),
            onPressed: () => _go(_Stage.draw),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(flex: 13, child: LedgerButton(label: 'Done'.tr, onPressed: () => Navigator.of(context).pop(true))),
      ]),
    ]);
  }

  Widget _savedRow(String title, String meta, {required Widget trailing}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Ledger.label),
              const SizedBox(height: 2),
              Text(meta, style: Ledger.caption),
            ]),
          ),
          const SizedBox(width: 12),
          trailing,
        ]),
      );

  Widget _failed() => ColoredBox(
        color: Ledger.paper,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('The map needs internet'.tr, style: Ledger.title, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Connect to mobile data or Wi-Fi, then open the map again.'.tr, style: Ledger.body, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              LedgerButton(label: 'Close'.tr, kind: LedgerButtonKind.secondary, onPressed: () => Navigator.of(context).pop(false)),
            ]),
          ),
        ),
      );
}

/// The map screens' line icons (Lucide, ISC licence).
class _Icons {
  static const locate = '<line x1="2" x2="5" y1="12" y2="12"/><line x1="19" x2="22" y1="12" y2="12"/><line x1="12" x2="12" y1="2" y2="5"/><line x1="12" x2="12" y1="19" y2="22"/><circle cx="12" cy="12" r="7"/><circle cx="12" cy="12" r="3"/>';
  static const undo = '<path d="M9 14 4 9l5-5"/><path d="M4 9h10.5a5.5 5.5 0 0 1 5.5 5.5a5.5 5.5 0 0 1-5.5 5.5H11"/>';
  static const trash = '<path d="M10 11v6"/><path d="M14 11v6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6"/><path d="M3 6h18"/><path d="M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>';
  static const pen = '<path d="M13 21h8"/><path d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z"/>';
  static const footprints = '<path d="M4 16v-2.38C4 11.5 2.97 10.5 3 8c.03-2.72 1.49-6 4.5-6C9.37 2 10 3.8 10 5.5c0 3.11-2 5.66-2 8.68V16a2 2 0 1 1-4 0Z"/><path d="M20 20v-2.38c0-2.12 1.03-3.12 1-5.62-.03-2.72-1.49-6-4.5-6C14.63 6 14 7.8 14 9.5c0 3.11 2 5.66 2 8.68V20a2 2 0 1 0 4 0Z"/><path d="M16 17h4"/><path d="M4 13h4"/>';
  static const chevronRight = '<path d="m9 18 6-6-6-6"/>';
  static const pin = '<path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0"/><circle cx="12" cy="10" r="3"/>';
  static const alert = '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"/><path d="M12 9v4"/><path d="M12 17h.01"/>';
}

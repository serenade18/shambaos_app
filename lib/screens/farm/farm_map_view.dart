import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/api_service.dart';
import 'boundary_geo.dart';

/// What the map tells the app.
sealed class MapEvent {}

/// A tap on the ground, where a corner should go.
class MapTap extends MapEvent {
  final LngLat point;
  MapTap(this.point);
}

/// A corner dragged to a new place.
class MapMove extends MapEvent {
  final int index;
  final LngLat point;
  MapMove(this.index, this.point);
}

/// The map could not start (no internet for the map library).
class MapFailed extends MapEvent {}

/// Drives the Cesium page in assets/map/farm_map.html. Calls made before the
/// page is ready wait for it.
class FarmMapController {
  WebViewController? _web;
  final _ready = <String>[];
  bool _isReady = false;

  void _attach(WebViewController web) => _web = web;

  void _onReady() {
    _isReady = true;
    for (final js in _ready) {
      _web?.runJavaScript(js);
    }
    _ready.clear();
  }

  void _call(String js) {
    if (_isReady) {
      _web?.runJavaScript(js);
    } else {
      _ready.add(js);
    }
  }

  static List<List<double>> _points(List<LngLat> ring) => [for (final p in ring) [p.$1, p.$2]];

  /// Where to look first, and the ion token for 3D terrain ('' for none).
  void init({required String token, LngLat? center, List<LngLat> ring = const []}) => _call(
      'window.shamba.init(${jsonEncode({'token': token, 'center': center == null ? null : [center.$1, center.$2], 'ring': _points(ring)})})');

  /// The boundary and how to draw it.
  void setRing(List<LngLat> ring, {bool closed = false, bool editable = false, int? active, (int, int)? bad}) =>
      _call('window.shamba.setRing(${jsonEncode({
        'ring': _points(ring),
        'closed': closed,
        'editable': editable,
        'active': active,
        'bad': bad == null ? null : [bad.$1, bad.$2],
      })})');

  void showMe(LngLat p, double accuracy) => _call('window.shamba.showMe(${p.$1}, ${p.$2}, $accuracy)');
  void hideMe() => _call('window.shamba.hideMe()');
  void lookAt(LngLat p) => _call('window.shamba.lookAt(${p.$1}, ${p.$2})');
  void fit() => _call('window.shamba.fit()');
}

/// The Cesium globe, full size. Where there is no web view (widget tests) it
/// shows the ground colour instead.
class FarmMapView extends StatefulWidget {
  final FarmMapController controller;
  final ValueChanged<MapEvent> onEvent;
  const FarmMapView({super.key, required this.controller, required this.onEvent});

  @override
  State<FarmMapView> createState() => _FarmMapViewState();
}

class _FarmMapViewState extends State<FarmMapView> {
  WebViewController? _web;

  @override
  void initState() {
    super.initState();
    if (WebViewPlatform.instance == null) return;
    final web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFB9C7A8))
      ..addJavaScriptChannel('Shamba', onMessageReceived: _onMessage)
      ..setNavigationDelegate(NavigationDelegate(
        onWebResourceError: (e) {
          if (e.isForMainFrame ?? false) widget.onEvent(MapFailed());
        },
      ));
    widget.controller._attach(web);
    _web = web;
    _load(web);
  }

  Future<void> _load(WebViewController web) async {
    final html = await rootBundle.loadString('assets/map/farm_map.html');
    // The page's origin is the API's, so a Cesium ion token restricted to
    // that domain works here as it does in the portal.
    await web.loadHtmlString(html, baseUrl: Uri.parse(ApiService.baseUrl).replace(path: '/').toString());
  }

  void _onMessage(JavaScriptMessage message) {
    final m = jsonDecode(message.message);
    if (m is! Map) return;
    switch (m['type']) {
      case 'ready':
        widget.controller._onReady();
      case 'tap':
        widget.onEvent(MapTap(((m['lng'] as num).toDouble(), (m['lat'] as num).toDouble())));
      case 'move':
        widget.onEvent(MapMove(m['index'] as int, ((m['lng'] as num).toDouble(), (m['lat'] as num).toDouble())));
      case 'error':
        widget.onEvent(MapFailed());
    }
  }

  @override
  Widget build(BuildContext context) {
    final web = _web;
    if (web == null) return const ColoredBox(color: Color(0xFFB9C7A8));
    return WebViewWidget(controller: web);
  }
}

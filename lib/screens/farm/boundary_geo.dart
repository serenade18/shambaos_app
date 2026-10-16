import 'dart:math' as math;

/// Farm boundary geometry on the phone, matching apps/farms/geometry.py on the
/// server (and the portal's geo.ts) so the map can warn before saving.
/// Points are (lng, lat), GeoJSON order; rings here are open (the first
/// point is not repeated).
typedef LngLat = (double, double);

const _earthRadiusM = 6378137.0;
const _m2PerAcre = 4046.8564224;
const maxFarmHa = 3000.0;
const maxCorners = 200;

double _rad(double d) => d * math.pi / 180;

/// Spherical area in square metres (the formula turf.js uses).
double areaM2(List<LngLat> ring) {
  if (ring.length < 3) return 0;
  var total = 0.0;
  for (var i = 0; i < ring.length; i++) {
    final (lng1, lat1) = ring[i];
    final (lng2, lat2) = ring[(i + 1) % ring.length];
    total += _rad(lng2 - lng1) * (2 + math.sin(_rad(lat1)) + math.sin(_rad(lat2)));
  }
  return total.abs() * _earthRadiusM * _earthRadiusM / 2;
}

double hectares(List<LngLat> ring) => areaM2(ring) / 10000;
double acres(List<LngLat> ring) => areaM2(ring) / _m2PerAcre;

/// Metres between two points on the ground (haversine).
double metresBetween(LngLat a, LngLat b) {
  final dLat = _rad(b.$2 - a.$2), dLng = _rad(b.$1 - a.$1);
  final h = math.pow(math.sin(dLat / 2), 2) + math.cos(_rad(a.$2)) * math.cos(_rad(b.$2)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusM * math.asin(math.sqrt(h));
}

double _orient(LngLat a, LngLat b, LngLat c) => (b.$1 - a.$1) * (c.$2 - a.$2) - (b.$2 - a.$2) * (c.$1 - a.$1);

bool _within(LngLat a, LngLat b, LngLat c) =>
    math.min(a.$1, b.$1) <= c.$1 && c.$1 <= math.max(a.$1, b.$1) && math.min(a.$2, b.$2) <= c.$2 && c.$2 <= math.max(a.$2, b.$2);

bool _meet(LngLat p1, LngLat p2, LngLat q1, LngLat q2) {
  final d1 = _orient(q1, q2, p1), d2 = _orient(q1, q2, p2), d3 = _orient(p1, p2, q1), d4 = _orient(p1, p2, q2);
  if (d1 != 0 && d2 != 0 && d3 != 0 && d4 != 0 && (d1 > 0) != (d2 > 0) && (d3 > 0) != (d4 > 0)) return true;
  return (d1 == 0 && _within(q1, q2, p1)) || (d2 == 0 && _within(q1, q2, p2)) || (d3 == 0 && _within(p1, p2, q1)) || (d4 == 0 && _within(p1, p2, q2));
}

/// The two edges (by their first corner's index) that touch though they are
/// not neighbours, or null: the farmer went round out of order.
(int, int)? crossing(List<LngLat> ring) {
  final n = ring.length;
  if (n < 4) return null;
  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      if (j == i + 1 || (i == 0 && j == n - 1)) continue;
      if (_meet(ring[i], ring[(i + 1) % n], ring[j], ring[(j + 1) % n])) return (i, j);
    }
  }
  return null;
}

enum BoundaryProblem { few, crosses, big, many }

/// What stops this ring being saved, if anything. An empty ring is fine (no boundary).
BoundaryProblem? boundaryProblem(List<LngLat> ring) {
  if (ring.isEmpty) return null;
  // Crossing first: a bow tie's two halves cancel out to almost no area.
  if (crossing(ring) != null) return BoundaryProblem.crosses;
  if (ring.length < 3 || areaM2(ring) < 1) return BoundaryProblem.few;
  if (ring.length > maxCorners) return BoundaryProblem.many;
  if (hectares(ring) > maxFarmHa) return BoundaryProblem.big;
  return null;
}

double _round6(double v) => (v * 1e6).roundToDouble() / 1e6;

/// GeoJSON for the API: the ring closed, or null for no boundary.
Map<String, dynamic>? toPolygon(List<LngLat> ring) => ring.length < 3
    ? null
    : {
        'type': 'Polygon',
        'coordinates': [
          [for (final p in [...ring, ring.first]) [_round6(p.$1), _round6(p.$2)]],
        ],
      };

/// The open ring back from the API's GeoJSON.
List<LngLat> fromPolygon(Object? polygon) {
  if (polygon is! Map || polygon['coordinates'] is! List || (polygon['coordinates'] as List).isEmpty) return [];
  final ring = [
    for (final p in (polygon['coordinates'] as List).first as List) ((p[0] as num).toDouble(), (p[1] as num).toDouble()),
  ];
  return ring.length > 1 && ring.first == ring.last ? ring.sublist(0, ring.length - 1) : ring;
}

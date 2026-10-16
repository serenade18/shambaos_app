import 'package:flutter_test/flutter_test.dart';
import 'package:shambaOS/screens/farm/boundary_geo.dart';

void main() {
  // About 100 m by 100 m near Nyeri: one hectare, give or take.
  const square = <LngLat>[(36.9500, -0.4200), (36.9509, -0.4200), (36.9509, -0.4209), (36.9500, -0.4209)];

  test('area of a square of about 100 m', () {
    expect(hectares(square), closeTo(1.0, 0.02));
    expect(acres(square), closeTo(hectares(square) * 2.4711, 0.01));
  });

  test('a ring that goes round in order is fine', () {
    expect(boundaryProblem(square), isNull);
    expect(boundaryProblem(const []), isNull);
  });

  test('two corners swapped make the boundary cross itself', () {
    final bowTie = [square[0], square[2], square[1], square[3]];
    expect(crossing(bowTie), isNotNull);
    expect(boundaryProblem(bowTie), BoundaryProblem.crosses);
  });

  test('fewer than three corners is too few', () {
    expect(boundaryProblem(square.sublist(0, 2)), BoundaryProblem.few);
  });

  test('bigger than 3,000 hectares is too big', () {
    const huge = <LngLat>[(36.0, 0.0), (36.6, 0.0), (36.6, -0.6), (36.0, -0.6)];
    expect(boundaryProblem(huge), BoundaryProblem.big);
  });

  test('GeoJSON round trip closes and reopens the ring', () {
    final polygon = toPolygon(square)!;
    final coords = (polygon['coordinates'] as List).first as List;
    expect(coords.length, 5);
    expect(coords.first, coords.last);
    expect(fromPolygon(polygon), square);
    expect(toPolygon(square.sublist(0, 2)), isNull);
  });

  test('metres between two points', () {
    expect(metresBetween(square[0], square[1]), closeTo(100, 1));
  });
}

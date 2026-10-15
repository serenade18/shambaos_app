/// A farm, as the weather widget needs it: from GET /farms.
class AgroPolygon {
  final String id;
  final String name;
  final List<double> center; // GeoJSON order: [lng, lat]; empty if the farm has no location

  AgroPolygon({
    required this.id,
    required this.name,
    required this.center,
  });

  factory AgroPolygon.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    return AgroPolygon(
      id: json['id'],
      name: json['name'],
      center: location is Map
          ? [(location['lng'] as num).toDouble(), (location['lat'] as num).toDouble()]
          : const [],
    );
  }
}

class AgroPolygon {
  final String id;
  final String name;
  final List<double> center;

  AgroPolygon({
    required this.id,
    required this.name,
    required this.center,
  });

  factory AgroPolygon.fromJson(Map<String, dynamic> json) {
    return AgroPolygon(
      id: json['id'],
      name: json['name'],
      center: List<double>.from(json['center']),
    );
  }
}
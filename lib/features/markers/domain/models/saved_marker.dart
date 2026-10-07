import 'package:latlong2/latlong.dart';

class SavedMarker {
  final String id;
  final String title;
  final LatLng position;

  SavedMarker({
    required this.id,
    required this.title,
    required this.position,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lat': position.latitude,
      'lng': position.longitude,
    };
  }

  factory SavedMarker.fromJson(Map<String, dynamic> json) {
    return SavedMarker(
      id: json['id'] as String? ??
          'marker_${DateTime.now().microsecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Точка на карте',
      position: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
    );
  }
}

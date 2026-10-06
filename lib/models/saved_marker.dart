import 'package:latlong2/latlong.dart';

class SavedMarker {
  final String id;
  final String title;
  final LatLng position;
  final DateTime createdAt;

  SavedMarker({
    required this.id,
    required this.title,
    required this.position,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lat': position.latitude,
      'lng': position.longitude,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavedMarker.fromJson(Map<String, dynamic> json) {
    return SavedMarker(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? 'Точка на карте',
      position: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

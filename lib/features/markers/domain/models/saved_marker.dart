import 'package:latlong2/latlong.dart';

class SavedMarker {
  final String id;
  final String title;
  final LatLng position;
  final String? address;
  final String? description;

  SavedMarker({
    required this.id,
    required this.title,
    required this.position,
    this.address,
    this.description,
  });

  SavedMarker copyWith({
    String? id,
    String? title,
    LatLng? position,
    String? address,
    String? description,
  }) {
    return SavedMarker(
      id: id ?? this.id,
      title: title ?? this.title,
      position: position ?? this.position,
      address: address ?? this.address,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lat': position.latitude,
      'lng': position.longitude,
      if (address != null) 'address': address,
      if (description != null) 'description': description,
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
      address: json['address'] as String?,
      description: json['description'] as String?,
    );
  }
}

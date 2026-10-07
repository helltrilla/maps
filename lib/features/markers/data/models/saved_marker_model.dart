import 'package:latlong2/latlong.dart';
import '../../domain/entities/saved_marker.dart';

class SavedMarkerModel extends SavedMarker {
  const SavedMarkerModel({
    required super.id,
    required super.title,
    required super.position,
    super.address,
    super.description,
  });

  factory SavedMarkerModel.fromEntity(SavedMarker entity) {
    return SavedMarkerModel(
      id: entity.id,
      title: entity.title,
      position: entity.position,
      address: entity.address,
      description: entity.description,
    );
  }

  factory SavedMarkerModel.fromJson(Map<String, dynamic> json) {
    return SavedMarkerModel(
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
}

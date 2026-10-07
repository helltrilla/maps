import 'package:latlong2/latlong.dart';

class SavedMarker {
  final String id;
  final String title;
  final LatLng position;
  final String? address;
  final String? description;

  const SavedMarker({
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
}

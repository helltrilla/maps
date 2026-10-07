import 'package:latlong2/latlong.dart';

class ReverseGeocodeResult {
  final String street;
  final String fullAddress;
  final LatLng position;

  const ReverseGeocodeResult({
    required this.street,
    required this.fullAddress,
    required this.position,
  });

  @override
  String toString() =>
      'ReverseGeocodeResult(street: $street, fullAddress: $fullAddress, position: $position)';
}

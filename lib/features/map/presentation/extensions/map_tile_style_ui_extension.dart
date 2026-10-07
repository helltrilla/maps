import 'package:flutter/material.dart';
import '../../domain/entities/map_tile_style.dart';

extension MapTileStyleUiExtension on MapTileStyle {
  IconData get icon {
    switch (type) {
      case MapTileType.openStreetMap:
        return Icons.map_rounded;
      case MapTileType.satellite:
        return Icons.satellite_alt_rounded;
      case MapTileType.cyclosm:
        return Icons.directions_bike_rounded;
      case MapTileType.openTopoMap:
        return Icons.terrain_rounded;
      case MapTileType.esriDarkGray:
        return Icons.dark_mode_rounded;
    }
  }
}

import 'package:flutter/material.dart';

enum MapTileType {
  openStreetMap,
  openTopoMap,
  satellite,
  cyclosm,
}

class MapTileStyle {
  final MapTileType type;
  final String title;
  final String description;
  final String urlTemplate;
  final List<String> subdomains;
  final int maxZoom;
  final IconData icon;

  const MapTileStyle({
    required this.type,
    required this.title,
    required this.description,
    required this.urlTemplate,
    this.subdomains = const [],
    this.maxZoom = 19,
    required this.icon,
  });

  static const List<MapTileStyle> availableStyles = [
    MapTileStyle(
      type: MapTileType.openStreetMap,
      title: 'Стандарт (OSM)',
      description: 'Классическая подробная карта улиц',
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      subdomains: [],
      maxZoom: 19,
      icon: Icons.map_rounded,
    ),
    MapTileStyle(
      type: MapTileType.openTopoMap,
      title: 'Топографическая',
      description: 'Рельеф, высоты и природные объекты',
      urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
      subdomains: ['a', 'b', 'c'],
      maxZoom: 17,
      icon: Icons.terrain_rounded,
    ),
    MapTileStyle(
      type: MapTileType.satellite,
      title: 'Спутник (Esri)',
      description: 'Высокодетализированные спутниковые снимки',
      urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      subdomains: [],
      maxZoom: 19,
      icon: Icons.satellite_alt_rounded,
    ),
    MapTileStyle(
      type: MapTileType.cyclosm,
      title: 'Городская / Вело (CyclOSM)',
      description: 'Четкие дорожки, маршруты и ориентиры',
      urlTemplate: 'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
      subdomains: ['a', 'b', 'c'],
      maxZoom: 18,
      icon: Icons.directions_bike_rounded,
    ),
  ];
}

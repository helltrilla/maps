import 'package:flutter/material.dart';

enum MapTileType {
  openStreetMap,
  satellite,
  cyclosm,
  openTopoMap,
  esriDarkGray,
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

  int get maxNativeZoom => maxZoom;

  static const List<MapTileStyle> availableStyles = [
    MapTileStyle(
      type: MapTileType.openStreetMap,
      title: 'Классика (OSM)',
      description: 'Детальные улицы, дома, номера и пешеходные зоны',
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      subdomains: [],
      maxZoom: 19,
      icon: Icons.map_rounded,
    ),
    MapTileStyle(
      type: MapTileType.satellite,
      title: 'Спутник (Esri World)',
      description: 'Высокодетализированные спутниковые снимки местности',
      urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      subdomains: [],
      maxZoom: 19,
      icon: Icons.satellite_alt_rounded,
    ),
    MapTileStyle(
      type: MapTileType.cyclosm,
      title: 'Городская / Навигация (CyclOSM)',
      description: 'Улицы, велодорожки, парки и четкие ориентиры',
      urlTemplate: 'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
      subdomains: ['a', 'b', 'c'],
      maxZoom: 18,
      icon: Icons.directions_bike_rounded,
    ),
    MapTileStyle(
      type: MapTileType.openTopoMap,
      title: 'Топографическая',
      description: 'Рельеф, перепады высот и природные тропы',
      urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
      subdomains: ['a', 'b', 'c'],
      maxZoom: 17,
      icon: Icons.terrain_rounded,
    ),
    MapTileStyle(
      type: MapTileType.esriDarkGray,
      title: 'Ночная (Dark Gray)',
      description: 'Контрастный темный режим для ночи',
      urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
      subdomains: [],
      maxZoom: 16,
      icon: Icons.dark_mode_rounded,
    ),
  ];
}

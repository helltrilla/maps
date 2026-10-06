import 'package:flutter/material.dart';

enum MapTileType {
  esriDarkGray,
  satellite,
  openStreetMap,
  openTopoMap,
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
      type: MapTileType.esriDarkGray,
      title: 'Тёмный Неон (Dark Gray)',
      description: 'Премиальный глубокий ночной стиль',
      urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
      subdomains: [],
      maxZoom: 16,
      icon: Icons.dark_mode_rounded,
    ),
    MapTileStyle(
      type: MapTileType.satellite,
      title: 'Спутник (Esri World)',
      description: 'Высокодетализированные спутниковые снимки',
      urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      subdomains: [],
      maxZoom: 19,
      icon: Icons.satellite_alt_rounded,
    ),
    MapTileStyle(
      type: MapTileType.openStreetMap,
      title: 'Классика (OSM)',
      description: 'Базовая подробная открытая карта улиц',
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      subdomains: [],
      maxZoom: 19,
      icon: Icons.map_rounded,
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
  ];
}

import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';

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
  final String attribution;

  const MapTileStyle({
    required this.type,
    required this.title,
    required this.description,
    required this.urlTemplate,
    this.subdomains = const [],
    this.maxZoom = 19,
    required this.icon,
    required this.attribution,
  });

  int get maxNativeZoom => maxZoom;

  static const List<MapTileStyle> availableStyles = [
    MapTileStyle(
      type: MapTileType.openStreetMap,
      title: 'Классика (OSM)',
      description: 'Детальные улицы, дома, номера и пешеходные зоны',
      urlTemplate: AppConfig.osmTileUrl,
      subdomains: [],
      maxZoom: 19,
      icon: Icons.map_rounded,
      attribution: '© OpenStreetMap contributors',
    ),
    MapTileStyle(
      type: MapTileType.satellite,
      title: 'Спутник (Esri World)',
      description: 'Высокодетализированные спутниковые снимки местности',
      urlTemplate: AppConfig.esriSatelliteTileUrl,
      subdomains: [],
      maxZoom: 19,
      icon: Icons.satellite_alt_rounded,
      attribution: 'Tiles © Esri — Source: Esri, Maxar, Earthstar Geographics',
    ),
    MapTileStyle(
      type: MapTileType.cyclosm,
      title: 'Городская / Навигация (CyclOSM)',
      description: 'Улицы, велодорожки, парки и четкие ориентиры',
      urlTemplate: AppConfig.cyclosmTileUrl,
      subdomains: ['a', 'b', 'c'],
      maxZoom: 18,
      icon: Icons.directions_bike_rounded,
      attribution: '© OpenStreetMap contributors. Tiles courtesy of CyclOSM',
    ),
    MapTileStyle(
      type: MapTileType.openTopoMap,
      title: 'Топографическая',
      description: 'Рельеф, перепады высот и природные тропы',
      urlTemplate: AppConfig.openTopoTileUrl,
      subdomains: ['a', 'b', 'c'],
      maxZoom: 17,
      icon: Icons.terrain_rounded,
      attribution:
          'Map data: © OpenStreetMap contributors, SRTM | Map style: © OpenTopoMap (CC-BY-SA)',
    ),
    MapTileStyle(
      type: MapTileType.esriDarkGray,
      title: 'Ночная (Dark Gray)',
      description: 'Контрастный темный режим для ночи',
      urlTemplate: AppConfig.esriDarkTileUrl,
      subdomains: [],
      maxZoom: 16,
      icon: Icons.dark_mode_rounded,
      attribution: 'Tiles © Esri — Esri, DeLorme, NAVTEQ',
    ),
  ];
}

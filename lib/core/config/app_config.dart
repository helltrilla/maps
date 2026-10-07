/// Конфигурация внешних провайдеров и сервисов приложения.
/// Все значения имеют рабочие дефолты и могут быть переопределены
/// через флаг `--dart-define` при сборке (`flutter build` / `flutter run`).
class AppConfig {
  const AppConfig._();

  /// Имя приложения
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Maps',
  );

  /// User-Agent для HTTP-запросов (OSRM, Overpass, Photon, Nominatim)
  static const String appUserAgent = String.fromEnvironment(
    'APP_USER_AGENT',
    defaultValue:
        'MapsFlutterApp/1.0 (iOS/Android; Mobile; +https://github.com/helltrilla/maps)',
  );

  /// Package name для идентификации тайловых запросов в соответствии с OSM Tile Policy
  static const String userAgentPackageName = String.fromEnvironment(
    'USER_AGENT_PACKAGE_NAME',
    defaultValue: 'com.helltrilla.maps',
  );

  /// Базовый URL сервера OSRM (маршрутизация)
  static const String osrmBaseUrl = String.fromEnvironment(
    'OSRM_BASE_URL',
    defaultValue: 'https://router.project-osrm.org/route/v1/driving',
  );

  /// Базовый URL сервиса Photon (геопоиск мест и адресов)
  static const String photonBaseUrl = String.fromEnvironment(
    'PHOTON_BASE_URL',
    defaultValue: 'https://photon.komoot.io/api',
  );

  /// Базовый URL сервиса Nominatim (резервный геопоиск)
  static const String nominatimBaseUrl = String.fromEnvironment(
    'NOMINATIM_BASE_URL',
    defaultValue: 'https://nominatim.openstreetmap.org',
  );

  /// Зеркала Overpass API, разделенные запятыми
  static const String _overpassMirrorsRaw = String.fromEnvironment(
    'OVERPASS_MIRRORS',
    defaultValue:
        'https://lz4.overpass-api.de/api/interpreter,https://overpass-api.de/api/interpreter,https://z.overpass-api.de/api/interpreter',
  );

  /// Список активных зеркал Overpass API с автоматическим переключением при сбоях
  static List<String> get overpassMirrors => _overpassMirrorsRaw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  /// Шаблон URL тайлов OpenStreetMap (Standard)
  static const String osmTileUrl = String.fromEnvironment(
    'OSM_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  /// Шаблон URL спутниковых тайлов Esri World Imagery
  static const String esriSatelliteTileUrl = String.fromEnvironment(
    'ESRI_SATELLITE_TILE_URL',
    defaultValue:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
  );

  /// Шаблон URL тайлов CyclOSM
  static const String cyclosmTileUrl = String.fromEnvironment(
    'CYCLOSM_TILE_URL',
    defaultValue:
        'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
  );

  /// Шаблон URL тайлов OpenTopoMap
  static const String openTopoTileUrl = String.fromEnvironment(
    'OPENTOPO_TILE_URL',
    defaultValue: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
  );

  /// Шаблон URL ночных тайлов Esri Dark Gray
  static const String esriDarkTileUrl = String.fromEnvironment(
    'ESRI_DARK_TILE_URL',
    defaultValue:
        'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
  );
}

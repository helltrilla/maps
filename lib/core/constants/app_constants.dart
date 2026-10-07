import 'package:latlong2/latlong.dart';

import '../config/app_config.dart';

class AppConstants {
  static const String appName = AppConfig.appName;
  static const String appUserAgent = AppConfig.appUserAgent;
  static const String userAgentPackageName = AppConfig.userAgentPackageName;

  // Default coordinate (Kaliningrad)
  static const LatLng defaultLocation = LatLng(54.7104, 20.4522);
  static const double defaultZoom = 14.5;
  static const double minZoom = 3.0;
  static const double maxZoom = 21.0;
  static const double tileLayerMaxZoom = 22.0;

  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 10);
  static const Duration osrmTimeout = Duration(seconds: 15);
  static const Duration overpassTimeout = Duration(seconds: 8);
  static const Duration searchDebounce = Duration(milliseconds: 350);

  // Storage keys
  static const String savedMarkersKey = 'saved_markers_v2';
  static const String legacyMarkersKey = 'saved_markers';
}

import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../markers/domain/models/saved_marker.dart';
import '../../../places/domain/models/place.dart';
import '../../../routing/domain/models/route_info.dart';
import '../../domain/models/map_tile_style.dart';
import 'map_marker_widgets.dart';

class MapLayersView extends StatelessWidget {
  final MapController mapController;
  final CacheStore cacheStore;
  final MapTileStyle tileStyle;
  final LatLng? userLocation;
  final double userHeading;
  final double userSpeed;
  final List<SavedMarker> savedMarkers;
  final List<Place> nearbyPlaces;
  final RouteInfo? currentRoute;
  final void Function(TapPosition tapPosition, LatLng point) onTap;
  final void Function(MapCamera camera, bool hasGesture) onPositionChanged;
  final void Function(SavedMarker marker) onMarkerTap;
  final void Function(Place place) onPlaceTap;

  const MapLayersView({
    super.key,
    required this.mapController,
    required this.cacheStore,
    required this.tileStyle,
    required this.userLocation,
    required this.userHeading,
    required this.userSpeed,
    required this.savedMarkers,
    required this.nearbyPlaces,
    required this.currentRoute,
    required this.onTap,
    required this.onPositionChanged,
    required this.onMarkerTap,
    required this.onPlaceTap,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        backgroundColor: AppTheme.background,
        initialCenter: AppConstants.defaultLocation,
        initialZoom: AppConstants.defaultZoom,
        minZoom: AppConstants.minZoom,
        maxZoom: AppConstants.maxZoom,
        onTap: onTap,
        onPositionChanged: onPositionChanged,
        cameraConstraint: const CameraConstraint.containLatitude(),
      ),
      children: [
        // 1. Тайлы карты (с кешем и глубоким зумом)
        TileLayer(
          key: ValueKey(tileStyle.type),
          urlTemplate: tileStyle.urlTemplate,
          subdomains: tileStyle.subdomains,
          keepBuffer: 6,
          panBuffer: 2,
          maxNativeZoom: tileStyle.maxNativeZoom,
          maxZoom: AppConstants.tileLayerMaxZoom,
          tileDisplay: const TileDisplay.fadeIn(),
          userAgentPackageName: AppConstants.userAgentPackageName,
          tileProvider: CachedTileProvider(
            store: cacheStore,
            maxStale: const Duration(days: 30),
            hitCacheOnNetworkFailure: true,
          ),
        ),

        // 2. Линия маршрута
        if (currentRoute != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: currentRoute!.points,
                strokeWidth: 7.0,
                color: const Color(0xFF1E3A8A),
              ),
              Polyline(
                points: currentRoute!.points,
                strokeWidth: 4.5,
                color: AppTheme.accent,
              ),
            ],
          ),

        // 3. Маркеры
        MarkerLayer(
          markers: [
            if (userLocation != null)
              MapMarkerWidgets.buildUserLocationMarker(
                userLocation!,
                heading: userHeading,
                speed: userSpeed,
              ),
            ...savedMarkers.map(
              (m) => MapMarkerWidgets.buildSavedMarker(
                position: m.position,
                title: m.title,
                onTap: () => onMarkerTap(m),
                onLongPress: () => onMarkerTap(m),
              ),
            ),
            ...nearbyPlaces.map(
              (place) => MapMarkerWidgets.buildPlaceMarker(
                position: place.position,
                icon: place.icon,
                color: place.color,
                onTap: () => onPlaceTap(place),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

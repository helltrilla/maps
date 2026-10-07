import 'dart:io';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_cache_file_store/http_cache_file_store.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

import 'core/constants/app_constants.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/map/presentation/controllers/map_state_controller.dart';
import 'features/map/presentation/widgets/layer_switcher_dialog.dart';
import 'features/map/presentation/widgets/map_controls_column.dart';
import 'features/map/presentation/widgets/map_layers_view.dart';
import 'features/map/presentation/widgets/point_picker_overlay.dart';
import 'features/markers/domain/models/saved_marker.dart';
import 'features/markers/presentation/controllers/markers_controller.dart';
import 'features/places/domain/models/place.dart';
import 'features/places/presentation/controllers/places_controller.dart';
import 'features/places/presentation/widgets/bottom_panel.dart';
import 'features/places/presentation/widgets/place_details_sheet.dart';
import 'features/routing/presentation/controllers/routing_controller.dart';
import 'features/routing/presentation/widgets/route_header_card.dart';
import 'features/routing/presentation/widgets/route_planner_sheet.dart';
import 'features/search/presentation/controllers/search_controller.dart';
import 'features/search/presentation/widgets/search_bar_widget.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final MapController _mapController = MapController();
  final GlobalKey<FloatingSearchBarState> _searchBarKey =
      GlobalKey<FloatingSearchBarState>();
  late final Future<CacheStore> _cacheStoreFuture;

  RoutePointItem? _savedPlannerStart;
  RoutePointItem? _savedPlannerEnd;

  @override
  void initState() {
    super.initState();
    _cacheStoreFuture = _getCacheStore();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  static Future<CacheStore> _getCacheStore() async {
    final directory = await getApplicationSupportDirectory();
    final cacheDirectory = Directory('${directory.path}/map_tiles');
    if (!await cacheDirectory.exists()) {
      await cacheDirectory.create(recursive: true);
    }
    return FileCacheStore(cacheDirectory.path);
  }

  void _initData() {
    final locState = ref.read(userLocationControllerProvider);
    final pos = locState.location ?? AppConstants.defaultLocation;
    ref.read(placesControllerProvider.notifier).loadNearbyPlaces(pos);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _zoom(bool zoomIn) {
    final double currentZoom = _mapController.camera.zoom;
    final LatLng currentCenter = _mapController.camera.center;
    final double newZoom = (zoomIn ? currentZoom + 1 : currentZoom - 1).clamp(
      AppConstants.minZoom,
      AppConstants.maxZoom,
    );
    _mapController.move(currentCenter, newZoom);
  }

  void _onMyLocationPressed() {
    HapticFeedback.lightImpact();
    ref.read(userLocationControllerProvider.notifier).setFollowingUser(true);
    final loc = ref.read(userLocationControllerProvider).location;
    if (loc != null) {
      _mapController.move(loc, 16);
    }
  }

  Future<void> _handleMapTap(LatLng position) async {
    FocusScope.of(context).unfocus();
    final isSearchOpen = ref.read(searchControllerProvider).isSearchOpen;
    if (isSearchOpen) {
      _searchBarKey.currentState?.closeSearch();
      ref.read(searchControllerProvider.notifier).setSearchOpen(false);
      return;
    }

    final isPicking = ref.read(routingControllerProvider).isPickingPointOnMap;
    if (isPicking) {
      _mapController.move(position, _mapController.camera.zoom);
      return;
    }

    final newMarker = SavedMarker(
      id: UniqueKey().toString(),
      title:
          'Метка (${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)})',
      position: position,
    );
    await ref.read(markersControllerProvider.notifier).addMarker(newMarker);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.pointAdded}: ${newMarker.title}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showLayerSwitcher() {
    final currentStyle = ref.read(selectedTileStyleProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LayerSwitcherModal(
        currentType: currentStyle.type,
        onStyleSelected: (newStyle) {
          ref.read(selectedTileStyleProvider.notifier).state = newStyle;
        },
      ),
    );
  }

  void _openMarkerDetails(SavedMarker marker) {
    final place = Place(
      id: marker.id,
      name: marker.title,
      position: marker.position,
      type: 'точка',
      address:
          '${marker.position.latitude.toStringAsFixed(5)}, ${marker.position.longitude.toStringAsFixed(5)}',
    );
    _openPlaceDetails(place);
  }

  void _openPlaceDetails(Place place) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PlaceDetailsSheet(
        place: place,
        onBuildRoute: () {
          Navigator.of(ctx).pop();
          _openRoutePlannerSheet(preselectedDestination: place);
        },
      ),
    );
  }

  void _openRoutePlannerSheet({Place? preselectedDestination}) {
    final locState = ref.read(userLocationControllerProvider);
    final markers = ref.read(markersControllerProvider);
    final places = ref.read(placesControllerProvider).places;

    RoutePointItem? destItem = _savedPlannerEnd;
    if (preselectedDestination != null) {
      destItem = RoutePointItem(
        id: preselectedDestination.id,
        title: preselectedDestination.name,
        position: preselectedDestination.position,
        icon: Icons.place_rounded,
        iconColor: AppTheme.primary,
      );
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RoutePlannerSheet(
        userLocation: locState.location,
        savedMarkers: markers,
        nearbyPlaces: places,
        initialStart: _savedPlannerStart,
        initialDestination: destItem,
        onPickOnMap: (forStart, currentStart, currentEnd) {
          _savedPlannerStart = currentStart;
          _savedPlannerEnd = currentEnd;
          ref
              .read(routingControllerProvider.notifier)
              .startPickingPoint(forStart: forStart);
        },
        onBuildRoute: (startPos, startName, endPos, endName) {
          ref.read(routingControllerProvider.notifier).clearRoute();
          ref.read(routingControllerProvider.notifier).buildRoute(
                start: startPos,
                destination: endPos,
                startName: startName,
                destinationName: endName,
              );
          _mapController.move(startPos, 14);
        },
      ),
    );
  }

  void _confirmPickedPoint() {
    final center = _mapController.camera.center;
    final forStart = ref.read(routingControllerProvider).pickingForStart;
    final pickedItem = RoutePointItem(
      id: 'picked_${DateTime.now().millisecondsSinceEpoch}',
      title: AppStrings.pickedPoint,
      position: center,
      icon: Icons.place_rounded,
      iconColor: AppTheme.accent,
    );

    if (forStart) {
      _savedPlannerStart = pickedItem;
    } else {
      _savedPlannerEnd = pickedItem;
    }

    ref.read(routingControllerProvider.notifier).stopPickingPoint();
    _openRoutePlannerSheet();
  }

  @override
  Widget build(BuildContext context) {
    final tileStyle = ref.watch(selectedTileStyleProvider);
    final userLoc = ref.watch(userLocationControllerProvider);
    final savedMarkers = ref.watch(markersControllerProvider);
    final placesState = ref.watch(placesControllerProvider);
    final routingState = ref.watch(routingControllerProvider);
    final searchState = ref.watch(searchControllerProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Основная карта с тайлами, маршрутом и маркерами
          FutureBuilder<CacheStore>(
            future: _cacheStoreFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('${AppStrings.cacheErrorPrefix}${snapshot.error}',
                      style: const TextStyle(color: Colors.white70)),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                );
              }
              return MapLayersView(
                mapController: _mapController,
                cacheStore: snapshot.data!,
                tileStyle: tileStyle,
                userLocation: userLoc.location,
                userHeading: userLoc.heading,
                userSpeed: userLoc.speed,
                savedMarkers: savedMarkers,
                nearbyPlaces: placesState.places,
                currentRoute: routingState.currentRoute,
                onTap: (_, point) => _handleMapTap(point),
                onPositionChanged: (camera, hasGesture) {
                  if (hasGesture && userLoc.isFollowingUser) {
                    ref
                        .read(userLocationControllerProvider.notifier)
                        .setFollowingUser(false);
                  }
                },
                onMarkerTap: _openMarkerDetails,
                onPlaceTap: _openPlaceDetails,
              );
            },
          ),

          // 2. Оверлей интерактивного выбора точки на карте
          if (routingState.isPickingPointOnMap)
            PointPickerOverlay(
              pickingForStart: routingState.pickingForStart,
              onConfirm: _confirmPickedPoint,
              onCancel: () {
                ref.read(routingControllerProvider.notifier).stopPickingPoint();
                _openRoutePlannerSheet();
              },
            ),

          // 3. Затемняющий оверлей поиска
          if (searchState.isSearchOpen && !routingState.isPickingPointOnMap)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _searchBarKey.currentState?.closeSearch();
                  ref
                      .read(searchControllerProvider.notifier)
                      .setSearchOpen(false);
                  FocusScope.of(context).unfocus();
                },
                child: Container(color: Colors.black26),
              ),
            ),

          // 4. Поисковая панель вверху
          if (!routingState.isPickingPointOnMap)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: FloatingSearchBar(
                  key: _searchBarKey,
                  userLocation: userLoc.location,
                  mapCenter: _mapController.camera.center,
                  nearbyPlaces: placesState.places,
                  onOpenStateChanged: (isOpen) {
                    ref
                        .read(searchControllerProvider.notifier)
                        .setSearchOpen(isOpen);
                  },
                  onCategorySelected: (cat) {
                    final pos =
                        userLoc.location ?? AppConstants.defaultLocation;
                    ref
                        .read(placesControllerProvider.notifier)
                        .selectCategory(pos, cat);
                  },
                  onResultSelected: (result) {
                    _mapController.move(result.position, 16);
                    final rawPlace = Place(
                      id: '${result.position.latitude}_${result.position.longitude}',
                      name: result.title,
                      position: result.position,
                      type: result.type,
                      address: result.subtitle,
                    );
                    _openPlaceDetails(rawPlace);
                  },
                  onClear: () {},
                ),
              ),
            ),

          // 5. Карточка активного маршрута
          if (routingState.currentRoute != null &&
              !routingState.isPickingPointOnMap)
            Positioned(
              top: 75,
              left: 0,
              right: 0,
              child: SafeArea(
                child: RouteHeaderCard(
                  route: routingState.currentRoute!,
                  onClose: () =>
                      ref.read(routingControllerProvider.notifier).clearRoute(),
                ),
              ),
            ),

          // 6. Правая колонка кнопок управления
          if (!routingState.isPickingPointOnMap)
            Positioned(
              right: 16,
              bottom: 120,
              child: SafeArea(
                child: MapControlsColumn(
                  onLayerSwitcherPressed: _showLayerSwitcher,
                  onZoomInPressed: () => _zoom(true),
                  onZoomOutPressed: () => _zoom(false),
                  onMyLocationPressed: _onMyLocationPressed,
                  isFollowingUser: userLoc.isFollowingUser,
                ),
              ),
            ),

          // 7. Нижняя панель категорий и меток
          if (!routingState.isPickingPointOnMap && !searchState.isSearchOpen)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: BottomPanel(
                savedMarkers: savedMarkers,
                onCategorySelected: (cat) {
                  final pos = userLoc.location ?? AppConstants.defaultLocation;
                  ref
                      .read(placesControllerProvider.notifier)
                      .selectCategory(pos, cat);
                },
                onMarkerSelected: (marker) {
                  _mapController.move(marker.position, 16);
                  _openMarkerDetails(marker);
                },
                onClearAllMarkers: () {
                  ref.read(markersControllerProvider.notifier).clearAll();
                },
                onShareLocation: () {
                  final loc = userLoc.location;
                  if (loc != null) {
                    final link =
                        'https://www.google.com/maps?q=${loc.latitude},${loc.longitude}';
                    Clipboard.setData(ClipboardData(text: link));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(AppStrings.locationCopied),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                onOpenRoutePlanner: () => _openRoutePlannerSheet(),
              ),
            ),
        ],
      ),
    );
  }
}

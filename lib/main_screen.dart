import 'dart:io';

import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:http_cache_file_store/http_cache_file_store.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

import 'app_theme.dart';
import 'models/map_tile_style.dart';
import 'models/place.dart';
import 'models/route_info.dart';
import 'models/saved_marker.dart';
import 'services/location_service.dart';
import 'services/marker_storage.dart';
import 'services/place_details_service.dart';
import 'services/places_service.dart';
import 'services/routing_service.dart';
import 'widgets/bottom_panel.dart';
import 'widgets/layer_switcher_dialog.dart';
import 'widgets/map_marker_widgets.dart';
import 'widgets/place_details_sheet.dart';
import 'widgets/route_header_card.dart';
import 'widgets/route_planner_sheet.dart';
import 'widgets/search_bar_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final Future<CacheStore> _cacheStoreFuture;
  final MapController _mapController = MapController();

  // Состояние слоев
  MapTileStyle _selectedTileStyle = MapTileStyle.availableStyles[0]; // Dark Matter по умолчанию

  // Геолокация (по умолчанию Калининград, обновляется по сигналу GPS)
  LatLng? _userLocation = LocationService.defaultLocation;

  // Точки и объекты
  List<SavedMarker> _savedMarkers = [];
  List<Place> _nearbyPlaces = [];

  // Поиск
  final GlobalKey<FloatingSearchBarState> _searchBarKey = GlobalKey<FloatingSearchBarState>();
  bool _isSearchOpen = false;

  // Маршрут
  RouteInfo? _currentRoute;
  bool _isBuildingRoute = false;

  // Режим выбора точки на карте для маршрута
  bool _isPickingPointOnMap = false;
  bool _pickingForStart = false;
  RoutePointItem? _savedPlannerStart;
  RoutePointItem? _savedPlannerEnd;

  @override
  void initState() {
    super.initState();
    _cacheStoreFuture = _getCacheStore();
    _loadInitialData();
  }

  static Future<CacheStore> _getCacheStore() async {
    final directory = await getApplicationSupportDirectory();
    final cacheDirectory = Directory('${directory.path}/map_tiles');
    if (!await cacheDirectory.exists()) {
      await cacheDirectory.create(recursive: true);
    }
    return FileCacheStore(cacheDirectory.path);
  }

  Future<void> _loadInitialData() async {
    final markers = await MarkerStorage.loadMarkers();
    if (!mounted) return;
    setState(() {
      _savedMarkers = markers;
    });

    // Фоновое определение местоположения
    await _updateUserLocation(centerMap: false);

    // Фоновая подгрузка мест вокруг геолокации для быстрого поиска
    _precacheNearbyPlaces();
  }

  Future<void> _precacheNearbyPlaces() async {
    try {
      final loc = _userLocation ?? LocationService.defaultLocation;
      final places = await PlacesService.getNearbyPlaces(loc, radius: 1200);
      if (mounted && places.isNotEmpty) {
        setState(() {
          _nearbyPlaces = places;
        });
      }
    } catch (_) {}
  }

  Future<void> _updateUserLocation({bool centerMap = false}) async {
    final loc = await LocationService.getCurrentLocation();
    if (!mounted) return;
    if (loc != null) {
      setState(() {
        _userLocation = loc;
      });
      if (centerMap) {
        _mapController.move(loc, 15);
      }
    } else if (centerMap) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось определить местоположение'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  LatLng? get _safeMapCenter {
    try {
      return _mapController.camera.center;
    } catch (_) {
      return null;
    }
  }

  // --- Управление маркерами ---

  Future<void> _handleMapTap(LatLng position) async {
    FocusScope.of(context).unfocus();
    if (_isSearchOpen) {
      _searchBarKey.currentState?.closeSearch();
      setState(() {
        _isSearchOpen = false;
      });
      return;
    }
    if (_isPickingPointOnMap) {
      _mapController.move(position, _mapController.camera.zoom);
      return;
    }

    final newMarker = SavedMarker(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Точка #${_savedMarkers.length + 1}',
      position: position,
    );

    setState(() {
      _savedMarkers.add(newMarker);
    });
    await MarkerStorage.saveMarkers(_savedMarkers);

    if (!mounted) return;
    _openMarkerDetails(newMarker);
  }

  void _openMarkerDetails(SavedMarker marker) {
    double? dist;
    if (_userLocation != null) {
      dist = const Distance().as(
        LengthUnit.Meter,
        _userLocation!,
        marker.position,
      );
    }
    final place = PlaceDetailsService.fromMarker(marker);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PlaceDetailsSheet(
        place: place,
        distanceMeters: dist,
        onBuildRoute: () {
          Navigator.pop(ctx);
          _buildRouteTo(marker.position, marker.title);
        },
        onPlanRoute: () {
          Navigator.pop(ctx);
          _openRoutePlanner(
            initialStart: RoutePointItem(
              id: marker.id,
              title: marker.title,
              position: marker.position,
              icon: Icons.location_pin,
              iconColor: Colors.redAccent,
            ),
          );
        },
        onRename: (newName) async {
          setState(() {
            final idx = _savedMarkers.indexWhere((m) => m.id == marker.id);
            if (idx != -1) {
              _savedMarkers[idx] = SavedMarker(
                id: marker.id,
                title: newName,
                position: marker.position,
                createdAt: marker.createdAt,
              );
            }
          });
          await MarkerStorage.saveMarkers(_savedMarkers);
        },
        onDelete: () async {
          Navigator.pop(ctx);
          setState(() {
            _savedMarkers.removeWhere((m) => m.id == marker.id);
          });
          await MarkerStorage.saveMarkers(_savedMarkers);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Точка удалена'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _openPlaceDetails(Place place) {
    double? dist;
    if (_userLocation != null) {
      dist = const Distance().as(
        LengthUnit.Meter,
        _userLocation!,
        place.position,
      );
    }

    final enrichedPlace =
        place.photos.isEmpty ? PlaceDetailsService.enrichPlace(place) : place;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PlaceDetailsSheet(
        place: enrichedPlace,
        distanceMeters: dist,
        onBuildRoute: () {
          Navigator.pop(ctx);
          _buildRouteTo(enrichedPlace.position, enrichedPlace.name);
        },
        onPlanRoute: () {
          Navigator.pop(ctx);
          _openRoutePlanner(
            initialStart: RoutePointItem(
              id: enrichedPlace.id,
              title: enrichedPlace.name,
              position: enrichedPlace.position,
              icon: enrichedPlace.icon,
              iconColor: enrichedPlace.color,
            ),
          );
        },
      ),
    );
  }

  Future<void> _clearAllMarkers() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить все точки?'),
        content: const Text('Все сохраненные метки будут стерты безвозвратно.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _savedMarkers.clear();
      });
      await MarkerStorage.clearAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Все точки удалены'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // --- Поиск мест рядом через Overpass ---

  Future<void> _loadNearbyPlaces(String category) async {
    var userLoc = _userLocation;
    if (userLoc == null) {
      userLoc = await LocationService.getCurrentLocation();
      if (userLoc != null) {
        setState(() {
          _userLocation = userLoc;
        });
      }
    }

    if (userLoc == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Включите геолокацию для поиска рядом')),
      );
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Text('Ищем "$category" рядом...'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final places = await PlacesService.getNearbyPlaces(
        userLoc,
        category: category,
        radius: 1200,
      );

      if (!mounted) return;
      setState(() {
        _nearbyPlaces = places;
      });

      if (places.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('В радиусе 1.2 км ничего не найдено')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Найдено мест: ${places.length}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось загрузить места, попробуйте еще раз')),
      );
    }
  }

  // --- Маршруты ---

  Future<void> _buildRouteBetween({
    required LatLng start,
    required String startName,
    required LatLng destination,
    required String destinationName,
  }) async {
    setState(() {
      _isBuildingRoute = true;
    });

    final route = await RoutingService.getRoute(
      start,
      destination,
      startName: startName,
      destinationName: destinationName,
    );

    if (!mounted) return;
    setState(() {
      _isBuildingRoute = false;
      _currentRoute = route;
    });

    if (route != null) {
      final bounds = LatLngBounds.fromPoints([start, destination]);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.only(
            top: 130,
            bottom: 150,
            left: 50,
            right: 50,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось построить маршрут')),
      );
    }
  }

  Future<void> _buildRouteTo(LatLng destination, String title) async {
    var startLoc = _userLocation;
    if (startLoc == null) {
      startLoc = await LocationService.getCurrentLocation();
      if (startLoc != null) {
        setState(() {
          _userLocation = startLoc;
        });
      }
    }

    if (startLoc == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не определена точка отправления')),
      );
      return;
    }

    await _buildRouteBetween(
      start: startLoc,
      startName: 'Моё местоположение',
      destination: destination,
      destinationName: title,
    );
  }

  void _openRoutePlanner({
    RoutePointItem? initialStart,
    RoutePointItem? initialDestination,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RoutePlannerSheet(
        userLocation: _userLocation,
        initialStart: initialStart,
        initialDestination: initialDestination,
        savedMarkers: _savedMarkers,
        nearbyPlaces: _nearbyPlaces,
        onPickOnMap: (isStart, currentStart, currentEnd) {
          setState(() {
            _isPickingPointOnMap = true;
            _pickingForStart = isStart;
            _savedPlannerStart = currentStart;
            _savedPlannerEnd = currentEnd;
          });
          HapticFeedback.mediumImpact();
        },
        onBuildRoute: (startPos, startName, endPos, endName) {
          _buildRouteBetween(
            start: startPos,
            startName: startName,
            destination: endPos,
            destinationName: endName,
          );
        },
      ),
    );
  }

  void _clearRoute() {
    setState(() {
      _currentRoute = null;
    });
  }

  // --- Переключение слоев ---

  void _showLayerSwitcher() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LayerSwitcherModal(
        currentType: _selectedTileStyle.type,
        onStyleSelected: (newStyle) {
          setState(() {
            _selectedTileStyle = newStyle;
          });
        },
      ),
    );
  }

  void _zoom(bool zoomIn) {
    final double currentZoom = _mapController.camera.zoom;
    final LatLng currentCenter = _mapController.camera.center;
    final double newZoom = zoomIn ? currentZoom + 1 : currentZoom - 1;
    _mapController.move(currentCenter, newZoom);
  }

  // --- Сборка слоев карты ---

  Widget _buildMap(CacheStore cacheStore) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        backgroundColor: AppTheme.background,
        initialCenter: const LatLng(54.7104, 20.4522),
        initialZoom: 13.0,
        minZoom: 2.5,
        maxZoom: 19,
        onTap: (tapPosition, point) => _handleMapTap(point),
        cameraConstraint: CameraConstraint.containLatitude(),
      ),
      children: [
        // 1. Тайлы карты (с кешем)
        TileLayer(
          key: ValueKey(_selectedTileStyle.type),
          urlTemplate: _selectedTileStyle.urlTemplate,
          subdomains: _selectedTileStyle.subdomains,
          keepBuffer: 4,
          maxZoom: _selectedTileStyle.maxZoom.toDouble(),
          userAgentPackageName: 'com.helltrilla.maps',
          tileProvider: CachedTileProvider(
            store: cacheStore,
            maxStale: const Duration(days: 30),
            hitCacheOnNetworkFailure: true,
          ),
        ),

        // 2. Линия построенного маршрута
        if (_currentRoute != null)
          PolylineLayer(
            polylines: [
              // Фоновая обводка для красивого контраста
              Polyline(
                points: _currentRoute!.points,
                strokeWidth: 7.0,
                color: const Color(0xFF1E3A8A),
              ),
              // Основная неоновая линия
              Polyline(
                points: _currentRoute!.points,
                strokeWidth: 4.5,
                color: AppTheme.accent,
              ),
            ],
          ),

        // 3. Маркеры
        MarkerLayer(
          markers: [
            // Текущее местоположение юзера
            if (_userLocation != null)
              MapMarkerWidgets.buildUserLocationMarker(_userLocation!),

            // Пользовательские сохраненные точки
            ..._savedMarkers.map(
              (m) => MapMarkerWidgets.buildSavedMarker(
                position: m.position,
                title: m.title,
                onTap: () => _openMarkerDetails(m),
                onLongPress: () => _openMarkerDetails(m),
              ),
            ),

            // Найденные объекты (Overpass / поиск)
            ..._nearbyPlaces.map(
              (place) => MapMarkerWidgets.buildPlaceMarker(
                position: place.position,
                icon: place.icon,
                color: place.color,
                onTap: () => _openPlaceDetails(place),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Основная карта
          FutureBuilder<CacheStore>(
            future: _cacheStoreFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Ошибка кеша: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                );
              }
              return _buildMap(snapshot.data!);
            },
          ),

          // Центральный прицел/пин при выборе точки на карте
          if (_isPickingPointOnMap)
            IgnorePointer(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 38),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _pickingForStart ? Colors.greenAccent : Colors.redAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_pickingForStart ? Colors.greenAccent : Colors.redAccent).withAlpha(160),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          _pickingForStart ? Icons.play_arrow_rounded : Icons.flag_rounded,
                          color: Colors.black,
                          size: 26,
                        ),
                      ),
                      Container(
                        width: 3.5,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _pickingForStart ? Colors.greenAccent : Colors.redAccent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(140),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Затемняющий оверлей для мгновенного закрытия поиска тапом в любое место
          if (_isSearchOpen && !_isPickingPointOnMap)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _searchBarKey.currentState?.closeSearch();
                  setState(() {
                    _isSearchOpen = false;
                  });
                  FocusScope.of(context).unfocus();
                },
                child: Container(
                  color: Colors.black26,
                ),
              ),
            ),

          // Верхняя панель: Поиск ИЛИ Плашка режима выбора точки
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _isPickingPointOnMap
                  ? Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _pickingForStart
                              ? Colors.greenAccent.withAlpha(120)
                              : Colors.redAccent.withAlpha(120),
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 20,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (_pickingForStart
                                          ? Colors.greenAccent
                                          : Colors.redAccent)
                                      .withAlpha(35),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _pickingForStart
                                      ? Icons.play_arrow_rounded
                                      : Icons.flag_rounded,
                                  color: _pickingForStart
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _pickingForStart
                                          ? 'Точка отправления (А)'
                                          : 'Точка назначения (Б)',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Переместите карту под центральный маркер',
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isPickingPointOnMap = false;
                                  });
                                  _openRoutePlanner(
                                    initialStart: _savedPlannerStart,
                                    initialDestination: _savedPlannerEnd,
                                  );
                                },
                                icon: const Icon(Icons.close_rounded, color: Colors.white60),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final center = _mapController.camera.center;
                                final title =
                                    'Точка (${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)})';
                                final item = RoutePointItem(
                                  id: 'picked_${DateTime.now().millisecondsSinceEpoch}',
                                  title: title,
                                  position: center,
                                  icon: Icons.pin_drop_rounded,
                                  iconColor: _pickingForStart ? Colors.greenAccent : Colors.redAccent,
                                );

                                final newStart = _pickingForStart ? item : _savedPlannerStart;
                                final newEnd = !_pickingForStart ? item : _savedPlannerEnd;

                                setState(() {
                                  _isPickingPointOnMap = false;
                                });

                                _openRoutePlanner(
                                  initialStart: newStart,
                                  initialDestination: newEnd,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _pickingForStart ? Colors.greenAccent : AppTheme.primary,
                                foregroundColor: _pickingForStart ? Colors.black : Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 4,
                              ),
                              icon: const Icon(Icons.check_circle_rounded, size: 20),
                              label: const Text(
                                'Выбрать эту точку',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        FloatingSearchBar(
                          key: _searchBarKey,
                          userLocation: _userLocation,
                          mapCenter: _safeMapCenter,
                          nearbyPlaces: _nearbyPlaces,
                          onOpenStateChanged: (isOpen) {
                            if (_isSearchOpen != isOpen) {
                              setState(() {
                                _isSearchOpen = isOpen;
                              });
                            }
                          },
                          onCategorySelected: (cat) => _loadNearbyPlaces(cat),
                          onResultSelected: (result) {
                            _mapController.move(result.position, 16);
                            final rawPlace = Place(
                              id: 'search_${result.position.latitude}_${result.position.longitude}',
                              name: result.title,
                              position: result.position,
                              type: result.type,
                              address: result.subtitle,
                            );
                            final place = PlaceDetailsService.enrichPlace(rawPlace);
                            setState(() {
                              _nearbyPlaces = [place, ..._nearbyPlaces];
                            });
                            _openPlaceDetails(place);
                          },
                          onClear: () {},
                        ),
                        if (_currentRoute != null)
                          RouteHeaderCard(
                            route: _currentRoute!,
                            onClose: _clearRoute,
                          ),
                        if (_isBuildingRoute)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Прокладываем маршрут...',
                                  style: TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ),

          // Плавающие кнопки справа
          Positioned(
            right: 16,
            bottom: _isPickingPointOnMap ? 40 : 120,
            child: Column(
              children: [
                // Переключатель слоев
                FloatingActionButton.small(
                  heroTag: 'layers_fab',
                  onPressed: _showLayerSwitcher,
                  tooltip: 'Слои карты',
                  backgroundColor: AppTheme.surface,
                  child: const Icon(Icons.layers_rounded, color: Colors.white),
                ),
                const SizedBox(height: 10),

                // Зум +
                FloatingActionButton.small(
                  heroTag: 'zoom_in_fab',
                  onPressed: () => _zoom(true),
                  tooltip: 'Приблизить',
                  backgroundColor: AppTheme.surface,
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                ),
                const SizedBox(height: 8),

                // Зум -
                FloatingActionButton.small(
                  heroTag: 'zoom_out_fab',
                  onPressed: () => _zoom(false),
                  tooltip: 'Отдалить',
                  backgroundColor: AppTheme.surface,
                  child: const Icon(Icons.remove_rounded, color: Colors.white),
                ),
                const SizedBox(height: 12),

                // Мое местоположение
                FloatingActionButton(
                  heroTag: 'my_location_fab',
                  onPressed: () => _updateUserLocation(centerMap: true),
                  tooltip: 'Мое местоположение',
                  backgroundColor: AppTheme.primary,
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Colors.white,
                  ),
                ),

                if (!_isPickingPointOnMap && (_savedMarkers.isNotEmpty || _nearbyPlaces.isNotEmpty)) ...[
                  const SizedBox(height: 10),
                  FloatingActionButton.small(
                    heroTag: 'clear_places_fab',
                    onPressed: () {
                      setState(() {
                        _nearbyPlaces.clear();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Найденные места скрыты с карты'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    tooltip: 'Скрыть точки с карты',
                    backgroundColor: AppTheme.surfaceSubtle,
                    child: const Icon(
                      Icons.layers_clear_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Нижняя шторка с категориями и сохраненными местами (скрыта в режиме пикера)
          if (!_isPickingPointOnMap)
            BottomPanel(
              savedMarkers: _savedMarkers,
              onCategorySelected: (cat) => _loadNearbyPlaces(cat),
              onMarkerSelected: (marker) {
                _mapController.move(marker.position, 16);
                _openMarkerDetails(marker);
              },
              onClearAllMarkers: _clearAllMarkers,
              onOpenRoutePlanner: () => _openRoutePlanner(),
              onShareLocation: () {
                if (_userLocation != null) {
                  final link =
                      'https://www.google.com/maps?q=${_userLocation!.latitude},${_userLocation!.longitude}';
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ссылка на геопозицию скопирована!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Геолокация еще не определена')),
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}

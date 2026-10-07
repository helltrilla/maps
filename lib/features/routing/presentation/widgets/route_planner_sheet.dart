import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../markers/domain/models/saved_marker.dart';
import '../../../places/domain/models/place.dart';

class RoutePointItem {
  final String id;
  final String title;
  final LatLng position;
  final IconData icon;
  final Color iconColor;
  final bool isUserLocation;

  const RoutePointItem({
    required this.id,
    required this.title,
    required this.position,
    required this.icon,
    required this.iconColor,
    this.isUserLocation = false,
  });
}

class RoutePlannerSheet extends StatefulWidget {
  final LatLng? userLocation;
  final RoutePointItem? initialStart;
  final RoutePointItem? initialDestination;
  final List<SavedMarker> savedMarkers;
  final List<Place> nearbyPlaces;
  final void Function(
    LatLng startPos,
    String startName,
    LatLng endPos,
    String endName,
  ) onBuildRoute;
  final void Function(
    bool isStart,
    RoutePointItem currentStart,
    RoutePointItem currentEnd,
  )? onPickOnMap;

  const RoutePlannerSheet({
    super.key,
    this.userLocation,
    this.initialStart,
    this.initialDestination,
    required this.savedMarkers,
    required this.nearbyPlaces,
    required this.onBuildRoute,
    this.onPickOnMap,
  });

  @override
  State<RoutePlannerSheet> createState() => _RoutePlannerSheetState();
}

class _RoutePlannerSheetState extends State<RoutePlannerSheet> {
  late RoutePointItem _startPoint;
  late RoutePointItem _endPoint;

  @override
  void initState() {
    super.initState();

    final userPoint = widget.userLocation != null
        ? RoutePointItem(
            id: 'user_location',
            title: 'Моё местоположение',
            position: widget.userLocation!,
            icon: Icons.my_location_rounded,
            iconColor: AppTheme.accent,
            isUserLocation: true,
          )
        : null;

    if (widget.initialStart != null) {
      _startPoint = widget.initialStart!;
    } else if (userPoint != null) {
      _startPoint = userPoint;
    } else if (widget.savedMarkers.isNotEmpty) {
      final m = widget.savedMarkers.first;
      _startPoint = RoutePointItem(
        id: m.id,
        title: m.title,
        position: m.position,
        icon: Icons.location_pin,
        iconColor: Colors.redAccent,
      );
    } else {
      _startPoint = RoutePointItem(
        id: 'default_kaliningrad',
        title: 'Калининград (центр)',
        position: const LatLng(54.7104, 20.4522),
        icon: Icons.location_pin,
        iconColor: Colors.redAccent,
      );
    }

    if (widget.initialDestination != null) {
      _endPoint = widget.initialDestination!;
    } else if (widget.savedMarkers.isNotEmpty) {
      final m = widget.savedMarkers.last;
      _endPoint = RoutePointItem(
        id: m.id,
        title: m.title,
        position: m.position,
        icon: Icons.location_pin,
        iconColor: Colors.redAccent,
      );
    } else if (widget.nearbyPlaces.isNotEmpty) {
      final p = widget.nearbyPlaces.first;
      _endPoint = RoutePointItem(
        id: p.id,
        title: p.name,
        position: p.position,
        icon: p.icon,
        iconColor: p.color,
      );
    } else {
      _endPoint = RoutePointItem(
        id: 'default_kaliningrad_dest',
        title: 'Калининград (Северный)',
        position: const LatLng(54.7208, 20.4556),
        icon: Icons.flag_rounded,
        iconColor: Colors.amber,
      );
    }
  }

  void _swapPoints() {
    HapticFeedback.lightImpact();
    setState(() {
      final temp = _startPoint;
      _startPoint = _endPoint;
      _endPoint = temp;
    });
  }

  List<RoutePointItem> _getAllAvailablePoints() {
    final list = <RoutePointItem>[];

    if (widget.userLocation != null) {
      list.add(
        RoutePointItem(
          id: 'user_location',
          title: 'Моё местоположение',
          position: widget.userLocation!,
          icon: Icons.my_location_rounded,
          iconColor: AppTheme.accent,
          isUserLocation: true,
        ),
      );
    }

    for (final m in widget.savedMarkers) {
      list.add(
        RoutePointItem(
          id: m.id,
          title: m.title,
          position: m.position,
          icon: Icons.bookmark_rounded,
          iconColor: Colors.amber,
        ),
      );
    }

    for (final p in widget.nearbyPlaces) {
      list.add(
        RoutePointItem(
          id: p.id,
          title: p.name,
          position: p.position,
          icon: p.icon,
          iconColor: p.color,
        ),
      );
    }

    return list;
  }

  void _selectPointModal(bool isStart) {
    final allPoints = _getAllAvailablePoints();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(
              isStart
                  ? 'Выберите точку отправления (А)'
                  : 'Выберите точку назначения (Б)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),

            // Кнопка: Указать точку на карте
            if (widget.onPickOnMap != null) ...[
              Material(
                color: AppTheme.accent.withAlpha(25),
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.touch_app_rounded,
                        color: AppTheme.accent, size: 22),
                  ),
                  title: const Text(
                    'Указать точку на карте',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: const Text(
                    'Перемещайте карту и наведите прицел',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppTheme.accent),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                    widget.onPickOnMap!(isStart, _startPoint, _endPoint);
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],

            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: allPoints.length,
                separatorBuilder: (context, index) =>
                    const Divider(color: Colors.white10, height: 1),
                itemBuilder: (context, i) {
                  final pt = allPoints[i];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: pt.iconColor.withAlpha(35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(pt.icon, color: pt.iconColor, size: 20),
                    ),
                    title: Text(
                      pt.title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${pt.position.latitude.toStringAsFixed(4)}, ${pt.position.longitude.toStringAsFixed(4)}',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        if (isStart) {
                          _startPoint = pt;
                        } else {
                          _endPoint = pt;
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Заголовок
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.alt_route_rounded,
                    color: AppTheme.accent, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Маршрут между точками',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Выберите старт и финиш для навигации',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white60),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Контейнер выбора точек со стрелкой обмена
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSubtle,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white12),
            ),
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                Column(
                  children: [
                    // Точка А (Старт)
                    InkWell(
                      onTap: () => _selectPointModal(true),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ОТКУДА (А)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white54,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _startPoint.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.onPickOnMap != null)
                              IconButton(
                                icon: const Icon(Icons.pin_drop_outlined,
                                    size: 18, color: AppTheme.accent),
                                tooltip: 'Указать точку на карте',
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onPickOnMap!(
                                      true, _startPoint, _endPoint);
                                },
                              ),
                            const SizedBox(
                                width: 36), // место под кнопку реверса
                          ],
                        ),
                      ),
                    ),

                    const Divider(color: Colors.white10, height: 16),

                    // Точка Б (Финиш)
                    InkWell(
                      onTap: () => _selectPointModal(false),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'КУДА (Б)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white54,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _endPoint.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.onPickOnMap != null)
                              IconButton(
                                icon: const Icon(Icons.pin_drop_outlined,
                                    size: 18, color: Colors.redAccent),
                                tooltip: 'Указать точку на карте',
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onPickOnMap!(
                                      false, _startPoint, _endPoint);
                                },
                              ),
                            const SizedBox(width: 36),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Кнопка реверса по центру справа
                Positioned(
                  right: 4,
                  child: Material(
                    color: AppTheme.primary,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _swapPoints,
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.swap_vert_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Быстрые чипы точек
          const Text(
            'Быстрый выбор точек:',
            style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (widget.onPickOnMap != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.touch_app_rounded,
                          size: 16, color: AppTheme.accent),
                      label: const Text('Указать на карте',
                          style: TextStyle(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.bold)),
                      backgroundColor: AppTheme.accent.withAlpha(30),
                      side:
                          const BorderSide(color: AppTheme.accent, width: 0.8),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onPickOnMap!(false, _startPoint, _endPoint);
                      },
                    ),
                  ),
                if (widget.userLocation != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.my_location_rounded,
                          size: 16, color: AppTheme.accent),
                      label: const Text('Моё местоположение',
                          style: TextStyle(color: Colors.white)),
                      backgroundColor: AppTheme.surfaceSubtle,
                      side: BorderSide.none,
                      onPressed: () {
                        setState(() {
                          _startPoint = RoutePointItem(
                            id: 'user_location',
                            title: 'Моё местоположение',
                            position: widget.userLocation!,
                            icon: Icons.my_location_rounded,
                            iconColor: AppTheme.accent,
                            isUserLocation: true,
                          );
                        });
                      },
                    ),
                  ),
                ...widget.savedMarkers.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.bookmark_rounded,
                          size: 16, color: Colors.amber),
                      label: Text(m.title,
                          style: const TextStyle(color: Colors.white)),
                      backgroundColor: AppTheme.surfaceSubtle,
                      side: BorderSide.none,
                      onPressed: () {
                        setState(() {
                          _endPoint = RoutePointItem(
                            id: m.id,
                            title: m.title,
                            position: m.position,
                            icon: Icons.location_pin,
                            iconColor: Colors.redAccent,
                          );
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Кнопка подтверждения
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              widget.onBuildRoute(
                _startPoint.position,
                _startPoint.title,
                _endPoint.position,
                _endPoint.title,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            icon: const Icon(Icons.directions_car_rounded, size: 22),
            label: const Text(
              'Построить маршрут',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

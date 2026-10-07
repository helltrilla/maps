import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../markers/domain/models/saved_marker.dart';

class BottomPanel extends StatelessWidget {
  final List<SavedMarker> savedMarkers;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<SavedMarker> onMarkerSelected;
  final VoidCallback onClearAllMarkers;
  final VoidCallback onShareLocation;
  final VoidCallback onOpenRoutePlanner;

  const BottomPanel({
    super.key,
    required this.savedMarkers,
    required this.onCategorySelected,
    required this.onMarkerSelected,
    required this.onClearAllMarkers,
    required this.onShareLocation,
    required this.onOpenRoutePlanner,
  });

  static const List<Map<String, dynamic>> categories = [
    {'title': 'Все', 'icon': Icons.explore_rounded, 'color': Color(0xFF3B82F6)},
    {
      'title': 'Кафе',
      'icon': Icons.local_cafe_rounded,
      'color': Color(0xFFFF9800)
    },
    {
      'title': 'Ресторан',
      'icon': Icons.restaurant_rounded,
      'color': Color(0xFFE91E63)
    },
    {
      'title': 'Аптека',
      'icon': Icons.local_pharmacy_rounded,
      'color': Color(0xFF4CAF50)
    },
    {
      'title': 'Магазин',
      'icon': Icons.shopping_bag_rounded,
      'color': Color(0xFF00BCD4)
    },
    {
      'title': 'АЗС',
      'icon': Icons.local_gas_station_rounded,
      'color': Color(0xFFFF5722)
    },
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.14,
      minChildSize: 0.14,
      maxChildSize: 0.65,
      snap: true,
      snapSizes: const [0.14, 0.65],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // Полоса перетаскивания (Handle bar)
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                // Горизонтальный скролл быстрых категорий поиска
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final color = cat['color'] as Color;
                      return InkWell(
                        onTap: () => onCategorySelected(cat['title'] as String),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: color.withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withAlpha(80)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(cat['icon'] as IconData,
                                  size: 16, color: color),
                              const SizedBox(width: 6),
                              Text(
                                cat['title'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 18),

                // Раздел: Мои сохраненные места
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Мои сохраненные точки',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (savedMarkers.isNotEmpty)
                      TextButton(
                        onPressed: onClearAllMarkers,
                        child: const Text(
                          'Очистить',
                          style:
                              TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                      ),
                  ],
                ),

                if (savedMarkers.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            size: 36,
                            color: Colors.white30,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Нажмите в любое место карты, чтобы добавить точку',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...savedMarkers.map((marker) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        marker.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        '${marker.position.latitude.toStringAsFixed(4)}, ${marker.position.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white38,
                      ),
                      onTap: () => onMarkerSelected(marker),
                    );
                  }),

                const SizedBox(height: 16),

                // Дополнительные быстрые действия
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.alt_route_rounded,
                      color: AppTheme.accent,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Маршрут между точками (А ➔ Б)',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Проложить маршрут от любой точки до другой',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  onTap: onOpenRoutePlanner,
                ),

                const SizedBox(height: 6),

                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.share_location_rounded,
                      color: AppTheme.accent,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Поделиться текущим местоположением',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: onShareLocation,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

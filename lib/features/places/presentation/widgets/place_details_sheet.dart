import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/place.dart';
import '../../domain/models/place_review.dart';
import '../extensions/place_ui_extension.dart';

class PlaceDetailsSheet extends StatefulWidget {
  final Place place;
  final double? distanceMeters;
  final VoidCallback onBuildRoute;
  final VoidCallback? onPlanRoute;
  final VoidCallback? onDelete;
  final void Function(String newName)? onRename;

  const PlaceDetailsSheet({
    super.key,
    required this.place,
    this.distanceMeters,
    required this.onBuildRoute,
    this.onPlanRoute,
    this.onDelete,
    this.onRename,
  });

  @override
  State<PlaceDetailsSheet> createState() => _PlaceDetailsSheetState();
}

class _PlaceDetailsSheetState extends State<PlaceDetailsSheet> {
  late String _currentName;

  @override
  void initState() {
    super.initState();
    _currentName = widget.place.name;
  }

  @override
  void didUpdateWidget(covariant PlaceDetailsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.place.name != oldWidget.place.name) {
      _currentName = widget.place.name;
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} м от вас';
    }
    return '${(meters / 1000).toStringAsFixed(1)} км от вас';
  }

  void _showFullscreenPhoto(BuildContext context, String imageUrl) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 250,
                  color: AppTheme.surfaceSubtle,
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded,
                        size: 48, color: Colors.white54),
                  ),
                ),
              ),
            ),
            IconButton.filled(
              onPressed: () => Navigator.pop(ctx),
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: _currentName);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Переименовать точку',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Название',
            hintStyle: TextStyle(color: Colors.white38),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && widget.onRename != null) {
                setState(() {
                  _currentName = newName;
                });
                widget.onRename!(newName);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final distanceMeters = widget.distanceMeters;
    final onBuildRoute = widget.onBuildRoute;
    final onPlanRoute = widget.onPlanRoute;
    final onDelete = widget.onDelete;
    final onRename = widget.onRename;
    return DraggableScrollableSheet(
      initialChildSize: 0.50,
      minChildSize: 0.25,
      maxChildSize: 0.90,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Material(
            color: Colors.transparent,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                // Верхний блок: Иконка, Название, Категория
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: place.color.withAlpha(35),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(place.icon, color: place.color, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: place.color.withAlpha(40),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    place.type,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: place.color,
                                    ),
                                  ),
                                ),
                              ),
                              if (distanceMeters != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  _formatDistance(distanceMeters),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.accent,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (onRename != null)
                      IconButton(
                        onPressed: () => _showRenameDialog(context),
                        icon: const Icon(Icons.edit_outlined,
                            color: Colors.white60),
                        tooltip: 'Переименовать',
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Рейтинг и отзывы Google Maps (плашка)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        place.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '(${place.reviewsCount} отзывов • Демо)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.white60),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Кнопки действий: Маршрут, Копировать, Удалить
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: onBuildRoute,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.directions_rounded),
                        label: const Text(
                          AppStrings.buildRoute,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      onPressed: () {
                        final text =
                            '${place.position.latitude.toStringAsFixed(6)}, ${place.position.longitude.toStringAsFixed(6)}';
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Координаты скопированы'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.surfaceSubtle,
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon:
                          const Icon(Icons.copy_rounded, color: Colors.white70),
                      tooltip: 'Скопировать координаты',
                    ),
                    if (onPlanRoute != null) ...[
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: onPlanRoute,
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.accent.withAlpha(35),
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.alt_route_rounded,
                            color: AppTheme.accent),
                        tooltip: 'Маршрут между точками...',
                      ),
                    ],
                    if (onDelete != null) ...[
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: onDelete,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withAlpha(30),
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                        ),
                        tooltip: 'Удалить точку',
                      ),
                    ],
                  ],
                ),

                if (onPlanRoute != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: onPlanRoute,
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.alt_route_rounded,
                              size: 16, color: AppTheme.accent),
                          SizedBox(width: 6),
                          Text(
                            'Маршрут от этой точки до другой...',
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Информация: Адрес, Время работы, Телефон
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      if (place.address != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                color: Colors.white60, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                place.address!,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white12, height: 16),
                      ],
                      if (place.openingHours != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                color: Colors.greenAccent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                place.openingHours!,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white12, height: 16),
                      ],
                      if (place.phone != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined,
                                color: AppTheme.accent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                place.phone!,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(color: Colors.white12, height: 16),
                      Row(
                        children: [
                          const Icon(Icons.explore_outlined,
                              color: Colors.white60, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Координаты (дополнительная информация)',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.white38),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${place.position.latitude.toStringAsFixed(6)}, ${place.position.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded,
                                size: 16, color: Colors.white54),
                            tooltip: 'Скопировать координаты',
                            onPressed: () {
                              final text =
                                  '${place.position.latitude}, ${place.position.longitude}';
                              Clipboard.setData(ClipboardData(text: text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Координаты скопированы'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Секция: Реальные фотографии
                if (place.photos.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Фотографии места',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${place.photos.length} фото',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 125,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: place.photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final photoUrl = place.photos[index];
                        return InkWell(
                          onTap: () => _showFullscreenPhoto(context, photoUrl),
                          borderRadius: BorderRadius.circular(14),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              children: [
                                Image.network(
                                  photoUrl,
                                  width: 170,
                                  height: 125,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (_, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      width: 170,
                                      height: 125,
                                      color: AppTheme.surfaceSubtle,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 170,
                                    height: 125,
                                    color: AppTheme.surfaceSubtle,
                                    child: const Icon(
                                      Icons.broken_image_rounded,
                                      color: Colors.white38,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.zoom_in_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Секция: Отзывы из Google Maps
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.rate_review_rounded,
                              size: 18,
                              color: AppTheme.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'Отзывы пользователей (Демо)',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 18),
                        const SizedBox(width: 2),
                        Text(
                          place.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (place.reviews.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSubtle,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'Пока нет отзывов для этого места',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  )
                else
                  ...place.reviews.map((review) => _buildReviewCard(review)),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewCard(PlaceReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primary,
                backgroundImage: NetworkImage(review.authorAvatar),
                onBackgroundImageError: (exception, stackTrace) {},
                child: Text(
                  review.authorName.isNotEmpty ? review.authorName[0] : 'U',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    if (review.isLocalGuide)
                      const Text(
                        'Знаток города',
                        style:
                            TextStyle(fontSize: 11, color: Colors.orangeAccent),
                      ),
                  ],
                ),
              ),
              Text(
                review.timeAgo,
                style: const TextStyle(fontSize: 12, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                Icons.star_rounded,
                size: 16,
                color: index < review.rating ? Colors.amber : Colors.white24,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            review.text,
            style: const TextStyle(
                fontSize: 13, color: Colors.white, height: 1.35),
          ),
          if (review.likesCount > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.thumb_up_alt_outlined,
                    size: 14, color: Colors.white38),
                const SizedBox(width: 4),
                Text(
                  'Полезно (${review.likesCount})',
                  style: const TextStyle(fontSize: 12, color: Colors.white38),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

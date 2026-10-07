import 'package:flutter/material.dart';
import '../../domain/models/map_tile_style.dart';

/// Виджет видимой атрибуции тайлов карты.
/// Соответствует лицензионным требованиям OpenStreetMap, Esri, OpenTopoMap и CyclOSM.
class MapAttributionWidget extends StatelessWidget {
  final MapTileStyle tileStyle;

  const MapAttributionWidget({
    super.key,
    required this.tileStyle,
  });

  void _showAttributionDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, size: 22),
            const SizedBox(width: 8),
            Text(
              tileStyle.title,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Правообладатели и лицензии данных:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              tileStyle.attribution,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            const Text(
              'Подробные условия использования, квоты и лицензии описаны в файле docs/PROVIDERS_AND_LICENSES.md.',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAttributionDetails(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(160),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white12, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.copyright_rounded,
              size: 11,
              color: Colors.white70,
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                tileStyle.attribution,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

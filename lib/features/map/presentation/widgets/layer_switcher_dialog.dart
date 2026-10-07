import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/map_tile_style.dart';

class LayerSwitcherModal extends StatelessWidget {
  final MapTileType currentType;
  final ValueChanged<MapTileStyle> onStyleSelected;

  const LayerSwitcherModal({
    super.key,
    required this.currentType,
    required this.onStyleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const Text(
            AppStrings.mapLayers,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          ...MapTileStyle.availableStyles.map((style) {
            final isSelected = style.type == currentType;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Material(
                color: isSelected
                    ? AppTheme.primary.withAlpha(40)
                    : AppTheme.surfaceSubtle,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () {
                    onStyleSelected(style);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            isSelected ? AppTheme.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? AppTheme.primary : Colors.white10,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            style.icon,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                style.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: isSelected
                                      ? AppTheme.accent
                                      : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                style.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.primary,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

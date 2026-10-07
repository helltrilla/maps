import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class MapControlsColumn extends StatelessWidget {
  final VoidCallback onLayerSwitcherPressed;
  final VoidCallback onZoomInPressed;
  final VoidCallback onZoomOutPressed;
  final VoidCallback onMyLocationPressed;
  final bool isFollowingUser;

  const MapControlsColumn({
    super.key,
    required this.onLayerSwitcherPressed,
    required this.onZoomInPressed,
    required this.onZoomOutPressed,
    required this.onMyLocationPressed,
    required this.isFollowingUser,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Переключатель слоев
        FloatingActionButton.small(
          heroTag: 'layers_fab',
          onPressed: onLayerSwitcherPressed,
          tooltip: 'Слои карты',
          backgroundColor: AppTheme.surface,
          child: const Icon(Icons.layers_rounded, color: Colors.white),
        ),
        const SizedBox(height: 10),

        // Зум +
        FloatingActionButton.small(
          heroTag: 'zoom_in_fab',
          onPressed: onZoomInPressed,
          tooltip: 'Приблизить',
          backgroundColor: AppTheme.surface,
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
        const SizedBox(height: 8),

        // Зум -
        FloatingActionButton.small(
          heroTag: 'zoom_out_fab',
          onPressed: onZoomOutPressed,
          tooltip: 'Отдалить',
          backgroundColor: AppTheme.surface,
          child: const Icon(Icons.remove_rounded, color: Colors.white),
        ),
        const SizedBox(height: 12),

        // Мое местоположение
        FloatingActionButton(
          heroTag: 'my_location_fab',
          onPressed: onMyLocationPressed,
          tooltip: isFollowingUser ? 'Слежение активно' : 'Мое местоположение',
          backgroundColor: isFollowingUser ? AppTheme.accent : AppTheme.surface,
          child: Icon(
            isFollowingUser ? Icons.near_me_rounded : Icons.my_location_rounded,
            color: isFollowingUser ? Colors.black : AppTheme.accent,
          ),
        ),
      ],
    );
  }
}

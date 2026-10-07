import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';

class PointPickerOverlay extends StatelessWidget {
  final bool pickingForStart;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const PointPickerOverlay({
    super.key,
    required this.pickingForStart,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Центральный прицел
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
                      color: pickingForStart
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (pickingForStart
                                  ? Colors.greenAccent
                                  : Colors.redAccent)
                              .withAlpha(160),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      pickingForStart
                          ? Icons.play_arrow_rounded
                          : Icons.flag_rounded,
                      color: Colors.black,
                      size: 26,
                    ),
                  ),
                  Container(
                    width: 3.5,
                    height: 14,
                    decoration: BoxDecoration(
                      color: pickingForStart
                          ? Colors.greenAccent
                          : Colors.redAccent,
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

        // Верхняя плашка управления
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: pickingForStart
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
                          color: (pickingForStart
                                  ? Colors.greenAccent
                                  : Colors.redAccent)
                              .withAlpha(35),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          pickingForStart
                              ? Icons.trip_origin_rounded
                              : Icons.place_rounded,
                          color: pickingForStart
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pickingForStart
                                  ? AppStrings.pickStartPoint
                                  : AppStrings.pickDestinationPoint,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              AppStrings.moveMapHint,
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(AppStrings.cancel),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pickingForStart
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text(
                            AppStrings.selectThisPoint,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

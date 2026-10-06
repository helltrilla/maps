import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:flutter_map/flutter_map.dart';

class MapMarkerWidgets {
  /// Стильный анимированный маркер в стиле Яндекс Карт:
  /// пульсирующий радар, направление движения (heading) и навигационная стрелка
  static Marker buildUserLocationMarker(
    LatLng position, {
    double heading = 0.0,
    double speed = 0.0,
  }) {
    return Marker(
      point: position,
      width: 58,
      height: 58,
      child: UserLocationMarkerWidget(
        heading: heading,
        speed: speed,
      ),
    );
  }

  /// Маркер сохраненной точки пользователя
  static Marker buildSavedMarker({
    required LatLng position,
    required String title,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    return Marker(
      point: position,
      width: 40,
      height: 46,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            Positioned(
              bottom: 2,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Маркер заведения или объекта поиска
  static Marker buildPlaceMarker({
    required LatLng position,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Marker(
      point: position,
      width: 36,
      height: 36,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class UserLocationMarkerWidget extends StatefulWidget {
  final double heading;
  final double speed;

  const UserLocationMarkerWidget({
    super.key,
    this.heading = 0.0,
    this.speed = 0.0,
  });

  @override
  State<UserLocationMarkerWidget> createState() => _UserLocationMarkerWidgetState();
}

class _UserLocationMarkerWidgetState extends State<UserLocationMarkerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.65, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasHeading = widget.heading > 0;
    final double headingRad = widget.heading * (3.141592653589793 / 180.0);

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Пульсирующий ореол (радар)
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF3B82F6).withValues(alpha: _opacityAnimation.value * 0.35),
                    border: Border.all(
                      color: const Color(0xFF60A5FA).withValues(alpha: _opacityAnimation.value * 0.75),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              // 2. Конус направления взгляда / движения (как в Яндекс Картах)
              if (hasHeading)
                Transform.rotate(
                  angle: headingRad,
                  child: CustomPaint(
                    size: const Size(56, 56),
                    painter: _HeadingConePainter(),
                  ),
                ),

              // 3. Ядро: стрелка навигатора при движении или яркая синяя точка
              if (hasHeading && widget.speed > 0.4)
                Transform.rotate(
                  angle: headingRad,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      painter: _YandexNavigationArrowPainter(),
                    ),
                  ),
                )
              else
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                      center: Alignment(-0.2, -0.2),
                    ),
                    border: Border.all(color: Colors.white, width: 2.8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x662563EB),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HeadingConePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF3B82F6).withValues(alpha: 0.4),
          const Color(0xFF3B82F6).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        -1.5707963267948966 - 0.45,
        0.9,
        false,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _YandexNavigationArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF38BDF8), Color(0xFF1D4ED8)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(w / 2, 2)
      ..lineTo(w - 3, h - 3)
      ..lineTo(w / 2, h - 8)
      ..lineTo(3, h - 3)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

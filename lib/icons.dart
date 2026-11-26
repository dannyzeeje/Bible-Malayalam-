part of 'main.dart';

class AppIcon extends StatelessWidget {
  final IconData? icon;
  final double? size;
  final Color? color;
  const AppIcon(this.icon, {super.key, this.size, this.color});
  @override
  Widget build(BuildContext context) => Icon(icon, size: size, color: color);
}

/// Padded, symmetric open Bible with a cross formed by negative space.
class BibleMark extends StatelessWidget {
  const BibleMark({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Bible',
    image: true,
    child: CustomPaint(
      size: const Size(120, 120),
      painter: _BibleMarkPainter(uiInk(context)),
    ),
  );
}

class _BibleMarkPainter extends CustomPainter {
  final Color color;
  _BibleMarkPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 110, size.height / 110);
    final page = Path()
      ..moveTo(32, 32)
      ..quadraticBezierTo(28, 32, 28, 36)
      ..lineTo(28, 71)
      ..quadraticBezierTo(28, 75, 32, 75)
      ..quadraticBezierTo(44, 74, 53, 81)
      ..lineTo(53, 52)
      ..lineTo(48, 52)
      ..quadraticBezierTo(46, 52, 46, 50)
      ..quadraticBezierTo(46, 48, 48, 48)
      ..lineTo(53, 48)
      ..lineTo(53, 42)
      ..quadraticBezierTo(49, 33, 32, 32)
      ..close();
    final ink = Paint()..color = color;
    canvas.drawPath(page, ink);
    canvas.translate(110, 0);
    canvas.scale(-1, 1);
    canvas.drawPath(page, ink);
  }

  @override
  bool shouldRepaint(covariant _BibleMarkPainter old) => old.color != color;
}

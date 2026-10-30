part of 'main.dart';

class AppIcon extends StatelessWidget {
  final IconData? icon;
  final double? size;
  final Color? color;
  const AppIcon(this.icon, {super.key, this.size, this.color});
  @override
  Widget build(BuildContext context) {
    final custom =
        icon == CupertinoIcons.checkmark ||
        icon == CupertinoIcons.xmark ||
        icon == CupertinoIcons.doc_on_doc;
    if (!custom) return Icon(icon, size: size, color: color);
    final theme = IconTheme.of(context);
    final dimension = size ?? theme.size ?? 20;
    return Semantics(
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: dimension,
        child: CustomPaint(
          painter: ActionGlyphPainter(
            icon!,
            color ?? theme.color ?? uiInk(context),
          ),
        ),
      ),
    );
  }
}

class ActionGlyphPainter extends CustomPainter {
  final IconData icon;
  final Color color;
  ActionGlyphPainter(this.icon, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.65
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (icon == CupertinoIcons.checkmark) {
      canvas.drawPath(
        Path()
          ..moveTo(5, 12)
          ..lineTo(10, 17)
          ..lineTo(19, 7),
        p,
      );
    } else if (icon == CupertinoIcons.xmark) {
      canvas.drawLine(const Offset(6, 6), const Offset(18, 18), p);
      canvas.drawLine(const Offset(18, 6), const Offset(6, 18), p);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(8, 8, 12, 13),
          const Radius.circular(2.5),
        ),
        p,
      );
      canvas.drawPath(
        Path()
          ..moveTo(5, 16)
          ..lineTo(4, 16)
          ..quadraticBezierTo(3, 16, 3, 14)
          ..lineTo(3, 5)
          ..quadraticBezierTo(3, 3, 5, 3)
          ..lineTo(14, 3)
          ..quadraticBezierTo(16, 3, 16, 5),
        p,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ActionGlyphPainter old) =>
      old.icon != icon || old.color != color;
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

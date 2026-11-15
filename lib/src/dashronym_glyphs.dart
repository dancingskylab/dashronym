import 'package:flutter/foundation.dart' show internal;
import 'package:flutter/widgets.dart';

/// Glyphs that Dashronym paints itself, so the stock card needs no icon font.
@internal
enum DashronymGlyph {
  /// An outlined circle with a lowercase "i".
  info,

  /// A diagonal cross.
  close,
}

/// A decorative, font-free icon used by the stock tooltip card.
///
/// Glyphs are excluded from semantics; the controls that use them carry their
/// own labels.
@internal
class DashronymGlyphIcon extends StatelessWidget {
  /// Creates a glyph of [size] logical pixels painted in [color].
  const DashronymGlyphIcon(
    this.glyph, {
    super.key,
    required this.color,
    this.size = 24,
  });

  /// The glyph to paint.
  final DashronymGlyph glyph;

  /// The glyph color.
  final Color color;

  /// The width and height of the glyph.
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _GlyphPainter(glyph, color)),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph, this.color);

  final DashronymGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw on a 24 x 24 grid, the same grid Material icons use.
    canvas.scale(size.width / 24, size.height / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    switch (glyph) {
      case DashronymGlyph.info:
        final fill = Paint()..color = color;
        canvas
          ..drawCircle(const Offset(12, 12), 9, stroke)
          ..drawRect(const Rect.fromLTWH(11, 11, 2, 6), fill)
          ..drawRect(const Rect.fromLTWH(11, 7, 2, 2), fill);
      case DashronymGlyph.close:
        canvas
          ..drawLine(const Offset(5.7, 5.7), const Offset(18.3, 18.3), stroke)
          ..drawLine(const Offset(18.3, 5.7), const Offset(5.7, 18.3), stroke);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.color != color;
}

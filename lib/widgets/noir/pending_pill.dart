import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import '../../theme/noir.dart';

/// "3 marked · ~11 MB" — a centred pill with a dashed outline, shown while
/// items are marked but not yet deleted. Dashed on purpose: nothing has left
/// the phone yet.
class PendingPill extends StatelessWidget {
  final String text;

  const PendingPill({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        painter: _DashedPillPainter(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_outline_rounded,
                  size: 15, color: Color(0xFFD4D4D8)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: NoirText.family,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD4D4D8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedPillPainter extends CustomPainter {
  static const _dash = 5.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    ).deflate(0.5);
    final paint = Paint()
      ..color = const Color(0x47FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRRect(rrect);
    for (final PathMetric metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final end = (d + _dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(d, end), paint);
        d += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// One step of the onboarding tour: a target widget to highlight + text.
class CoachStep {
  final GlobalKey targetKey;
  final String title;
  final String body;
  const CoachStep({
    required this.targetKey,
    required this.title,
    required this.body,
  });
}

/// Full-screen interactive tour. Dims the screen, highlights the current
/// target with an arrow + explanation, and advances on tap / "Next".
class CoachmarkOverlay extends StatefulWidget {
  final List<CoachStep> steps;
  final String nextLabel;
  final String doneLabel;
  final VoidCallback onFinish;

  const CoachmarkOverlay({
    super.key,
    required this.steps,
    required this.nextLabel,
    required this.doneLabel,
    required this.onFinish,
  });

  @override
  State<CoachmarkOverlay> createState() => _CoachmarkOverlayState();
}

class _CoachmarkOverlayState extends State<CoachmarkOverlay> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // The target render boxes aren't measured until after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      widget.onFinish();
    } else {
      setState(() => _index++);
    }
  }

  Rect? _rectFor(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final rect = _rectFor(step.targetKey);
    final size = MediaQuery.of(context).size;
    final isLast = _index == widget.steps.length - 1;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _next,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _HolePainter(rect))),
          if (rect != null)
            Positioned(
              left: rect.left - 6,
              top: rect.top - 6,
              width: rect.width + 12,
              height: rect.height + 12,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ),
          if (rect != null) _buildBubble(rect, size, step, isLast),
        ],
      ),
    );
  }

  Widget _buildBubble(Rect rect, Size size, CoachStep step, bool isLast) {
    // Put the bubble below the target if the target sits in the upper half.
    final below = rect.center.dy < size.height / 2;
    final arrow =
        below ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    final bubble = Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(arrow, color: AppTheme.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(step.title,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(step.body,
              style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                  height: 1.4)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(
                  widget.steps.length,
                  (i) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _index
                          ? AppTheme.primary
                          : AppTheme.primary.withOpacity(0.25),
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isLast ? widget.doneLabel : widget.nextLabel),
              ),
            ],
          ),
        ],
      ),
    );

    if (below) {
      return Positioned(left: 0, right: 0, top: rect.bottom + 16, child: bubble);
    }
    return Positioned(
        left: 0, right: 0, bottom: size.height - rect.top + 16, child: bubble);
  }
}

/// Paints a dim scrim over the whole screen with a rounded "hole" cut out
/// around the highlighted target.
class _HolePainter extends CustomPainter {
  final Rect? hole;
  _HolePainter(this.hole);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.75);
    if (hole == null) {
      canvas.drawRect(Offset.zero & size, paint);
      return;
    }
    final outer = Path()..addRect(Offset.zero & size);
    final inner = Path()
      ..addRRect(RRect.fromRectAndRadius(
          hole!.inflate(6), const Radius.circular(24)));
    canvas.drawPath(
        Path.combine(ui.PathOperation.difference, outer, inner), paint);
  }

  @override
  bool shouldRepaint(_HolePainter old) => old.hole != hole;
}

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../theme/app_theme.dart';

/// Wrap a screen with this widget to show a quick celebration on demand:
/// a confetti burst from the centre of the screen, a 🎉 that pops in, and the
/// amount of space freed underneath it.
///
/// Reach it with a [GlobalKey] — `CelebrationOverlay.of(context)` searches
/// ancestors, and the overlay is normally built *below* the calling screen's
/// context, so the lookup would return null.
class CelebrationOverlay extends StatefulWidget {
  final Widget child;

  const CelebrationOverlay({super.key, required this.child});

  static CelebrationOverlayState? of(BuildContext context) =>
      context.findAncestorStateOfType<CelebrationOverlayState>();

  @override
  State<CelebrationOverlay> createState() => CelebrationOverlayState();
}

class CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _pop;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  bool _visible = false;
  String _text = '';

  /// Total time the celebration stays on screen. Short, but with an eased
  /// pop-in and fade-out so it doesn't feel abrupt.
  static const Duration _hold = Duration(milliseconds: 1100);

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(milliseconds: 600));
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scale = CurvedAnimation(parent: _pop, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _pop, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _confetti.dispose();
    _pop.dispose();
    super.dispose();
  }

  /// [message] should be short — e.g. "12 MB freed".
  void celebrate(String message) {
    if (!mounted) return;
    setState(() {
      _visible = true;
      _text = message;
    });
    _confetti.play();
    _pop.forward(from: 0);
    Future.delayed(_hold, () async {
      if (!mounted) return;
      await _pop.reverse();
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Confetti bursts from the centre, where the user is looking.
        IgnorePointer(
          child: Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 24,
              gravity: 0.35,
              maxBlastForce: 18,
              minBlastForce: 6,
              colors: const [
                AppTheme.primary,
                AppTheme.secondary,
                AppTheme.success,
                Color(0xFFFFD700),
                Color(0xFF00E5FF),
              ],
              emissionFrequency: 0.25,
              minimumSize: const Size(6, 3),
              maximumSize: const Size(13, 7),
            ),
          ),
        ),
        if (_visible)
          IgnorePointer(
            child: Center(
              // Material ancestor — without it Flutter paints raw Text with an
              // ugly yellow/red dotted underline.
              child: Material(
                type: MaterialType.transparency,
                child: FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 10),
                        Text(
                          _text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 12,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../theme/app_theme.dart';

/// Wrap a screen with this widget to show a confetti burst on demand.
class CelebrationOverlay extends StatefulWidget {
  final Widget child;
  final String freedText;

  const CelebrationOverlay({
    super.key,
    required this.child,
    this.freedText = '',
  });

  static CelebrationOverlayState? of(BuildContext context) =>
      context.findAncestorStateOfType<CelebrationOverlayState>();

  @override
  State<CelebrationOverlay> createState() => CelebrationOverlayState();
}

class CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _badge;
  late final Animation<double> _badgeScale;
  bool _showBadge = false;
  String _badgeText = '';

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _badge = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _badgeScale = CurvedAnimation(parent: _badge, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _confetti.dispose();
    _badge.dispose();
    super.dispose();
  }

  void celebrate(String message) {
    setState(() {
      _showBadge = true;
      _badgeText = message;
    });
    _confetti.play();
    _badge.forward(from: 0);
    Future.delayed(const Duration(seconds: 2, milliseconds: 500), () {
      if (mounted) {
        setState(() => _showBadge = false);
        _badge.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Confetti emitter at the top center
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 40,
            gravity: 0.3,
            colors: const [
              AppTheme.primary,
              AppTheme.secondary,
              AppTheme.success,
              Color(0xFFFFD700),
              Color(0xFF00E5FF),
            ],
            emissionFrequency: 0.3,
            minimumSize: const Size(6, 3),
            maximumSize: const Size(14, 7),
          ),
        ),
        // Floating badge
        if (_showBadge)
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(
              child: ScaleTransition(
                scale: _badgeScale,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.success.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Text(
                        _badgeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

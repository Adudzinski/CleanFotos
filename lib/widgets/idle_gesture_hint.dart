import 'dart:async';

import 'package:flutter/material.dart';

/// A gentle, self-dismissing coach layer for the group-review screens.
///
/// The navigation gestures (pull past the top/bottom of the grid) are
/// invisible, so after a few seconds of no interaction we fade in bouncing
/// arrows and a one-line explanation. Any touch hides it again.
///
/// Wrap the screen body:
/// ```dart
/// IdleGestureHint(
///   idleAfter: Duration(seconds: 4),
///   tapHint: 'Tap a photo to mark it',
///   swipeHint: 'Pull up or down for the next group',
///   child: ...,
/// )
/// ```
class IdleGestureHint extends StatefulWidget {
  final Widget child;
  final String tapHint;
  final String swipeHint;
  final Duration idleAfter;

  /// Set false to suppress the hint (e.g. while a dialog is open).
  final bool enabled;

  const IdleGestureHint({
    super.key,
    required this.child,
    required this.tapHint,
    required this.swipeHint,
    this.idleAfter = const Duration(seconds: 4),
    this.enabled = true,
  });

  @override
  State<IdleGestureHint> createState() => _IdleGestureHintState();
}

class _IdleGestureHintState extends State<IdleGestureHint>
    with SingleTickerProviderStateMixin {
  Timer? _idleTimer;
  bool _show = false;
  late final AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _restartTimer();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _bounce.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _idleTimer?.cancel();
    if (!widget.enabled) return;
    _idleTimer = Timer(widget.idleAfter, () {
      if (mounted) setState(() => _show = true);
    });
  }

  /// Any interaction hides the hint and restarts the idle countdown.
  void _onUserActivity() {
    if (_show) setState(() => _show = false);
    _restartTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onUserActivity(),
      onPointerMove: (_) => _onUserActivity(),
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _show ? 1 : 0,
                duration: const Duration(milliseconds: 450),
                child: Center(
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 26, vertical: 22),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _arrow(Icons.keyboard_arrow_up_rounded, up: true),
                          const SizedBox(height: 2),
                          Text(
                            widget.swipeHint,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          _arrow(Icons.keyboard_arrow_down_rounded, up: false),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.touch_app_rounded,
                                  color: Colors.white70, size: 20),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  widget.tapHint,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Arrow that drifts in the direction it points, so the gesture reads as
  /// "keep pulling this way".
  Widget _arrow(IconData icon, {required bool up}) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_bounce.value);
        return Transform.translate(
          offset: Offset(0, up ? -6 * t : 6 * t),
          child: child,
        );
      },
      child: Icon(icon, color: Colors.white, size: 40),
    );
  }
}

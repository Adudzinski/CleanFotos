import 'dart:async';

import 'package:flutter/material.dart';
import '../../theme/noir.dart';

/// White pill toast, 112 px above the bottom, gone after 1.4 s.
/// Only one is visible at a time: a new toast replaces the current one.
class NoirToast {
  NoirToast._();

  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(BuildContext context, String text) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    hide();
    final entry = OverlayEntry(builder: (_) => _ToastView(text: text));
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(const Duration(milliseconds: 1400), hide);
  }

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _ToastView extends StatelessWidget {
  final String text;
  const _ToastView({required this.text});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bottom = MediaQuery.paddingOf(context).bottom + 112;
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: const ShapeDecoration(
        color: Colors.white,
        shape: StadiumBorder(),
        shadows: [
          BoxShadow(
              color: Color(0x66000000), blurRadius: 30, offset: Offset(0, 10)),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: NoirText.family,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Noir.bg,
        ),
      ),
    );
    return Positioned(
      left: 20,
      right: 20,
      bottom: bottom,
      child: IgnorePointer(
        child: Material(
          type: MaterialType.transparency,
          child: Center(
            child: reduceMotion
                ? pill
                : TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 180),
                    builder: (_, t, child) => Opacity(
                      opacity: t,
                      child: Transform.translate(
                          offset: Offset(0, 8 * (1 - t)), child: child),
                    ),
                    child: pill,
                  ),
          ),
        ),
      ),
    );
  }
}

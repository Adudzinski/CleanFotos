import 'package:flutter/material.dart';
import '../../theme/noir.dart';

/// `surface` card with a hairline border and 24 px radius.
class NoirCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  const NoirCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Noir.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Noir.rCard),
        side: BorderSide(color: borderColor ?? Noir.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Two (or more) pill tabs in a `surface2` track. Selected = white on black.
class NoirSegmented extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const NoirSegmented({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const ShapeDecoration(
        color: Noir.surface2,
        shape: StadiumBorder(),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == selectedIndex,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (i != selectedIndex) onChanged(i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 44,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: ShapeDecoration(
                      color: i == selectedIndex
                          ? Noir.accent
                          : Colors.transparent,
                      shape: const StadiumBorder(),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        labels[i],
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: NoirText.family,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: i == selectedIndex
                              ? Noir.onAccent
                              : Noir.muted,
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
}

/// Screen header: [leading] · centred title (+ subtitle) · [trailing].
class NoirHeader extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const NoirHeader({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    const spacer = SizedBox(width: Noir.iconButton, height: Noir.iconButton);
    return Row(
      children: [
        leading ?? spacer,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: NoirText.bar),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: NoirText.caption.copyWith(
                        fontWeight: FontWeight.w500)),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Keep the title centred: trailing is at least as wide as leading.
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: Noir.iconButton),
          child: Align(
            alignment: Alignment.centerRight,
            widthFactor: 1,
            child: trailing ?? spacer,
          ),
        ),
      ],
    );
  }
}

/// Thin progress bar with pill ends; the fill animates over 300 ms.
class ProgressTrack extends StatelessWidget {
  /// 0.0 – 1.0
  final double value;
  final double height;
  final Color color;

  const ProgressTrack({
    super.key,
    required this.value,
    this.height = 4,
    this.color = Noir.accent,
  });

  /// The 6 px gold variant used for milestones.
  const ProgressTrack.reward({super.key, required this.value, this.height = 6})
      : color = Noir.reward;

  @override
  Widget build(BuildContext context) {
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return LayoutBuilder(builder: (context, c) {
      return Container(
        height: height,
        decoration: const ShapeDecoration(
            color: Noir.surface2, shape: StadiumBorder()),
        alignment: Alignment.centerLeft,
        child: AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          width: c.maxWidth * v,
          height: height,
          decoration: ShapeDecoration(color: color, shape: const StadiumBorder()),
        ),
      );
    });
  }
}

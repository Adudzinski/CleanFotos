import 'package:flutter/material.dart';
import '../../theme/noir.dart';

/// 44×44 round icon button: `surface` fill, 1 px hairline, 20 px icon.
class NoirIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  const NoirIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: Noir.surface,
        shape: const CircleBorder(side: BorderSide(color: Noir.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: Noir.iconButton,
            height: Noir.iconButton,
            child: Icon(icon,
                size: 20, color: enabled ? Noir.text : Noir.faint),
          ),
        ),
      ),
    );
  }
}

enum NoirButtonVariant { primary, danger, secondary, ghost }

/// Pill button, 60 tall (64 with [big]). Pass no [label] for a square
/// icon-only button (e.g. "previous group").
class NoirButton extends StatelessWidget {
  final NoirButtonVariant variant;
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool big;

  /// Fill the available width (default). Icon-only buttons are always square.
  final bool expand;

  /// Overrides the default height (e.g. the 40 px "Remove ads" link).
  final double? height;

  /// Overrides the label style (keeps the variant's colour).
  final TextStyle? textStyle;

  /// Accessibility label for icon-only buttons.
  final String? semanticLabel;

  const NoirButton({
    super.key,
    required this.variant,
    this.label,
    this.icon,
    this.onPressed,
    this.big = false,
    this.expand = true,
    this.height,
    this.textStyle,
    this.semanticLabel,
  });

  const NoirButton.primary({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.big = false,
    this.expand = true,
    this.height,
    this.textStyle,
    this.semanticLabel,
  }) : variant = NoirButtonVariant.primary;

  const NoirButton.danger({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.big = false,
    this.expand = true,
    this.height,
    this.textStyle,
    this.semanticLabel,
  }) : variant = NoirButtonVariant.danger;

  const NoirButton.secondary({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.big = false,
    this.expand = true,
    this.height,
    this.textStyle,
    this.semanticLabel,
  }) : variant = NoirButtonVariant.secondary;

  const NoirButton.ghost({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.big = false,
    this.expand = true,
    this.height,
    this.textStyle,
    this.semanticLabel,
  }) : variant = NoirButtonVariant.ghost;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final (Color bg, Color fg, BorderSide side) = switch (variant) {
      NoirButtonVariant.primary =>
        (Noir.accentStrong, Noir.onAccent, BorderSide.none),
      NoirButtonVariant.danger => (Noir.danger, Colors.white, BorderSide.none),
      NoirButtonVariant.secondary => (
          Noir.surface2,
          Noir.text,
          const BorderSide(color: Noir.line)
        ),
      NoirButtonVariant.ghost => (Colors.transparent, Noir.muted, BorderSide.none),
    };
    final h = height ?? (big ? Noir.bigButton : Noir.button);
    final iconOnly = label == null;

    Widget content;
    if (iconOnly) {
      content = Icon(icon, size: 24, color: fg);
    } else {
      final text = Text(
        label!,
        maxLines: 1,
        style: (textStyle ?? NoirText.button).copyWith(color: fg),
      );
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22, color: fg),
            const SizedBox(width: 10),
          ],
          // Shrinks instead of overflowing at the 1.4 text scale.
          Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: text)),
        ],
      );
    }

    final button = Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: bg,
        shape: iconOnly
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), side: side)
            : StadiumBorder(side: side),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: h,
            width: iconOnly ? h : null,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: iconOnly ? 0 : 20),
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );

    final sized = (!iconOnly && expand)
        ? SizedBox(width: double.infinity, child: button)
        : button;
    return Semantics(
      button: true,
      enabled: enabled,
      label: iconOnly ? semanticLabel : null,
      child: sized,
    );
  }
}

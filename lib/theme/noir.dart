import 'package:flutter/material.dart';

/// Noir — the 1.3 design tokens. Dark-only: this is the app's single theme.
///
/// Values come from the "Noir · feel & rewards" page of the CleanFotos
/// Redesign canvas (copied into REDESIGN_1.3_PLAN.md §2.1).
class Noir {
  Noir._();

  // ── Colours ──────────────────────────────────────────────────────────────
  static const bg = Color(0xFF0A0A0C);
  static const surface = Color(0xFF17171B);
  static const surface2 = Color(0xFF232329);
  static const text = Color(0xFFF4F4F5);

  /// 7.7:1 on [bg] — fine for body copy.
  static const muted = Color(0xFFA1A1AA);

  /// Locked / disabled only — never body text.
  static const faint = Color(0xFF71717A);

  /// 8% white hairline.
  static const line = Color(0x14FFFFFF);

  /// Primary buttons, selected tab, progress.
  static const accent = Color(0xFFFFFFFF);
  static const onAccent = Color(0xFF0A0A0C);

  /// Delete only. White text on it = 4.7:1.
  static const danger = Color(0xFFD63A2C);

  /// Milestones only — nowhere else.
  static const reward = Color(0xFFF5C451);
  static const onReward = Color(0xFF1A1405);

  // ── Radii ────────────────────────────────────────────────────────────────
  static const rCard = 24.0, rPhoto = 28.0, rThumb = 14.0, rPill = 999.0;

  // ── Spacing ──────────────────────────────────────────────────────────────
  static const pad = 20.0, gap = 16.0, gapS = 12.0, gapXS = 8.0;

  // ── Sizes ────────────────────────────────────────────────────────────────
  static const iconButton = 44.0, button = 60.0, bigButton = 64.0;
}

/// Noir typography (Geist). Letter spacing is given in the spec as a multiple
/// of the font size (-0.03em), so it's computed per size here.
class NoirText {
  NoirText._();

  static const String family = 'Geist';

  static double _em(double size, double em) => size * em;

  /// The big "freed" number on the Finished screen.
  static final display = TextStyle(
    fontFamily: family,
    fontSize: 46,
    fontWeight: FontWeight.w600,
    letterSpacing: _em(46, -0.03),
    height: 1.05,
    color: Noir.text,
  );

  /// Home title, Milestones total.
  static final h1 = TextStyle(
    fontFamily: family,
    fontSize: 36,
    fontWeight: FontWeight.w600,
    letterSpacing: _em(36, -0.03),
    height: 1.1,
    color: Noir.text,
  );

  /// Card titles.
  static final h2 = TextStyle(
    fontFamily: family,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: _em(22, -0.03),
    height: 1.2,
    color: Noir.text,
  );

  /// Screen header title.
  static final bar = TextStyle(
    fontFamily: family,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: _em(18, -0.03),
    color: Noir.text,
  );

  static const body = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: Noir.text,
  );

  static const bodyMuted = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: Noir.muted,
  );

  static const secondary = TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: Noir.muted,
  );

  /// Captions, meta, counters (13–14 is intentional, see plan §2.1).
  static const caption = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Noir.muted,
  );

  static const meta = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Noir.muted,
  );

  static const button = TextStyle(
    fontFamily: family,
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );

  /// Upper-case section label (Settings, "MILESTONE REACHED").
  static final label = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: _em(13, 0.06),
    color: Noir.muted,
  );
}

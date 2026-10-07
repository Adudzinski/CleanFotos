import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../models/milestone.dart';
import '../providers/app_provider.dart';
import '../theme/noir.dart';
import '../utils/format.dart';
import '../widgets/noir/noir_widgets.dart';

/// Every milestone tier: reached, current, locked (REDESIGN_1.3_PLAN.md §5.6).
class MilestonesScreen extends StatelessWidget {
  const MilestonesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final s = AppStrings.of(provider.languageCode);
    final lang = provider.languageCode;
    const ladder = Milestone.ladder;

    return Scaffold(
      backgroundColor: Noir.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            NoirHeader(
              leading: NoirIconButton(
                icon: Icons.chevron_left_rounded,
                semanticLabel: s.back,
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: s.milestones,
            ),
            const SizedBox(height: 28),
            Text(formatBytes(provider.freedBytes, lang, ByteRounding.down),
                style: NoirText.h1.copyWith(
                    fontSize: 44, letterSpacing: 44 * -0.03)),
            const SizedBox(height: 4),
            Text(s.freedInTotal(formatCount(provider.deletedCount, lang)),
                style: NoirText.secondary),
            const SizedBox(height: 24),
            NoirCard(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Column(
                children: [
                  for (var i = 0; i < ladder.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, color: Color(0x0FFFFFFF)),
                    _row(context, provider, s, ladder[i]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, AppProvider provider, AppStrings s,
      Milestone m) {
    final lang = provider.languageCode;
    final reached = m.index <= provider.milestoneIndex;
    final current = m.index == provider.milestoneIndex + 1;
    final label = m.label;

    Widget badge;
    Widget title;
    String trailing;

    if (reached) {
      badge = Container(
        width: 36,
        height: 36,
        decoration:
            const BoxDecoration(color: Noir.reward, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, size: 20, color: Noir.onReward),
      );
      title = Text(label,
          style: NoirText.body.copyWith(fontWeight: FontWeight.w600));
      final date = provider.milestoneDates[m.index];
      trailing = date == null ? s.reached : s.reachedOn(s.reachedDate(date));
    } else if (current) {
      final progress = (provider.freedBytes / m.bytes).clamp(0.0, 1.0);
      badge = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Noir.reward, width: 2),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('${(progress * 100).floor()}%',
              style: const TextStyle(
                  fontFamily: NoirText.family,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Noir.reward)),
        ),
      );
      title = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: NoirText.body.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ProgressTrack.reward(value: progress, height: 5),
        ],
      );
      trailing = s.ofTier(
          formatBytes(provider.freedBytes, lang, ByteRounding.down), label);
    } else {
      badge = Container(
        width: 36,
        height: 36,
        decoration:
            const BoxDecoration(color: Noir.surface2, shape: BoxShape.circle),
        child: const Icon(Icons.lock_outline_rounded,
            size: 17, color: Noir.faint),
      );
      title = Text(label, style: NoirText.bodyMuted);
      trailing = s.aboutPhotos(
          formatCount(provider.photosEquivalent(m.bytes), lang));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          badge,
          const SizedBox(width: 14),
          Expanded(child: title),
          const SizedBox(width: 12),
          Flexible(
            child: Text(trailing,
                textAlign: TextAlign.right,
                style: NoirText.caption.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

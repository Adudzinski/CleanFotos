import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../models/delete_result.dart';
import '../models/milestone.dart';
import '../providers/app_provider.dart';
import '../services/feedback_service.dart';
import '../theme/noir.dart';
import '../utils/format.dart';
import '../widgets/noir/noir_widgets.dart';
import 'session.dart';

/// "Finished" — shown after the OS answered the delete prompt
/// (REDESIGN_1.3_PLAN.md §5.5). The celebration lives here, after the
/// deletion is confirmed, never before.
class SessionSummaryScreen extends StatefulWidget {
  final DeleteResult result;
  final MediaKind kind;

  /// Offer "Keep going" (there are more items in the mode).
  final bool canKeepGoing;

  const SessionSummaryScreen({
    super.key,
    required this.result,
    required this.kind,
    this.canKeepGoing = false,
  });

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen>
    with TickerProviderStateMixin {
  late final AnimationController _countUp = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final AnimationController _milestoneIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  Timer? _milestoneTimer;

  bool get _confirmed => widget.result.confirmed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      if (!_confirmed) {
        FeedbackService.instance.play(Fx.declined);
        return;
      }
      FeedbackService.instance.play(Fx.success);
      if (reduceMotion) {
        _countUp.value = 1;
      } else {
        _countUp.forward();
      }
      if (widget.result.newMilestone != null) {
        _milestoneTimer = Timer(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          FeedbackService.instance.play(Fx.milestone);
          if (reduceMotion) {
            _milestoneIn.value = 1;
          } else {
            _milestoneIn.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _milestoneTimer?.cancel();
    _countUp.dispose();
    _milestoneIn.dispose();
    super.dispose();
  }

  void _leave(SummaryChoice choice) => Navigator.of(context).pop(choice);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final s = AppStrings.of(provider.languageCode);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave(SummaryChoice.home);
      },
      child: Scaffold(
        backgroundColor: Noir.bg,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: _confirmed
                      ? _buildConfirmed(context, provider, s)
                      : _buildDeclined(s),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circle({required Color color, required Widget child}) => Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: child,
      );

  Widget _buildConfirmed(
      BuildContext context, AppProvider provider, AppStrings s) {
    final r = widget.result;
    final lang = provider.languageCode;
    final count = formatCount(r.deleted, lang);
    final body = Platform.isIOS
        ? s.movedToRecentlyDeleted(widget.kind, r.deleted, count)
        : r.usedTrash
            ? s.movedToTrash(widget.kind, r.deleted, count)
            : s.deletedPlain(widget.kind, r.deleted, count);

    return Column(
      children: [
        const Spacer(),
        _circle(
          color: Noir.accent,
          child: const Icon(Icons.check_rounded, size: 40, color: Noir.onAccent),
        ),
        const SizedBox(height: 24),
        AnimatedBuilder(
          animation: _countUp,
          builder: (_, __) {
            final shown = (r.bytes * Curves.easeOut.transform(_countUp.value))
                .round();
            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(s.freed(formatBytes(shown, lang)),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: NoirText.display),
            );
          },
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(body,
              textAlign: TextAlign.center, style: NoirText.bodyMuted),
        ),
        if (r.newMilestone != null) ...[
          const SizedBox(height: 28),
          _milestoneCard(provider, s, r.newMilestone!),
        ],
        const Spacer(),
        const SizedBox(height: 24),
        if (widget.canKeepGoing) ...[
          NoirButton.primary(
            label: s.keepGoing,
            onPressed: () => _leave(SummaryChoice.keepGoing),
          ),
          const SizedBox(height: 8),
          NoirButton.ghost(
            label: s.backHome,
            onPressed: () => _leave(SummaryChoice.home),
          ),
        ] else
          NoirButton.primary(
            label: s.backHome,
            onPressed: () => _leave(SummaryChoice.home),
          ),
      ],
    );
  }

  Widget _milestoneCard(AppProvider provider, AppStrings s, Milestone m) {
    final lang = provider.languageCode;
    final total = formatBytes(provider.freedBytes, lang, ByteRounding.down);
    final photos =
        formatCount(provider.photosEquivalent(provider.freedBytes), lang);
    final next = Milestone.after(m.index);

    final card = NoirCard(
      borderColor: Noir.reward.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                    color: Noir.reward, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(m.valueLabel,
                        style: const TextStyle(
                            fontFamily: NoirText.family,
                            fontSize: 17,
                            height: 1.0,
                            fontWeight: FontWeight.w700,
                            color: Noir.onReward)),
                    Text(m.unitLabel,
                        style: const TextStyle(
                            fontFamily: NoirText.family,
                            fontSize: 10,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                            color: Noir.onReward)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.milestoneReached,
                        style: NoirText.label.copyWith(color: Noir.reward)),
                    const SizedBox(height: 4),
                    Text(s.milestoneLine(total, photos), style: NoirText.body),
                  ],
                ),
              ),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(s.nextTier(next.label),
                      style: NoirText.caption),
                ),
                Text(
                    s.toGo(formatBytes(
                        next.bytes - provider.freedBytes, lang, ByteRounding.up)),
                    style: NoirText.caption),
              ],
            ),
            const SizedBox(height: 8),
            ProgressTrack.reward(value: provider.freedBytes / next.bytes),
          ],
        ],
      ),
    );

    return AnimatedBuilder(
      animation: _milestoneIn,
      builder: (_, child) {
        final t = Curves.easeOutCubic.transform(_milestoneIn.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
              offset: Offset(0, 24 * (1 - t)), child: child),
        );
      },
      child: card,
    );
  }

  Widget _buildDeclined(AppStrings s) {
    return Column(
      children: [
        const Spacer(),
        _circle(
          color: Noir.surface2,
          child: const Icon(Icons.info_outline_rounded,
              size: 40, color: Noir.text),
        ),
        const SizedBox(height: 24),
        Text(s.nothingDeleted, textAlign: TextAlign.center, style: NoirText.h1),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(s.nothingDeletedBody(widget.kind),
              textAlign: TextAlign.center, style: NoirText.bodyMuted),
        ),
        const Spacer(),
        const SizedBox(height: 24),
        NoirButton.primary(
          label: s.backHome,
          onPressed: () => _leave(SummaryChoice.home),
        ),
      ],
    );
  }
}

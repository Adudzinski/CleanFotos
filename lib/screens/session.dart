import 'package:flutter/material.dart';
import '../models/delete_result.dart';
import '../models/progress.dart';
import '../providers/app_provider.dart';
import 'session_summary_screen.dart';

export '../models/progress.dart';

/// What the user picked on the Finished screen.
enum SummaryChoice { keepGoing, home }

/// A mode's route result.
///
/// [summary] is set when the mode handed over to the Finished screen: it
/// completes when the user leaves that screen. Home awaits it before showing
/// an interstitial or the review prompt, so neither ever lands on top of the
/// celebration.
class ModeExit {
  final Future<SummaryChoice?>? summary;
  final ResumePoint? resume;
  const ModeExit({this.summary, this.resume});
}

/// The shared "Finish" of every cleanup mode (REDESIGN_1.3_PLAN.md §5.2).
///
/// Nothing marked → straight back to Home. Otherwise: one system delete
/// prompt, then the Finished screen replaces the mode.
Future<void> finishSession(
  BuildContext context, {
  required AppProvider provider,
  required MediaKind kind,
  ResumePoint? resume,
}) async {
  final nav = Navigator.of(context);
  if (!provider.hasPendingDeletions) {
    nav.pop(ModeExit(resume: resume));
    return;
  }
  final result = await provider.flushPendingDeletions();
  if (result.requested == 0) {
    // Everything marked was already gone (deleted elsewhere) — nothing to say.
    nav.pop(ModeExit(resume: resume));
    return;
  }
  final route = MaterialPageRoute<SummaryChoice>(
    builder: (_) => SessionSummaryScreen(
      result: result,
      kind: kind,
      canKeepGoing: resume != null,
    ),
  );
  nav.pushReplacement(route,
      result: ModeExit(summary: route.popped, resume: resume));
}

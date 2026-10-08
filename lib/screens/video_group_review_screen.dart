import 'package:flutter/material.dart';
import '../models/delete_result.dart';
import '../models/photo_group.dart';
import 'group_review_screen.dart';

/// "Similar clips" — the group review for videos; hold a tile to play it
/// inline (REDESIGN_1.3_PLAN.md §5.4).
class VideoGroupReviewScreen extends StatelessWidget {
  final List<PhotoGroup> groups;
  final int startIndex;
  final bool fromNewest;

  const VideoGroupReviewScreen({
    super.key,
    required this.groups,
    this.startIndex = 0,
    this.fromNewest = true,
  });

  @override
  Widget build(BuildContext context) => GroupReviewScreen(
        groups: groups,
        startIndex: startIndex,
        kind: MediaKind.videos,
        fromNewest: fromNewest,
      );
}

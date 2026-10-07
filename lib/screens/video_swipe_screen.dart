import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/delete_result.dart';
import 'swipe_screen.dart';

/// "Swipe" for videos — the same deck as photos, with hold-to-play on
/// the current card (REDESIGN_1.3_PLAN.md §5.3, video variant).
class VideoSwipeScreen extends StatelessWidget {
  final List<AssetEntity> videos;
  final int startIndex;

  const VideoSwipeScreen({
    super.key,
    required this.videos,
    this.startIndex = 0,
  });

  @override
  Widget build(BuildContext context) => SwipeScreen(
        photos: videos,
        startIndex: startIndex,
        kind: MediaKind.videos,
      );
}

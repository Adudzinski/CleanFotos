import 'dart:io' show Platform;

import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

/// Build a player for a gallery asset.
///
/// `contentUri` is Android-only (content:// URIs). On iOS `getMediaUrl()`
/// hands back a file URL, so we must go through the file API instead —
/// otherwise playback silently fails on iPhone.
Future<VideoPlayerController?> buildAssetVideoController(
    AssetEntity asset) async {
  if (Platform.isAndroid) {
    final url = await asset.getMediaUrl();
    if (url == null) return null;
    return VideoPlayerController.contentUri(Uri.parse(url));
  }
  final f = await asset.file;
  if (f == null) return null;
  return VideoPlayerController.file(f);
}

/// "1:07"
String formatVideoDuration(Duration d) {
  final m = d.inMinutes;
  final sec = d.inSeconds % 60;
  return '$m:${sec.toString().padLeft(2, '0')}';
}

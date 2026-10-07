import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../../theme/noir.dart';

/// Up to three thumbnails fanned out (−8°, +5°, 0°) in a 92×120 box — the
/// visual on Home's mode cards. Pass one asset for a single upright thumb.
class ThumbStack extends StatelessWidget {
  final List<AssetEntity> assets;

  const ThumbStack({super.key, required this.assets});

  static const _angles = [-8.0, 5.0, 0.0];

  @override
  Widget build(BuildContext context) {
    final shown = assets.take(3).toList();
    // Draw back to front: with 3 assets the last (0°) sits on top.
    final angles = shown.length == 1
        ? const [0.0]
        : _angles.sublist(3 - (shown.isEmpty ? 3 : shown.length));
    final count = shown.isEmpty ? 3 : shown.length;
    return ExcludeSemantics(
      child: SizedBox(
        width: 92,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < count; i++)
              Transform.rotate(
                angle: angles[i] * math.pi / 180,
                child: _thumb(shown.isEmpty ? null : shown[i]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _thumb(AssetEntity? asset) {
    return Container(
      width: 76,
      height: 96,
      decoration: BoxDecoration(
        color: Noir.surface2,
        borderRadius: BorderRadius.circular(Noir.rThumb),
        border: Border.all(color: Noir.surface, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: asset == null
          ? null
          : AssetEntityImage(
              asset,
              isOriginal: false,
              thumbnailSize: const ThumbnailSize.square(200),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
    );
  }
}

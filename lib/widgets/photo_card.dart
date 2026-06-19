import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../theme/app_theme.dart';

/// Displays a single photo thumbnail with an optional selection overlay.
class PhotoCard extends StatelessWidget {
  final AssetEntity asset;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final double borderRadius;

  const PhotoCard({
    super.key,
    required this.asset,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: selected
              ? Border.all(color: AppTheme.danger, width: 3.5)
              : Border.all(color: Colors.transparent, width: 3.5),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppTheme.danger.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: selected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(borderRadius - 2),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AssetEntityImage(
                asset,
                isOriginal: false,
                thumbnailSize: const ThumbnailSize.square(400),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image_outlined,
                      color: Colors.grey),
                ),
              ),
              // Dark overlay when selected
              if (selected)
                Container(
                  color: AppTheme.danger.withOpacity(0.25),
                  child: const Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.danger,
                        child: Icon(Icons.delete_outline,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen photo viewer dialog.
class PhotoDetailDialog extends StatelessWidget {
  final AssetEntity asset;

  const PhotoDetailDialog({super.key, required this.asset});

  static void show(BuildContext context, AssetEntity asset) {
    showDialog(
      context: context,
      builder: (_) => PhotoDetailDialog(asset: asset),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.9),
          child: Stack(
            children: [
              Center(
                child: Hero(
                  tag: asset.id,
                  child: AssetEntityImage(
                    asset,
                    isOriginal: true,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildMetadata(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadata(BuildContext context) {
    final dt = asset.createDateTime;
    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        dateStr,
        style: const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}

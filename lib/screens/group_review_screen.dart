import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/photo_group.dart';
import '../providers/app_provider.dart';
import '../utils/asset_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/photo_card.dart';
import '../widgets/celebration_overlay.dart';
import '../l10n/strings.dart';

class GroupReviewScreen extends StatefulWidget {
  final List<PhotoGroup> groups;

  const GroupReviewScreen({super.key, required this.groups});

  @override
  State<GroupReviewScreen> createState() => _GroupReviewScreenState();
}

class _GroupReviewScreenState extends State<GroupReviewScreen> {
  late List<PhotoGroup> _groups;
  int _currentIndex = 0;

  /// All photos in the current group (scrollable). Shrinks as photos are deleted.
  final List<AssetEntity> _photos = [];
  /// Selected for deletion
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _groups = List.from(widget.groups);
    _loadGroup(0);
  }

  void _loadGroup(int index) {
    if (index >= _groups.length) return;
    _selectedIds.clear();
    _photos
      ..clear()
      ..addAll(_groups[index].assets);
  }

  PhotoGroup get _currentGroup => _groups[_currentIndex];

  bool get _hasMore => _currentIndex < _groups.length - 1;

  void _toggleSelect(AssetEntity asset) {
    setState(() {
      if (_selectedIds.contains(asset.id)) {
        _selectedIds.remove(asset.id);
      } else {
        _selectedIds.add(asset.id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final provider = context.read<AppProvider>();
    final s = AppStrings.of(provider.languageCode);

    final toDelete =
        _photos.where((a) => _selectedIds.contains(a.id)).toList();
    if (toDelete.isEmpty) return;

    final freed = await provider.deleteAssets(toDelete);

    if (freed == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.deleteFailed)),
        );
      }
      return;
    }

    CelebrationOverlay.of(context)
        ?.celebrate(s.deleted(toDelete.length, _formatBytes(freed)));

    // Remove the deleted photos; the rest reflow up. We do NOT auto-advance —
    // the user stays on this group and taps "Next" when they're done.
    setState(() {
      final del = Set<String>.from(_selectedIds);
      _photos.removeWhere((a) => del.contains(a.id));
      _selectedIds.clear();
    });
  }

  void _advanceGroup() {
    if (_hasMore) {
      setState(() {
        _currentIndex++;
        _loadGroup(_currentIndex);
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final s = AppStrings.of(provider.languageCode);

    if (_groups.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(s.groupMode)),
        body: Center(child: Text(s.allClean)),
      );
    }

    final group = _currentGroup;
    final remaining = _photos.length;
    final totalInGroup = group.totalCount;

    return CelebrationOverlay(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: _buildAppBar(context, s),
        body: Column(
          children: [
            // Progress
            _buildProgressBar(context, s),

            // Group info bar
            _buildGroupInfo(context, group, totalInGroup, remaining, s),

            // Photo grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _buildPhotoGrid(context, s),
              ),
            ),

            // Bottom action bar
            _buildActionBar(context, s),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppStrings s) {
    return AppBar(
      title: Text(s.groupMode),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, AppStrings s) {
    final progress = _groups.isEmpty
        ? 1.0
        : (_currentIndex + 1) / widget.groups.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      color: AppTheme.surface,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.groupOf(
                    _currentIndex + 1, widget.groups.length),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppTheme.primary.withOpacity(0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupInfo(BuildContext context, PhotoGroup group,
      int totalInGroup, int remaining, AppStrings s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      color: AppTheme.surface,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(_groupDisplayDate(group)),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                if (group.location != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 13, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Text(group.location!,
                          style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(BuildContext context, AppStrings s) {
    // All photos in the group, in a scrollable grid (same tile size as before).
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: _photos.length,
      itemBuilder: (context, i) {
        final asset = _photos[i];
        final selected = _selectedIds.contains(asset.id);
        return PhotoCard(
          asset: asset,
          selected: selected,
          onTap: () => _toggleSelect(asset),
          onLongPress: () => PhotoDetailDialog.show(context, asset),
        );
      },
    );
  }

  Widget _buildActionBar(BuildContext context, AppStrings s) {
    final selectedCount = _selectedIds.length;
    final hasSelection = selectedCount > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hint text
          Text(
            hasSelection
                ? s.tapToDeselect
                : s.tapToSelectDelete,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 17,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            s.recoverHint,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Continue / Next
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: _advanceGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(s.continueBtn, maxLines: 1),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Delete
              Expanded(
                flex: 4,
                child: ElevatedButton.icon(
                  onPressed: hasSelection ? _deleteSelected : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.danger,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.danger.withOpacity(0.4),
                    disabledForegroundColor: Colors.white70,
                    minimumSize: const Size.fromHeight(56),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      hasSelection ? s.deleteCount(selectedCount) : s.deleteBtn,
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DateTime _groupDisplayDate(PhotoGroup group) {
    return group.assets
        .map(librarySortTime)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

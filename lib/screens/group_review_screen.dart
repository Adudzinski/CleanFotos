import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/photo_group.dart';
import '../providers/app_provider.dart';
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

  /// The 4 assets currently visible
  final List<AssetEntity> _visible = [];
  /// Assets queued but not yet visible (rest of the group)
  final List<AssetEntity> _queue = [];
  /// Selected for deletion
  final Set<String> _selectedIds = {};

  static const int _pageSize = 4;

  @override
  void initState() {
    super.initState();
    _groups = List.from(widget.groups);
    _loadGroup(0);
  }

  void _loadGroup(int index) {
    if (index >= _groups.length) return;
    final group = _groups[index];
    _selectedIds.clear();

    final all = group.assets;
    _visible.clear();
    _visible.addAll(all.take(_pageSize));
    _queue.clear();
    _queue.addAll(all.skip(_pageSize));
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
    final lang = provider.languageCode;
    final s = AppStrings.of(lang);

    final toDelete =
        _visible.where((a) => _selectedIds.contains(a.id)).toList();

    final freed = await provider.deleteAssets(toDelete);

    // Celebration
    final celebrationState = CelebrationOverlay.of(context);
    final msg = s.deleted(toDelete.length, _formatBytes(freed));
    celebrationState?.celebrate(msg);

    // Remove deleted from visible, fill from queue
    _visible.removeWhere((a) => _selectedIds.contains(a.id));
    _selectedIds.clear();

    // Fill up to _pageSize from queue
    while (_visible.length < _pageSize && _queue.isNotEmpty) {
      _visible.add(_queue.removeAt(0));
    }

    // If group now has < 2 visible, move on
    if (_visible.length < 2) {
      _advanceGroup();
    } else {
      setState(() {});
    }
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

  void _skipGroup() {
    context.read<AppProvider>().skipGroup(_currentGroup.id);
    if (_hasMore) {
      setState(() {
        _groups.removeAt(_currentIndex);
        if (_currentIndex >= _groups.length) {
          _currentIndex = _groups.length - 1;
        }
        if (_groups.isEmpty) {
          Navigator.pop(context);
          return;
        }
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
    final remaining = _queue.length + _visible.length;
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
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                    fontSize: 13,
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
                  _formatDate(group.groupDate),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                if (group.location != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Text(group.location!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (group.savingsBytes > 0) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.savings_outlined,
                      size: 15, color: AppTheme.success),
                  const SizedBox(width: 5),
                  Text(
                    s.saveUpTo(group.savingsFormatted),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.success),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              s.photosInGroup(totalInGroup),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(BuildContext context, AppStrings s) {
    final int count = _visible.length;
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemCount: count,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, i) {
        final asset = _visible[i];
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
            style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Continue / Skip
              Expanded(
                child: OutlinedButton(
                  onPressed: _skipGroup,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    foregroundColor: AppTheme.textSecondary,
                    side: const BorderSide(color: AppTheme.textSecondary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  child: Text(s.continueBtn),
                ),
              ),
              const SizedBox(width: 12),
              // Delete
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: hasSelection ? _deleteSelected : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasSelection
                        ? AppTheme.danger
                        : AppTheme.danger.withOpacity(0.4),
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: Text(hasSelection
                      ? s.deleteCount(selectedCount)
                      : s.deleteBtn),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

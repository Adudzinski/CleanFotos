import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../models/photo_group.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/celebration_overlay.dart';
import '../l10n/strings.dart';

class SwipeScreen extends StatefulWidget {
  final List<PhotoGroup> groups;

  const SwipeScreen({super.key, required this.groups});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen>
    with TickerProviderStateMixin {
  // Flatten all duplicate assets into one queue, newest first
  late final List<AssetEntity> _queue;
  int _current = 0;

  // Drag state
  double _dragX = 0;
  double _dragY = 0;
  bool _isDragging = false;

  // Decision animation
  late AnimationController _flyOut;
  late Animation<Offset> _flyOffset;
  late Animation<double> _flyRotation;
  bool _flyingLeft = false;

  int _deletedCount = 0;
  int _freedBytes = 0;

  // Photos swiped to delete are queued and removed in ONE batch (a single
  // system permission dialog) when the user finishes or leaves.
  final List<AssetEntity> _pendingDelete = [];
  late final AppProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<AppProvider>();
    // Flatten all group assets (skip the "best" first photo per group)
    _queue = widget.groups
        .expand((g) => g.assets.skip(1)) // skip first as "keep" candidate
        .toList();

    _flyOut = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _flyOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(2.5, -0.5),
    ).animate(CurvedAnimation(parent: _flyOut, curve: Curves.easeIn));
    _flyRotation = Tween<double>(begin: 0, end: 0.4).animate(
      CurvedAnimation(parent: _flyOut, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    // Flush any queued deletions if the user leaves before finishing.
    _commitDeletions();
    _flyOut.dispose();
    super.dispose();
  }

  /// Delete all queued photos in one batch (one permission dialog).
  Future<void> _commitDeletions() async {
    if (_pendingDelete.isEmpty) return;
    final batch = List<AssetEntity>.from(_pendingDelete);
    _pendingDelete.clear();
    await _provider.deleteAssets(batch);
  }

  bool get _done => _current >= _queue.length;

  Future<void> _swipeLeft() async {
    // Delete
    _flyingLeft = true;
    _flyOffset = Tween<Offset>(
      begin: Offset(_dragX / 300, _dragY / 300),
      end: const Offset(-3, -0.3),
    ).animate(CurvedAnimation(parent: _flyOut, curve: Curves.easeIn));
    _flyRotation = Tween<double>(begin: _dragX / 1000, end: -0.5).animate(
      CurvedAnimation(parent: _flyOut, curve: Curves.easeIn),
    );
    await _flyOut.forward(from: 0);
    _flyOut.reset();

    // Queue for batch deletion (don't hit the OS dialog per swipe).
    _pendingDelete.add(_queue[_current]);
    _deletedCount++;
    _freedBytes += kAvgPhotoBytes;

    final s = AppStrings.of(_provider.languageCode);
    CelebrationOverlay.of(context)
        ?.celebrate(s.deleted(1, _formatBytes(kAvgPhotoBytes)));

    setState(() {
      _current++;
      _dragX = 0;
      _dragY = 0;
      _isDragging = false;
    });

    if (_current >= _queue.length) await _commitDeletions();
  }

  void _swipeRight() async {
    // Keep (skip)
    _flyingLeft = false;
    _flyOffset = Tween<Offset>(
      begin: Offset(_dragX / 300, _dragY / 300),
      end: const Offset(3, -0.3),
    ).animate(CurvedAnimation(parent: _flyOut, curve: Curves.easeIn));
    _flyRotation = Tween<double>(begin: _dragX / 1000, end: 0.5).animate(
      CurvedAnimation(parent: _flyOut, curve: Curves.easeIn),
    );
    await _flyOut.forward(from: 0);
    _flyOut.reset();

    setState(() {
      _current++;
      _dragX = 0;
      _dragY = 0;
      _isDragging = false;
    });

    if (_current >= _queue.length) await _commitDeletions();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() {
      _dragX += d.delta.dx;
      _dragY += d.delta.dy;
      _isDragging = true;
    });
  }

  void _onDragEnd(DragEndDetails d) {
    const threshold = 100.0;
    if (_dragX < -threshold) {
      _swipeLeft();
    } else if (_dragX > threshold) {
      _swipeRight();
    } else {
      // Snap back
      setState(() {
        _dragX = 0;
        _dragY = 0;
        _isDragging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final s = AppStrings.of(provider.languageCode);

    return CelebrationOverlay(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(s.swipeMode,
              style: const TextStyle(color: Colors.white)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_queue.length - _current} ${s.remaining}',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
        body: _done ? _buildDoneScreen(context, s) : _buildSwipeArea(context, s),
      ),
    );
  }

  Widget _buildSwipeArea(BuildContext context, AppStrings s) {
    final size = MediaQuery.of(context).size;
    final asset = _queue[_current];

    // Determine overlay opacity based on drag
    final deleteOpacity = (_dragX < 0 ? (-_dragX / 120).clamp(0.0, 1.0) : 0.0);
    final keepOpacity = (_dragX > 0 ? (_dragX / 120).clamp(0.0, 1.0) : 0.0);

    return Column(
      children: [
        // Card area
        Expanded(
          child: GestureDetector(
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Next card (peek behind)
                if (_current + 1 < _queue.length)
                  Positioned.fill(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                      child: _buildCard(_queue[_current + 1], 0, 0, 0),
                    ),
                  ),

                // Current card
                AnimatedBuilder(
                  animation: _flyOut,
                  builder: (context, _) {
                    final extraX =
                        _flyOut.isAnimating ? _flyOffset.value.dx * 300 : 0.0;
                    final extraY =
                        _flyOut.isAnimating ? _flyOffset.value.dy * 300 : 0.0;
                    final rot = _flyOut.isAnimating
                        ? _flyRotation.value
                        : _dragX / 2000;

                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..translate(_dragX + extraX, _dragY + extraY)
                        ..rotateZ(rot),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                        child: _buildCard(asset, deleteOpacity, keepOpacity,
                            _dragX / 1000),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Bottom buttons & instructions
        _buildBottomBar(context, s),
      ],
    );
  }

  Widget _buildCard(AssetEntity asset, double deleteOpacity,
      double keepOpacity, double rotation) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AssetEntityImage(
            asset,
            isOriginal: false,
            thumbnailSize: const ThumbnailSize(800, 1200),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade900,
              child: const Icon(Icons.broken_image_outlined,
                  color: Colors.grey, size: 64),
            ),
          ),
          // Delete overlay (red, swipe left)
          if (deleteOpacity > 0)
            Container(
              color: AppTheme.danger.withOpacity(deleteOpacity * 0.6),
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.all(28),
              child: Transform.rotate(
                angle: -0.3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: AppTheme.danger, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'DELETE',
                    style: TextStyle(
                      color: AppTheme.danger.withOpacity(deleteOpacity),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          // Keep overlay (green, swipe right)
          if (keepOpacity > 0)
            Container(
              color: AppTheme.success.withOpacity(keepOpacity * 0.6),
              alignment: Alignment.topRight,
              padding: const EdgeInsets.all(28),
              child: Transform.rotate(
                angle: 0.3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppTheme.success, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'KEEP',
                    style: TextStyle(
                      color: AppTheme.success.withOpacity(keepOpacity),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          // Date at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              child: Text(
                _formatDate(asset.createDateTime),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, AppStrings s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 36),
      color: Colors.black,
      child: Column(
        children: [
          Text(
            s.swipeHint,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            s.recoverHint,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionBtn(
                icon: Icons.delete_outline,
                label: s.swipeDelete,
                color: AppTheme.danger,
                onTap: _swipeLeft,
              ),
              // Counter
              Column(
                children: [
                  Text(
                    '$_deletedCount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800),
                  ),
                  Text(s.deleted_noun,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 16)),
                ],
              ),
              _buildActionBtn(
                icon: Icons.check_circle_outline,
                label: s.swipeKeep,
                color: AppTheme.success,
                onTap: _swipeRight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.15),
          border: Border.all(color: color, width: 2.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneScreen(BuildContext context, AppStrings s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 24),
            Text(
              s.swipeDone,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              s.deleted(_deletedCount, _formatBytes(_freedBytes)),
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.backHome),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

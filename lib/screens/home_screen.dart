import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../providers/app_provider.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../services/purchase_service.dart';
import '../services/video_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/coachmark_overlay.dart';
import 'group_review_screen.dart';
import 'swipe_screen.dart';
import 'video_swipe_screen.dart';
import 'settings_screen.dart';
import '../l10n/strings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Targets for the first-launch onboarding tour.
  final GlobalKey _groupCardKey = GlobalKey();
  final GlobalKey _swipeCardKey = GlobalKey();

  final VideoService _videoService = VideoService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().prepare();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final lang = provider.languageCode;
    final s = AppStrings.of(lang);

    final showCoach = provider.state == AppState.ready &&
        !provider.onboardingSeen &&
        provider.stats.totalPhotos > 0;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, provider, s),
                Expanded(
                  child: _buildBody(context, provider, s),
                ),
                if (provider.adsEnabled)
                  const SafeArea(top: false, child: BannerAdWidget()),
              ],
            ),
          ),
          if (showCoach)
            Positioned.fill(
              child: CoachmarkOverlay(
                steps: [
                  CoachStep(
                      targetKey: _groupCardKey,
                      title: s.groupMode,
                      body: s.groupModeDesc),
                  CoachStep(
                      targetKey: _swipeCardKey,
                      title: s.swipeMode,
                      body: s.swipeModeDesc),
                ],
                nextLabel: s.coachNext,
                doneLabel: s.coachDone,
                onFinish: () => provider.markOnboardingSeen(),
              ),
            ),
        ],
      ),
    );
  }

  /// Called when returning from a cleanup mode.
  ///
  /// We do NOT re-run the full analysis here — deletions already update the
  /// groups live, so re-scanning would just show a loading screen and lose the
  /// user's place. We only show a quick interstitial. (The user can still pull
  /// "Refresh" for a fresh scan.)
  void _afterMode(AppProvider provider) {
    if (provider.adsEnabled) AdService.instance.showInterstitial();
  }

  /// Open a cleanup mode, loading + grouping the photos on demand. If grouping
  /// hasn't run yet, we show a brief loading dialog while it does (this is the
  /// only point we touch the whole library), then navigate.
  Future<void> _openMode(
    BuildContext context,
    AppProvider provider,
    AppStrings s, {
    required bool swipe,
  }) async {
    if (!provider.groupsLoaded) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
      await provider.ensureGroups();
      if (!context.mounted) return;
      Navigator.of(context).pop(); // close the loading dialog
    }

    final groups = provider.groups;
    if (groups.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.allClean)));
      return;
    }

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            swipe ? SwipeScreen(groups: groups) : GroupReviewScreen(groups: groups),
      ),
    ).then((_) => _afterMode(provider));
  }

  /// Load all videos on demand, then open the video swipe deck.
  Future<void> _openVideoMode(
      BuildContext context, AppProvider provider, AppStrings s) async {
    final access = await _videoService.ensureAccess();
    if (!context.mounted) return;

    // No access at all → send the user to settings with a clear explanation.
    if (access == VideoAccess.denied) {
      await _showVideoAccessDialog(context, s);
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: kVideoAccent),
      ),
    );
    final videos = await _videoService.loadAllVideos();
    if (!context.mounted) return;
    Navigator.of(context).pop(); // close loading dialog

    if (videos.isEmpty) {
      // No usable videos almost always means partial/insufficient access on
      // Android 13+, so guide the user to grant full access rather than
      // misleadingly saying "all clean".
      await _showVideoAccessDialog(context, s);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoSwipeScreen(videos: videos)),
    ).then((_) => _afterMode(provider));
  }

  /// Explains that full video access is needed and offers to open Settings.
  Future<void> _showVideoAccessDialog(
      BuildContext context, AppStrings s) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.videoAccessTitle),
        content: Text(s.videoAccessBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.notNow),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _videoService.openSettings();
            },
            child: Text(s.openSettings),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, AppProvider provider, AppStrings s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      color: AppTheme.surface,
      child: Row(
        children: [
          // Logo + title
          Image.asset(
            'assets/icon/icon_header.png',
            width: 44,
            height: 44,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Text(
            'CleanPics',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 26),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, AppProvider provider, AppStrings s) {
    switch (provider.state) {
      case AppState.loading:
        return _buildLoading(s);
      case AppState.permissionDenied:
        return _buildPermissionDenied(context, s);
      case AppState.error:
        return _buildError(context, s, provider);
      case AppState.ready:
        return _buildReady(context, provider, s);
      case AppState.initial:
        return _buildInitial(context, provider, s);
    }
  }

  Widget _buildLoading(AppStrings s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primary),
          const SizedBox(height: 24),
          Text(s.analyzingPhotos,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildInitial(
      BuildContext context, AppProvider provider, AppStrings s) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.photo_library_outlined,
                  color: Colors.white, size: 64),
            ),
          ),
          const SizedBox(height: 36),
          Text(s.welcomeTitle,
              style: Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(s.welcomeSubtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppTheme.textSecondary, height: 1.5),
              textAlign: TextAlign.center),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: () => provider.prepare(),
            icon: const Icon(Icons.search_rounded, size: 22),
            label: Text(s.startAnalysis),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied(BuildContext context, AppStrings s) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 72, color: AppTheme.textSecondary),
          const SizedBox(height: 24),
          Text(s.permissionTitle,
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(s.permissionBody,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => PhotoManager.openSetting(),
            child: Text(s.openSettings),
          ),
        ],
      ),
    );
  }

  Widget _buildError(
      BuildContext context, AppStrings s, AppProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.danger),
          const SizedBox(height: 16),
          Text(s.errorMessage,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => provider.prepare(),
            child: Text(s.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildReady(
      BuildContext context, AppProvider provider, AppStrings s) {
    final groupCount = provider.groups.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cleanup actions (front and center) ───────────────────────────
          // The modes load + group photos on demand (see _openMode), so they're
          // available as soon as the library has photos — no upfront scan.
          if (!provider.groupsLoaded || groupCount > 0) ...[
            // Group review mode
            _buildModeCard(
              context,
              cardKey: _groupCardKey,
              icon: Icons.grid_view_rounded,
              title: s.groupMode,
              subtitle: s.groupModeDesc,
              gradient: const [AppTheme.primary, AppTheme.primaryDark],
              enabled: provider.stats.totalPhotos > 0,
              onTap: () => _openMode(context, provider, s, swipe: false),
            ),
            const SizedBox(height: 14),

            // Swipe mode
            _buildModeCard(
              context,
              cardKey: _swipeCardKey,
              icon: Icons.swipe_rounded,
              title: s.swipeMode,
              subtitle: s.swipeModeDesc,
              gradient: const [AppTheme.secondary, Color(0xFFE84A6F)],
              enabled: provider.stats.totalPhotos > 0,
              onTap: () => _openMode(context, provider, s, swipe: true),
            ),
          ],

          // Video cleanup — its own distinct mode, always available.
          const SizedBox(height: 14),
          _buildModeCard(
            context,
            icon: Icons.video_library_rounded,
            title: s.videoMode,
            subtitle: s.videoModeDesc,
            gradient: const [kVideoAccent, Color(0xFF0E9E88)],
            enabled: true,
            onTap: () => _openVideoMode(context, provider, s),
          ),

          if (provider.groupsLoaded && groupCount == 0) ...[
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 64, color: AppTheme.success),
                  const SizedBox(height: 16),
                  Text(s.allClean,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Pro upsell (above Refresh) — hidden once the user has removed ads.
          if (!provider.isPro) ...[
            _buildProPromo(context, s),
            const SizedBox(height: 14),
          ],

          // Refresh (beneath the Remove Ads button)
          OutlinedButton.icon(
            onPressed: () => provider.refresh(),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(s.refresh),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 28),

          // Lifetime saved summary (above the stats, neutral stat-card style)
          _buildSavedSummary(context, provider, s),
          const SizedBox(height: 14),

          // ── Stats (below the actions) ─────────────────────────────────────
          Row(
            children: [
              _buildStatCard(
                context,
                icon: Icons.photo_library_outlined,
                label: s.totalPhotos,
                value: '${provider.stats.totalPhotos}',
                color: AppTheme.primary,
              ),
              const SizedBox(width: 14),
              _buildStatCard(
                context,
                icon: Icons.storage_outlined,
                label: s.librarySize,
                value: provider.stats.totalSizeFormatted,
                color: const Color(0xFF43A8D0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Pro upsell card — same colored, white-on-gradient style as the mode cards,
  /// in a distinct amber. Tapping it goes straight to the Play Billing purchase
  /// sheet; if billing isn't ready yet it falls back to Settings (Restore lives
  /// there too).
  Widget _buildProPromo(BuildContext context, AppStrings s) {
    return _buildModeCard(
      context,
      icon: Icons.block_rounded,
      title: s.removeAds,
      subtitle: s.proTitle,
      gradient: const [Color(0xFFFFA33F), Color(0xFFF57C00)],
      enabled: true,
      onTap: () {
        final purchase = PurchaseService.instance;
        if (purchase.isAvailable) {
          purchase.buyPro();
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        }
      },
    );
  }

  /// Wide "how much you've saved" card. Always visible, styled to match the
  /// neutral stat cards below it (white surface, soft shadow) but full-width,
  /// with a celebratory icon so the user feels good about what they've cleaned.
  Widget _buildSavedSummary(
      BuildContext context, AppProvider provider, AppStrings s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.success.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 34)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.freedSpace,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  provider.freedFormatted,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${s.deletedPhotos}: ${provider.deletedCount}',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    Key? cardKey,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: cardKey,
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.4),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.4)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.9), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

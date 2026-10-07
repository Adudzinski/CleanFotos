import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../models/delete_result.dart';
import '../models/photo_group.dart';
import '../providers/app_provider.dart';
import '../services/ad_service.dart';
import '../services/feedback_service.dart';
import '../services/purchase_service.dart';
import '../services/review_service.dart';
import '../services/video_service.dart';
import '../theme/noir.dart';
import '../utils/asset_utils.dart';
import '../utils/format.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/noir/noir_widgets.dart';
import 'group_review_screen.dart';
import 'milestones_screen.dart';
import 'session.dart';
import 'session_summary_screen.dart';
import 'settings_screen.dart';
import 'swipe_screen.dart';
import 'video_group_review_screen.dart';
import 'video_swipe_screen.dart';

/// Home (REDESIGN_1.3_PLAN.md §5.1): freshness line, Photos/Videos tabs, two
/// mode cards and the next milestone. It explains itself — no tour.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// Drives the pulsing dot while a re-scan runs.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  /// Re-renders "checked N min ago" as time passes.
  Timer? _ticker;

  /// 0 = Photos, 1 = Videos.
  int _tab = 0;

  /// True while the "finish your cleanup" dialog is on screen, so a resume
  /// event can't stack a second copy of it.
  bool _askingPending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AppProvider>();
      await provider.prepare();
      if (mounted) await _offerPendingCleanup(provider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  /// Granting a permission in system Settings does NOT restart the app (only
  /// revoking does), so when the user comes back we must re-check — otherwise
  /// the home screen stays stuck on "photo access required" forever.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    final provider = context.read<AppProvider>();
    if (provider.state == AppState.permissionDenied) {
      provider.prepare();
    } else {
      // Photos taken while we were in the background (iOS keeps the app alive
      // for days) — re-scan quietly if anything changed.
      provider.onAppResumed();
    }
    // Returning from the background is another chance to finish deletions that
    // were marked but never confirmed.
    _offerPendingCleanup(provider);
  }

  /// If a previous session marked items but never got to confirm (app closed,
  /// killed, or backgrounded), explain that before firing the system delete
  /// dialog — an unexplained "Delete 12 photos?" on launch is alarming.
  Future<void> _offerPendingCleanup(AppProvider provider) async {
    if (_askingPending || !mounted) return;
    if (!provider.hasPendingDeletions) return;
    // Deleting needs photo access; don't ask while permission is missing.
    if (provider.state != AppState.ready) return;
    // Only ask when Home is actually on top. Backgrounding the app *during* a
    // cleanup session would otherwise pop this dialog over the group screen
    // the user is still working in.
    if (ModalRoute.of(context)?.isCurrent != true) return;

    _askingPending = true;
    try {
      final s = AppStrings.of(provider.languageCode);
      final count = provider.pendingDeleteCount;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(s.pendingTitle),
          content: Text(s.pendingBody(count)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(s.pendingLater),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Noir.danger,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(s.pendingConfirm),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        final deletedBefore = provider.deletedCount;
        final result = await provider.flushPendingDeletions();
        if (result.requested > 0 && mounted) {
          await Navigator.of(context).push(MaterialPageRoute<SummaryChoice>(
            builder: (_) => SessionSummaryScreen(
                result: result, kind: MediaKind.items),
          ));
          if (mounted) _afterMode(provider, deletedBefore);
        }
      } else if (confirmed == false) {
        // "Keep them" is an explicit answer — drop the marks so we don't ask
        // again on every launch.
        await provider.discardPendingDeletions();
      }
    } finally {
      _askingPending = false;
    }
  }

  // ─── Opening modes ────────────────────────────────────────────────────────

  /// Small white spinner on 60% black while a mode's data loads.
  void _showLoading() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: Noir.accent),
          ),
        ),
      ),
    );
  }

  /// Run a mode, then — once the user has left the Finished screen, if any —
  /// handle "Keep going", or show the post-session prompts on the way Home.
  ///
  /// [deletedBefore] carries the count across "Keep going" chains, so the
  /// prompts wait until the user is really back on Home and count the whole
  /// run.
  Future<void> _runMode(
    AppProvider provider,
    Widget mode,
    void Function(ResumePoint resume, int deletedBefore) reopen, {
    int? deletedBefore,
  }) async {
    final before = deletedBefore ?? provider.deletedCount;
    final exit = await Navigator.of(context)
        .push(MaterialPageRoute<ModeExit>(builder: (_) => mode));
    final choice = exit?.summary == null ? null : await exit!.summary;
    if (!mounted) return;
    if (choice == SummaryChoice.keepGoing && exit?.resume != null) {
      reopen(exit!.resume!, before);
      return;
    }
    _afterMode(provider, before);
  }

  /// After the user is back on Home from a mode (and its Finished screen).
  ///
  /// Only after something was actually deleted, and one thing at a time: the
  /// one-off notification request after the first cleanup, else an
  /// interstitial (at most one per 4 minutes, AdService), else the review
  /// prompt.
  void _afterMode(AppProvider provider, int? deletedBefore) {
    if (deletedBefore == null) return;
    final didDelete = provider.deletedCount > deletedBefore;
    // Small pause so returning to Home doesn't feel like an ambush.
    Future<void>.delayed(Duration(milliseconds: didDelete ? 500 : 0),
        () async {
      if (didDelete && await provider.maybeSetupReminders()) return;
      final shownAd = didDelete &&
          provider.adsEnabled &&
          AdService.instance.showInterstitial();
      if (!shownAd) ReviewService.instance.maybeAsk(provider.deletedCount);
    });
  }

  /// Index of the first asset at or after [r] in a newest-first list.
  static int _assetIndex(List<AssetEntity> list, ResumePoint? r) {
    if (r == null) return 0;
    final byId = list.indexWhere((a) => a.id == r.assetId);
    if (byId >= 0) return byId;
    final byTime = list.indexWhere((a) => !librarySortTime(a).isAfter(r.time));
    return byTime < 0 ? 0 : byTime;
  }

  static int _groupIndex(List<PhotoGroup> groups, ResumePoint? r) {
    if (r == null) return 0;
    final byId =
        groups.indexWhere((g) => g.assets.any((a) => a.id == r.assetId));
    if (byId >= 0) return byId;
    final byTime = groups.indexWhere((g) =>
        !g.assets.map(librarySortTime).reduce((a, b) => a.isAfter(b) ? a : b)
            .isAfter(r.time));
    return byTime < 0 ? 0 : byTime;
  }

  void _toastAllClean(AppStrings s) => NoirToast.show(context, s.allClean);

  /// Nothing (left) to review. Also ends a "Keep going" chain properly.
  void _nothingToReview(AppProvider provider, AppStrings s, int? deletedBefore) {
    _toastAllClean(s);
    _afterMode(provider, deletedBefore);
  }

  Future<void> _openPhotoSwipe(AppProvider provider, AppStrings s,
      {ResumePoint? resume, int? deletedBefore}) async {
    _showLoading();
    final photos = await provider.ensurePhotos();
    if (!mounted) return;
    Navigator.of(context).pop();
    final start = _assetIndex(photos, resume);
    if (photos.isEmpty || start >= photos.length) {
      return _nothingToReview(provider, s, deletedBefore);
    }
    await _runMode(
      provider,
      SwipeScreen(photos: photos, startIndex: start),
      (r, d) => _openPhotoSwipe(provider, s, resume: r, deletedBefore: d),
      deletedBefore: deletedBefore,
    );
  }

  Future<void> _openPhotoGroups(AppProvider provider, AppStrings s,
      {ResumePoint? resume, int? deletedBefore}) async {
    _showLoading();
    final groups = await provider.ensureGroups();
    if (!mounted) return;
    Navigator.of(context).pop();
    final start = _groupIndex(groups, resume);
    if (groups.isEmpty || start >= groups.length) {
      return _nothingToReview(provider, s, deletedBefore);
    }
    await _runMode(
      provider,
      GroupReviewScreen(groups: groups, startIndex: start),
      (r, d) => _openPhotoGroups(provider, s, resume: r, deletedBefore: d),
      deletedBefore: deletedBefore,
    );
  }

  /// Make sure we may read videos; explains and offers Settings when not.
  Future<bool> _ensureVideoAccess(AppProvider provider, AppStrings s) async {
    if (!provider.hasVideoAccess) {
      final access = await provider.requestVideoAccess();
      if (!mounted) return false;
      if (access == VideoAccess.denied) {
        await _showVideoAccessDialog(provider, s);
        return false;
      }
    }
    return true;
  }

  Future<void> _openVideoMode(AppProvider provider, AppStrings s,
      {required bool grouped, ResumePoint? resume, int? deletedBefore}) async {
    if (!await _ensureVideoAccess(provider, s)) return;
    if (!mounted) return;
    _showLoading();
    final videos = await provider.ensureVideos();
    final vGroups = grouped ? await provider.ensureVideoGroups() : const <PhotoGroup>[];
    if (!mounted) return;
    Navigator.of(context).pop();

    if (videos.isEmpty) {
      // No usable videos almost always means partial/insufficient access on
      // Android 13+, so guide the user to grant full access rather than
      // misleadingly saying "all clean".
      if (provider.videoAccess != VideoAccess.granted) {
        await _showVideoAccessDialog(provider, s);
        _afterMode(provider, deletedBefore);
      } else {
        _nothingToReview(provider, s, deletedBefore);
      }
      return;
    }

    if (grouped) {
      final start = _groupIndex(vGroups, resume);
      if (vGroups.isEmpty || start >= vGroups.length) {
        return _nothingToReview(provider, s, deletedBefore);
      }
      await _runMode(
        provider,
        VideoGroupReviewScreen(groups: vGroups, startIndex: start),
        (r, d) => _openVideoMode(provider, s,
            grouped: true, resume: r, deletedBefore: d),
        deletedBefore: deletedBefore,
      );
    } else {
      final start = _assetIndex(videos, resume);
      if (start >= videos.length) {
        return _nothingToReview(provider, s, deletedBefore);
      }
      await _runMode(
        provider,
        VideoSwipeScreen(videos: videos, startIndex: start),
        (r, d) => _openVideoMode(provider, s,
            grouped: false, resume: r, deletedBefore: d),
        deletedBefore: deletedBefore,
      );
    }
  }

  /// Explains that full video access is needed and offers to open Settings.
  Future<void> _showVideoAccessDialog(AppProvider provider, AppStrings s) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.videoAccessTitle),
        content: Text(s.videoAccessBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.notNow),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Noir.accentStrong,
              foregroundColor: Noir.onAccent,
              shape: const StadiumBorder(),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              provider.openVideoSettings();
            },
            child: Text(s.openSettings),
          ),
        ],
      ),
    );
  }

  Future<void> _onTabChanged(int i, AppProvider provider, AppStrings s) async {
    FeedbackService.instance.play(Fx.tap);
    setState(() => _tab = i);
    // The first switch to Videos runs the video-permission flow.
    if (i == 1 && provider.videoAccess == null) {
      await provider.requestVideoAccess();
    }
  }

  /// "Remove ads": straight to the store purchase sheet.
  Future<void> _buyPro(AppStrings s) async {
    final purchase = PurchaseService.instance;
    if (purchase.isAvailable) {
      await purchase.buyPro();
      return;
    }
    // The product may not have loaded at startup (store propagation delay,
    // agreements not active yet). Give it one more try before giving up.
    final ready = await purchase.refreshProduct();
    if (!mounted) return;
    if (ready) {
      await purchase.buyPro();
      return;
    }
    // Still unavailable — say so instead of silently doing nothing. Restore
    // lives in Settings.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.proUnavailable),
        action: SnackBarAction(
          label: s.settings,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final s = AppStrings.of(provider.languageCode);

    // Videos tab visible with access but the list was invalidated (library
    // change) — reload it in the background.
    if (_tab == 1 && provider.hasVideoAccess && !provider.videosLoaded) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => provider.ensureVideos());
    }

    return Scaffold(
      backgroundColor: Noir.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBody(context, provider, s)),
            if (provider.adsEnabled)
              const SafeArea(top: false, child: BannerAdWidget()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppProvider provider, AppStrings s) {
    switch (provider.state) {
      case AppState.ready:
        return _buildReady(context, provider, s);
      case AppState.loading:
      case AppState.initial:
        return _buildLoading(s);
      case AppState.permissionDenied:
        return _buildMessage(
          icon: Icons.lock_outline_rounded,
          title: s.permissionTitle,
          body: s.permissionBody,
          primary: NoirButton.primary(
            label: s.openSettings,
            onPressed: () => PhotoManager.openSetting(),
          ),
          // Manual re-check, in case the lifecycle callback didn't fire.
          secondary: NoirButton.ghost(
            label: s.retry,
            onPressed: () => provider.prepare(),
          ),
        );
      case AppState.error:
        return _buildMessage(
          icon: Icons.error_outline_rounded,
          title: s.errorMessage,
          primary: NoirButton.primary(
            label: s.retry,
            onPressed: () => provider.prepare(),
          ),
        );
    }
  }

  Widget _buildLoading(AppStrings s) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: Noir.accent),
          ),
          const SizedBox(height: 20),
          Text(s.analyzingPhotos, style: NoirText.bodyMuted),
        ],
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    String? body,
    required Widget primary,
    Widget? secondary,
  }) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                      color: Noir.surface2, shape: BoxShape.circle),
                  child: Icon(icon, size: 40, color: Noir.text),
                ),
                const SizedBox(height: 24),
                Text(title, textAlign: TextAlign.center, style: NoirText.h2),
                if (body != null) ...[
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Text(body,
                        textAlign: TextAlign.center,
                        style: NoirText.bodyMuted),
                  ),
                ],
                const Spacer(),
                primary,
                if (secondary != null) ...[
                  const SizedBox(height: 8),
                  secondary,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReady(BuildContext context, AppProvider provider, AppStrings s) {
    final lang = provider.languageCode;
    final videos = _tab == 1;
    final videoAccessDenied =
        provider.videoAccess == VideoAccess.denied;

    // Pull-to-refresh is a hidden fallback: the library normally re-scans by
    // itself on changes and on resume, so there's no Refresh button.
    return RefreshIndicator(
      color: Noir.onAccent,
      backgroundColor: Noir.accent,
      onRefresh: provider.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(s),
                  const SizedBox(height: 18),
                  if (provider.limitedAccess)
                    _buildLimitedAccess(s)
                  else
                    _buildFreshness(provider, s),
                  const SizedBox(height: 14),
                  Text(s.homeTitle, style: NoirText.h1),
                  const SizedBox(height: 18),
                  NoirSegmented(
                    labels: [
                      s.tabPhotos(formatCount(provider.stats.totalPhotos, lang)),
                      provider.videoCount > 0
                          ? s.tabVideos(formatCount(provider.videoCount, lang))
                          : s.videosLabel,
                    ],
                    selectedIndex: _tab,
                    onChanged: (i) => _onTabChanged(i, provider, s),
                  ),
                  const SizedBox(height: Noir.gap),
                  if (!videos) ...[
                    _modeCard(
                      title: s.similarShots,
                      desc: s.similarShotsDesc,
                      meta: provider.groupsLoaded
                          ? s.groupsCount(provider.groups.length,
                              formatCount(provider.groups.length, lang))
                          : s.findingGroups,
                      thumbs: provider.groups.isNotEmpty
                          ? provider.groups.first.assets.take(3).toList()
                          : const [],
                      onTap: () => _openPhotoGroups(provider, s),
                    ),
                    const SizedBox(height: Noir.gapS),
                    _modeCard(
                      title: s.swipe,
                      desc: s.swipePhotosDesc,
                      meta: s.photosCount(provider.stats.totalPhotos,
                          formatCount(provider.stats.totalPhotos, lang)),
                      thumbs: provider.allPhotos.isNotEmpty
                          ? [provider.allPhotos.first]
                          : const [],
                      single: true,
                      onTap: () => _openPhotoSwipe(provider, s),
                    ),
                  ] else ...[
                    _modeCard(
                      title: s.similarClips,
                      desc: s.similarClipsDesc,
                      meta: videoAccessDenied
                          ? s.allowAccess
                          : s.videosCount(provider.videoCount,
                              formatCount(provider.videoCount, lang)),
                      thumbs: provider.videoGroups.isNotEmpty
                          ? provider.videoGroups.first.assets.take(3).toList()
                          : provider.allVideos.take(3).toList(),
                      onTap: videoAccessDenied
                          ? () => _showVideoAccessDialog(provider, s)
                          : () => _openVideoMode(provider, s, grouped: true),
                    ),
                    const SizedBox(height: Noir.gapS),
                    _modeCard(
                      title: s.swipe,
                      desc: s.swipeVideosDesc,
                      meta: videoAccessDenied
                          ? s.allowAccess
                          : s.videosCount(provider.videoCount,
                              formatCount(provider.videoCount, lang)),
                      thumbs: provider.allVideos.isNotEmpty
                          ? [provider.allVideos.first]
                          : const [],
                      single: true,
                      onTap: videoAccessDenied
                          ? () => _showVideoAccessDialog(provider, s)
                          : () => _openVideoMode(provider, s, grouped: false),
                    ),
                  ],
                  const SizedBox(height: Noir.gap),
                  const Spacer(),
                  _buildMilestoneCard(provider, s),
                  if (!provider.isPro) ...[
                    const SizedBox(height: Noir.gapXS),
                    NoirButton.ghost(
                      label: s.removeAdsLink,
                      height: 40,
                      textStyle: NoirText.meta,
                      onPressed: () => _buyPro(s),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppStrings s) {
    return Row(
      children: [
        // The real app logo (transparent background), not a generic mark.
        Image.asset(
          'assets/icon/icon_header.png',
          width: 40,
          height: 40,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'CleanFotos',
            style: TextStyle(
              fontFamily: NoirText.family,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.6,
              color: Noir.text,
            ),
          ),
        ),
        NoirIconButton(
          icon: Icons.tune_rounded,
          semanticLabel: s.settings,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildFreshness(AppProvider provider, AppStrings s) {
    final String text;
    if (provider.isRescanning) {
      text = s.lookingForNew;
    } else {
      final last = provider.lastScanAt;
      final minutes =
          last == null ? 0 : DateTime.now().difference(last).inMinutes;
      text = minutes < 1 ? s.upToDate : s.checkedAgo(minutes);
    }
    final dot = Container(
      width: 8,
      height: 8,
      decoration:
          const BoxDecoration(color: Noir.accent, shape: BoxShape.circle),
    );
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          if (provider.isRescanning && !reduceMotion)
            FadeTransition(
              opacity: Tween(begin: 0.25, end: 1.0).animate(_pulse),
              child: dot,
            )
          else
            dot,
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: NoirText.meta.copyWith(
              fontWeight: FontWeight.w400))),
        ],
      ),
    );
  }

  /// Partial access ("Selected photos") — the most common reason "not all my
  /// pictures show up". iOS opens the picker; Android the app's settings.
  Widget _buildLimitedAccess(AppStrings s) {
    final ios = Platform.isIOS;
    return NoirCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.limitedAccessTitle,
              style: NoirText.body.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(ios ? s.limitedAccessBodyIos : s.limitedAccessBody,
              style: NoirText.secondary),
          const SizedBox(height: 12),
          NoirButton.secondary(
            label: ios ? s.selectMorePhotos : s.openSettings,
            height: 44,
            textStyle: NoirText.button.copyWith(fontSize: 15),
            // The library-change listener re-scans when the user comes back.
            onPressed: () => ios
                ? PhotoManager.presentLimited()
                : PhotoManager.openSetting(),
          ),
        ],
      ),
    );
  }

  Widget _modeCard({
    required String title,
    required String desc,
    required String meta,
    required List<AssetEntity> thumbs,
    required VoidCallback onTap,
    bool single = false,
  }) {
    return Semantics(
      button: true,
      child: NoirCard(
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: NoirText.h2),
                  const SizedBox(height: 6),
                  Text(desc, style: NoirText.secondary),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: const ShapeDecoration(
                      color: Noir.surface2,
                      shape: StadiumBorder(),
                    ),
                    child: Text(meta,
                        style: NoirText.caption.copyWith(color: Noir.text)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ThumbStack(assets: single ? thumbs.take(1).toList() : thumbs),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneCard(AppProvider provider, AppStrings s) {
    final lang = provider.languageCode;
    final next = provider.nextMilestone;
    final freed = provider.freedBytes;

    Widget content;
    if (next == null) {
      content = Row(
        children: [
          _ring(const Icon(Icons.check_rounded, size: 20, color: Noir.reward)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(s.allMilestones(formatBytes(freed, lang, ByteRounding.down)),
                style: NoirText.body.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      );
    } else {
      final firstEver = freed == 0;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(s.nextMilestone, style: NoirText.caption)),
              if (!firstEver)
                Text(s.toGo(formatBytes(next.bytes - freed, lang, ByteRounding.up)),
                    style: NoirText.caption),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ring(FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(next.valueLabel,
                    style: const TextStyle(
                        fontFamily: NoirText.family,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Noir.reward)),
              )),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (firstEver)
                      Text(s.firstMilestone(next.label),
                          style: NoirText.body
                              .copyWith(fontWeight: FontWeight.w600))
                    else
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: formatBytes(freed, lang, ByteRounding.down),
                            style: const TextStyle(
                                fontFamily: NoirText.family,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Noir.text),
                          ),
                          TextSpan(
                            text: ' ${s.ofFreed(next.label)}',
                            style: NoirText.secondary,
                          ),
                        ]),
                      ),
                    const SizedBox(height: 8),
                    ProgressTrack.reward(value: freed / next.bytes),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    return NoirCard(
      padding: const EdgeInsets.all(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MilestonesScreen()),
      ),
      child: content,
    );
  }

  Widget _ring(Widget child) => Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Noir.reward, width: 2),
        ),
        alignment: Alignment.center,
        child: child,
      );
}

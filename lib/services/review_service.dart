import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles the "Rate this app" flows: a direct store-listing link (Settings)
/// and a smart, one-time native review prompt after the user has cleaned up
/// enough to feel good about the app.
class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  final InAppReview _review = InAppReview.instance;

  static const String _askedKey = 'review_asked';
  static const int _minDeletionsToAsk = 20;

  /// Open the Play Store listing so the user can rate/leave a review.
  Future<void> openStoreListing() async {
    try {
      await _review.openStoreListing();
    } catch (_) {}
  }

  /// Show the native in-app review prompt once, after the user has deleted a
  /// meaningful number of items. Google rate-limits this, so it may not always
  /// appear — that's expected.
  Future<void> maybeAsk(int deletedCount) async {
    if (deletedCount < _minDeletionsToAsk) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_askedKey) ?? false) return;
    try {
      if (await _review.isAvailable()) {
        await prefs.setBool(_askedKey, true);
        await _review.requestReview();
      }
    } catch (_) {}
  }
}

import 'package:flutter_test/flutter_test.dart';

import 'package:cleanfotos_app/l10n/strings.dart';
import 'package:cleanfotos_app/models/delete_result.dart';

const _langs = ['en', 'es', 'de', 'fr', 'pt', 'it', 'pl'];

void main() {
  test('every 1.3 string builds in every language', () {
    for (final code in _langs) {
      final s = AppStrings.of(code);
      final all = <String>[
        s.homeTitle, s.tabPhotos('1'), s.tabVideos('2'), s.videosLabel,
        s.upToDate, s.checkedAgo(3), s.lookingForNew,
        s.similarShots, s.similarShotsDesc, s.similarClips, s.similarClipsDesc,
        s.swipe, s.swipePhotosDesc, s.swipeVideosDesc,
        s.findingGroups, s.allowAccess, s.selectMorePhotos,
        s.limitedAccessBodyIos, s.nextMilestone, s.toGo('1 MB'),
        s.ofFreed('1 MB'), s.firstMilestone('100 MB'),
        s.allMilestones('50 GB'), s.removeAdsLink,
        s.reviewed('4'), s.markedPending('3', '11 MB'), s.confirmOnceNote,
        s.confirmOnceNoteVideos, s.swipeFirstHint, s.finish, s.undo, s.back,
        s.holdToPlay, s.playing, s.tapToMark, s.tapToMarkVideos,
        s.keepAllNext, s.deleteNext(2), s.keepAllFinish, s.deleteFinish(2),
        s.previousGroup, s.markedToast('7 MB'), s.freed('12 MB'),
        s.milestoneReached, s.milestoneLine('100 MB', '30'), s.nextTier('250 MB'),
        s.keepGoing, s.backHome, s.nothingDeleted, s.milestones,
        s.freedInTotal('10'), s.reachedOn('Oct 4'), s.reached,
        s.aboutPhotos('70'), s.ofTier('28 MB', '100 MB'), s.progress,
        s.feedback, s.sounds, s.haptics,
        s.refresh, s.leftOffAt('Sep 27, 2019'), s.resumeTitle,
        s.continueFrom('Sep 27, 2019'), s.startNewest,
        s.newSinceLastTime('12 photos'),
      ];
      for (final n in [0, 1, 2, 5, 12, 22, 112]) {
        all
          ..add(s.similarCount(n))
          ..add(s.similarClipsCount(n))
          ..add(s.groupsCount(n, '$n'));
        for (final k in MediaKind.values) {
          all
            ..add(s.mediaCount(k, n, '$n'))
            ..add(s.movedToRecentlyDeleted(k, n, '$n'))
            ..add(s.movedToTrash(k, n, '$n'))
            ..add(s.deletedPlain(k, n, '$n'))
            ..add(s.nothingDeletedBody(k));
        }
      }
      for (final text in all) {
        expect(text.trim(), isNotEmpty, reason: '$code: empty string');
        expect(text.contains(r'$'), isFalse, reason: '$code: "$text"');
      }
    }
  });

  test('Polish plural forms', () {
    final s = AppStrings.of('pl');
    expect(s.photosCount(1, '1'), '1 zdjęcie');
    expect(s.photosCount(3, '3'), '3 zdjęcia');
    expect(s.photosCount(5, '5'), '5 zdjęć');
    expect(s.photosCount(12, '12'), '12 zdjęć');
    expect(s.photosCount(22, '22'), '22 zdjęcia');
    expect(s.videosCount(2, '2'), '2 filmy');
  });

  test('gender agreement on the Finished screen', () {
    expect(AppStrings.of('fr').deletedPlain(MediaKind.photos, 2, '2'),
        '2 photos supprimées.');
    expect(AppStrings.of('fr').deletedPlain(MediaKind.items, 1, '1'),
        '1 élément supprimé.');
    expect(AppStrings.of('it').deletedPlain(MediaKind.videos, 3, '3'),
        '3 video eliminati.');
    expect(AppStrings.of('es').deletedPlain(MediaKind.photos, 1, '1'),
        '1 foto eliminada.');
    expect(AppStrings.of('en').movedToRecentlyDeleted(MediaKind.photos, 1, '1'),
        '1 photo moved to Recently Deleted. You can restore it there for 30 days.');
  });

  test('short dates', () {
    final now = DateTime(2026, 10, 7, 12);
    final en = AppStrings.of('en');
    expect(en.shortDate(DateTime(2026, 10, 7, 9, 14), now: now), 'Today, 09:14');
    expect(en.shortDate(DateTime(2026, 10, 6, 23, 2), now: now),
        'Yesterday, 23:02');
    expect(en.shortDate(DateTime(2026, 10, 4, 8), now: now), 'Sun, Oct 4');
    expect(en.shortDate(DateTime(2024, 9, 27), now: now), 'Sep 27, 2024');
    expect(en.shortDate(DateTime(2026, 10, 4, 8, 5), withTime: true, now: now),
        'Sun, Oct 4, 08:05');
    expect(AppStrings.of('de').shortDate(DateTime(2026, 10, 4), now: now),
        'So., 4. Okt.');
    expect(AppStrings.of('pl').reachedDate(DateTime(2025, 3, 2), now: now),
        '2 mar 2025');
  });
}

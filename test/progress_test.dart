import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cleanfotos_app/models/progress.dart';
import 'package:cleanfotos_app/providers/app_provider.dart';

ResumePoint _p(String id, int year, [int month = 6]) =>
    ResumePoint(assetId: id, time: DateTime(year, month));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('continuing moves the saved point as the user goes', () async {
    final p = AppProvider();
    const m = CleanupMode.photoSwipe;
    await p.recordProgress(m, _p('a', 2020), fromNewest: false);
    await p.recordProgress(m, _p('b', 2019), fromNewest: false);
    expect(p.progressFor(m)!.at!.assetId, 'b');
  });

  test('starting with the newest never throws away a deeper position',
      () async {
    final p = AppProvider();
    const m = CleanupMode.photoSwipe;
    // Worked back to 2019 last time.
    await p.recordProgress(m, _p('deep', 2019), fromNewest: false);
    // Now browsing this year's photos from the top.
    await p.recordProgress(m, _p('new', 2026),
        fromNewest: true, top: DateTime(2026, 10));
    expect(p.progressFor(m)!.at!.assetId, 'deep');
    expect(p.progressFor(m)!.top, DateTime(2026, 10));
    // ...and once they go deeper than 2019, the point follows them.
    await p.recordProgress(m, _p('older', 2018),
        fromNewest: true, top: DateTime(2026, 10));
    expect(p.progressFor(m)!.at!.assetId, 'older');
  });

  test('reaching the end clears the position but keeps "top"', () async {
    final p = AppProvider();
    const m = CleanupMode.photoGroups;
    await p.recordProgress(m, _p('x', 2021),
        fromNewest: true, top: DateTime(2026, 1));
    await p.recordProgress(m, null, fromNewest: true, top: DateTime(2026, 1));
    expect(p.progressFor(m)!.at, isNull);
    expect(p.progressFor(m)!.top, DateTime(2026, 1));
  });

  test('modes are independent and the position is persisted', () async {
    final p = AppProvider();
    await p.recordProgress(CleanupMode.videoSwipe, _p('v', 2022),
        fromNewest: false);
    expect(p.progressFor(CleanupMode.photoSwipe), isNull);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('progress_videoSwipe')!;
    final restored = SavedProgress.fromJson(jsonDecode(raw));
    expect(restored!.at!.assetId, 'v');
    expect(restored.at!.time, DateTime(2022, 6));
  });
}

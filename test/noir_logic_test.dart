import 'package:flutter_test/flutter_test.dart';

import 'package:cleanfotos_app/models/milestone.dart';
import 'package:cleanfotos_app/utils/format.dart';

const _mb = 1024 * 1024;
const _gb = 1024 * _mb;

void main() {
  group('formatCount', () {
    test('uses each language\'s thousands separator', () {
      expect(formatCount(26414, 'en'), '26,414');
      expect(formatCount(26414, 'de'), '26.414');
      expect(formatCount(26414, 'pl'), '26.414');
      expect(formatCount(26414, 'fr'), '26 414');
      expect(formatCount(999, 'en'), '999');
      expect(formatCount(1000000, 'en'), '1,000,000');
      expect(formatCount(0, 'de'), '0');
    });
  });

  group('formatBytes', () {
    test('one decimal under 10, whole above', () {
      expect(formatBytes(0), '0 MB');
      expect(formatBytes(512 * 1024), '512 KB');
      expect(formatBytes((3.5 * _mb).round()), '3.5 MB');
      expect(formatBytes((3.5 * _mb).round(), 'de'), '3,5 MB');
      expect(formatBytes(28 * _mb), '28 MB');
      expect(formatBytes((1.25 * _gb).round()), '1.3 GB');
      expect(formatBytes(52 * _gb), '52 GB');
    });

    test('rounding modes', () {
      final almost100 = 104800000; // 99.95 MB
      expect(formatBytes(almost100), '100 MB');
      expect(formatBytes(almost100, 'en', ByteRounding.down), '99 MB');
      expect(formatBytes(57600, 'en', ByteRounding.up), '57 KB');
      expect(formatBytes(2 * _mb, 'en', ByteRounding.up), '2.0 MB');
      expect(formatBytes(100 * _mb, 'en', ByteRounding.down), '100 MB');
    });
  });

  group('roundTo2Sig', () {
    test('two significant figures', () {
      expect(roundTo2Sig(0), 0);
      expect(roundTo2Sig(7), 7);
      expect(roundTo2Sig(28.6), 29);
      expect(roundTo2Sig(143), 140);
      expect(roundTo2Sig(1427), 1400);
      expect(roundTo2Sig(14999), 15000);
    });
  });

  group('Milestone', () {
    test('ladder labels', () {
      expect(Milestone.ladder.first.label, '100 MB');
      expect(Milestone.ladder[3].label, '1 GB');
      expect(Milestone.ladder.last.label, '50 GB');
      expect(Milestone.ladder[3].valueLabel, '1');
      expect(Milestone.ladder[3].unitLabel, 'GB');
    });

    test('reachedIndex', () {
      expect(Milestone.reachedIndex(0), -1);
      expect(Milestone.reachedIndex(99 * _mb), -1);
      expect(Milestone.reachedIndex(100 * _mb), 0);
      expect(Milestone.reachedIndex(600 * _mb), 2);
      expect(Milestone.reachedIndex(60 * _gb), 8);
    });

    test('after', () {
      expect(Milestone.after(-1), Milestone.ladder.first);
      expect(Milestone.after(2), Milestone.ladder[3]);
      expect(Milestone.after(8), isNull);
    });
  });
}

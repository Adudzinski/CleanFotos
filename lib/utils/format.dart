/// Locale-aware number and size formatting, written by hand because `intl`
/// isn't a direct dependency (see pubspec.yaml).

/// Languages that write "26.414" and "3,5" (dot thousands, comma decimals).
const Set<String> _dotThousands = {'de', 'es', 'it', 'pt', 'pl'};

String _thousandsSep(String lang) {
  if (lang == 'fr') return ' '; // narrow no-break space: "26 414"
  if (_dotThousands.contains(lang)) return '.';
  return ',';
}

String _decimalSep(String lang) => lang == 'en' ? '.' : ',';

/// `26414` → en "26,414", de/es/it/pt/pl "26.414", fr "26 414".
String formatCount(int n, [String lang = 'en']) {
  final negative = n < 0;
  final digits = n.abs().toString();
  final sep = _thousandsSep(lang);
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(sep);
    buf.write(digits[i]);
  }
  return negative ? '-$buf' : buf.toString();
}

String _fixed(double v, int decimals, String lang) {
  final s = v.toStringAsFixed(decimals);
  if (decimals == 0) {
    return formatCount(int.parse(s), lang);
  }
  final parts = s.split('.');
  return '${formatCount(int.parse(parts[0]), lang)}${_decimalSep(lang)}${parts[1]}';
}

const int _kb = 1024;
const int _mb = 1024 * 1024;
const int _gb = 1024 * 1024 * 1024;

/// Bytes as KB / MB / GB. One decimal below 10 (so small numbers stay
/// meaningful: "3,5 MB"), whole numbers above ("28 MB", "52 GB").
String formatBytes(int bytes, [String lang = 'en']) {
  if (bytes <= 0) return '0 MB';
  if (bytes < _mb) return '${_fixed(bytes / _kb, 0, lang)} KB';
  if (bytes < _gb) {
    final mb = bytes / _mb;
    return '${_fixed(mb, mb < 10 ? 1 : 0, lang)} MB';
  }
  final gb = bytes / _gb;
  return '${_fixed(gb, gb < 10 ? 1 : 0, lang)} GB';
}

/// Round to two significant figures: 33 → 33, 143 → 140, 1427 → 1,400.
int roundTo2Sig(num value) {
  if (value <= 0) return 0;
  var magnitude = 1;
  while (value / magnitude >= 100) {
    magnitude *= 10;
  }
  return (value / magnitude).round() * magnitude;
}

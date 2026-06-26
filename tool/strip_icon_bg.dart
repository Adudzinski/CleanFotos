// One-off helper: makes the adaptive-icon foreground transparent.
//
// The source `icon_foreground.png` had a pale lavender square baked behind the
// logo, which showed up as a "quadratic frame" once Android masked the adaptive
// icon. This flood-fills the connected low-saturation (background + outer
// shadow) region starting from the image border and turns it transparent,
// leaving only the colorful logo (and the natural shadows *between* the cards,
// which are enclosed by the logo and therefore not reachable from the border).
//
// Run with: dart run tool/strip_icon_bg.dart
import 'dart:io';
import 'package:image/image.dart' as img;

// Pixels with chroma below this are treated as "background-ish" and can be
// flooded through. The logo (purple cards + green check) has much higher chroma.
const int chromaThreshold = 60;

int _chroma(img.Pixel p) {
  final r = p.r.toInt();
  final g = p.g.toInt();
  final b = p.b.toInt();
  final maxC = r > g ? (r > b ? r : b) : (g > b ? g : b);
  final minC = r < g ? (r < b ? r : b) : (g < b ? g : b);
  return maxC - minC;
}

void main() {
  const path = 'assets/icon/icon_foreground.png';
  final bytes = File('assets/icon/icon_foreground_original.png').readAsBytesSync();
  final image = img.decodePng(bytes);
  if (image == null) {
    stderr.writeln('Could not decode source PNG');
    exit(1);
  }
  image.convert(numChannels: 4); // ensure alpha channel

  final w = image.width;
  final h = image.height;
  final visited = List<bool>.filled(w * h, false);
  final stack = <int>[];

  void trySeed(int x, int y) {
    final idx = y * w + x;
    if (visited[idx]) return;
    if (_chroma(image.getPixel(x, y)) < chromaThreshold) {
      visited[idx] = true;
      stack.add(idx);
    }
  }

  // Seed from every border pixel.
  for (var x = 0; x < w; x++) {
    trySeed(x, 0);
    trySeed(x, h - 1);
  }
  for (var y = 0; y < h; y++) {
    trySeed(0, y);
    trySeed(w - 1, y);
  }

  var cleared = 0;
  while (stack.isNotEmpty) {
    final idx = stack.removeLast();
    final x = idx % w;
    final y = idx ~/ w;
    image.setPixelRgba(x, y, 0, 0, 0, 0); // fully transparent
    cleared++;

    void visit(int nx, int ny) {
      if (nx < 0 || ny < 0 || nx >= w || ny >= h) return;
      final nIdx = ny * w + nx;
      if (visited[nIdx]) return;
      if (_chroma(image.getPixel(nx, ny)) < chromaThreshold) {
        visited[nIdx] = true;
        stack.add(nIdx);
      }
    }

    visit(x - 1, y);
    visit(x + 1, y);
    visit(x, y - 1);
    visit(x, y + 1);
  }

  File(path).writeAsBytesSync(img.encodePng(image));
  stdout.writeln('Cleared $cleared / ${w * h} pixels to transparent.');
  stdout.writeln('Wrote $path');
}

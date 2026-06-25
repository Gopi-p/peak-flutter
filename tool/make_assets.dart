// Pure-Dart launcher icon + splash master generator.
// Run: `dart run tool/make_assets.dart` from the project root.
//
// Produces:
//   assets/icon/peak-icon.png             (1024×1024 — iOS launcher / legacy Android, dark fill)
//   assets/icon/peak-icon-foreground.png  (1024×1024 — Android adaptive foreground, transparent)
//   assets/icon/peak-splash.png           (1024×1024 — flutter_native_splash source, transparent)
//
// The mark: a layered gold mountain range ("peak") with a pale snow tip on the
// Midnight Studio background. Everything is rendered at 4× and downsampled so
// edges are smooth. No border ring, no baked-in wordmark — the splash is a
// transparent mark that floats cleanly on the splash background color.

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

enum _Variant { icon, adaptiveForeground, splash }

/// Supersampling factor — render this much larger, then average down for
/// antialiased edges.
const _ss = 4;

const _bg = (r: 0x13, g: 0x13, b: 0x16);

void main() {
  _writeIcon('assets/icon/peak-icon.png', size: 1024, variant: _Variant.icon);
  _writeIcon('assets/icon/peak-icon-foreground.png',
      size: 1024, variant: _Variant.adaptiveForeground);
  _writeIcon('assets/icon/peak-splash.png', size: 1024, variant: _Variant.splash);
  stdout.writeln('Done.');
}

void _writeIcon(String path, {required int size, required _Variant variant}) {
  final ssSize = size * _ss;
  final image = img.Image(width: ssSize, height: ssSize, numChannels: 4);

  switch (variant) {
    case _Variant.icon:
      // Filled Midnight Studio square with a soft radial lift behind the peak.
      img.fill(image, color: img.ColorRgba8(_bg.r, _bg.g, _bg.b, 255));
      _radialGlow(image, ssSize);
      _drawMark(image, ssSize, scale: 0.74);
    case _Variant.adaptiveForeground:
      // Transparent; mountain inside the adaptive safe zone so the OS mask
      // never crops it.
      img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));
      _drawMark(image, ssSize, scale: 0.58);
    case _Variant.splash:
      // Transparent mark — the native splash composites it over its own
      // background color, so there is no box or border around the logo.
      img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));
      _drawMark(image, ssSize, scale: 0.60);
  }

  final out = img.copyResize(
    image,
    width: size,
    height: size,
    interpolation: img.Interpolation.average,
  );

  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(out));
  stdout.writeln('wrote $path');
}

/// A faint gold radial glow rising behind the peak — keeps the filled icon
/// from reading flat without introducing a hard edge.
void _radialGlow(img.Image image, int size) {
  final cx = size * 0.5;
  final cy = size * 0.56;
  final radius = size * 0.5;
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final d = math.sqrt(math.pow(x - cx, 2) + math.pow(y - cy, 2)) / radius;
      if (d >= 1) continue;
      final t = (1 - d) * (1 - d); // ease-out falloff
      final a = (26 * t); // very subtle
      final px = image.getPixel(x, y);
      image.setPixelRgba(
        x,
        y,
        _mix(px.r.toInt(), 0xD4, a / 255),
        _mix(px.g.toInt(), 0xAF, a / 255),
        _mix(px.b.toInt(), 0x37, a / 255),
        255,
      );
    }
  }
}

/// Draws the layered mountain range. `scale` shrinks the mark around the
/// canvas center (1.0 = full canvas).
void _drawMark(img.Image image, int size, {required double scale}) {
  final cx = size / 2;
  final cy = size / 2;
  double sx(double frac) => cx + (frac - 0.5) * size * scale;
  double sy(double frac) => cy + (frac - 0.5) * size * scale;

  // Back peak — taller, muted gold, sits behind and to the left.
  _fillTriangleGradient(
    image,
    ax: sx(0.06).toInt(), ay: sy(0.84).toInt(),
    bx: sx(0.40).toInt(), by: sy(0.20).toInt(),
    cx: sx(0.66).toInt(), cy: sy(0.84).toInt(),
    topR: 0xC6, topG: 0xA0, topB: 0x42,
    botR: 0x8C, botG: 0x71, botB: 0x28,
  );

  // Front peak — brighter gold, overlaps the back peak for depth.
  _fillTriangleGradient(
    image,
    ax: sx(0.40).toInt(), ay: sy(0.84).toInt(),
    bx: sx(0.62).toInt(), by: sy(0.14).toInt(),
    cx: sx(0.94).toInt(), cy: sy(0.84).toInt(),
    topR: 0xF2, topG: 0xCB, topB: 0x5E,
    botR: 0xD4, botG: 0xAF, botB: 0x37,
  );

  // Snowcap on the front peak — a solid pale tip that follows the peak's own
  // slopes (base corners sit exactly on the front peak's edges at frac y≈0.30).
  _fillTriangleGradient(
    image,
    ax: sx(0.570).toInt(), ay: sy(0.30).toInt(),
    bx: sx(0.62).toInt(), by: sy(0.14).toInt(),
    cx: sx(0.693).toInt(), cy: sy(0.30).toInt(),
    topR: 0xFA, topG: 0xF4, topB: 0xE2,
    botR: 0xEC, botG: 0xDF, botB: 0xBE,
  );
}

// --- primitives --------------------------------------------------------------

void _fillTriangleGradient(
  img.Image image, {
  required int ax,
  required int ay,
  required int bx,
  required int by,
  required int cx,
  required int cy,
  required int topR,
  required int topG,
  required int topB,
  required int botR,
  required int botG,
  required int botB,
}) {
  final minX = [ax, bx, cx].reduce(math.min);
  final maxX = [ax, bx, cx].reduce(math.max);
  final minY = [ay, by, cy].reduce(math.min);
  final maxY = [ay, by, cy].reduce(math.max);

  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      if (!_pointInTriangle(x, y, ax, ay, bx, by, cx, cy)) continue;
      // Vertical gradient: bright near the apex, deeper at the base.
      final t = (y - minY) / math.max(1, maxY - minY);
      image.setPixelRgba(
        x,
        y,
        _lerp(topR, botR, t),
        _lerp(topG, botG, t),
        _lerp(topB, botB, t),
        255,
      );
    }
  }
}

int _lerp(int a, int b, double t) => (a + (b - a) * t).round();

int _mix(int base, int over, double a) => (base + (over - base) * a).round().clamp(0, 255);

bool _pointInTriangle(int px, int py, int ax, int ay, int bx, int by, int cx, int cy) {
  num sign(int x1, int y1, int x2, int y2, int x3, int y3) =>
      (x1 - x3) * (y2 - y3) - (x2 - x3) * (y1 - y3);
  final d1 = sign(px, py, ax, ay, bx, by);
  final d2 = sign(px, py, bx, by, cx, cy);
  final d3 = sign(px, py, cx, cy, ax, ay);
  final hasNeg = d1 < 0 || d2 < 0 || d3 < 0;
  final hasPos = d1 > 0 || d2 > 0 || d3 > 0;
  return !(hasNeg && hasPos);
}

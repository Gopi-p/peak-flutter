// Pure-Dart launcher icon + splash master generator.
// Run: `dart run tool/make_assets.dart` from the project root.
//
// Produces:
//   assets/icon/peak-icon.png             (1024×1024 — iOS launcher / legacy Android)
//   assets/icon/peak-icon-foreground.png  (1024×1024 — Android adaptive foreground, transparent bg, mountain inside 66% safe zone)
//   assets/icon/peak-splash.png           (1024×1024 — flutter_native_splash source)
//
// The mark: a soft-gold mountain ("peak") on the Midnight Studio background.

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

enum _Variant { icon, adaptiveForeground, splash }

void main() {
  _writeIcon('assets/icon/peak-icon.png', size: 1024, variant: _Variant.icon);
  _writeIcon('assets/icon/peak-icon-foreground.png',
      size: 1024, variant: _Variant.adaptiveForeground);
  _writeIcon('assets/icon/peak-splash.png', size: 1024, variant: _Variant.splash);
  stdout.writeln('Done.');
}

void _writeIcon(String path, {required int size, required _Variant variant}) {
  final image = img.Image(width: size, height: size, numChannels: 4);

  if (variant == _Variant.adaptiveForeground) {
    // Adaptive foreground: transparent background, mountain centered inside
    // the inner ~66% safe zone so the OS mask never crops the peak. No glow ring.
    img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));
    _drawMountain(image, size: size, scale: 0.66);
  } else {
    // Filled square — Midnight Studio dark.
    img.fill(image, color: img.ColorRgba8(0x13, 0x13, 0x16, 255));

    // Soft glow ring inside the icon, hinting at the rounded-square iOS mask.
    _strokeRoundedRect(
      image,
      left: (size * 0.06).toInt(),
      top: (size * 0.06).toInt(),
      width: (size * 0.88).toInt(),
      height: (size * 0.88).toInt(),
      radius: (size * 0.20).toInt(),
      color: img.ColorRgba8(0xD4, 0xAF, 0x37, 90),
      thickness: math.max(2, (size * 0.012).round()),
    );

    _drawMountain(image, size: size, scale: 1.0);

    if (variant == _Variant.splash) {
      // Splash gets a small "PEAK" wordmark stand-in beneath the mountain.
      final barW = (size * 0.18).toInt();
      final barH = (size * 0.014).round();
      img.fillRect(
        image,
        x1: ((size - barW) / 2).toInt(),
        y1: (size * 0.86).toInt(),
        x2: ((size + barW) / 2).toInt(),
        y2: (size * 0.86).toInt() + barH,
        color: img.ColorRgba8(0xEF, 0xC6, 0x56, 255),
      );
    }
  }

  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(image));
  stdout.writeln('wrote $path');
}

/// Draws the mountain triangle + snowcap. `scale` shrinks the mountain
/// around the canvas center (1.0 = full canvas, 0.66 = inside adaptive
/// safe zone).
void _drawMountain(img.Image image, {required int size, required double scale}) {
  final cx = size / 2;
  final cy = size / 2;
  double sx(double frac) => cx + (frac - 0.5) * size * scale;
  double sy(double frac) => cy + (frac - 0.5) * size * scale;

  final ax = sx(0.18).toInt();
  final ay = sy(0.78).toInt();
  final bx = sx(0.50).toInt();
  final by = sy(0.28).toInt();
  final dx = sx(0.82).toInt();
  final dy = sy(0.78).toInt();
  _fillTriangleGradient(image, ax: ax, ay: ay, bx: bx, by: by, cx: dx, cy: dy);

  // Snowcap accent.
  _drawLine(
    image,
    x1: sx(0.38).toInt(),
    y1: sy(0.56).toInt(),
    x2: sx(0.50).toInt(),
    y2: sy(0.40).toInt(),
    color: img.ColorRgba8(0x13, 0x13, 0x16, 220),
    thickness: math.max(3, (size * 0.012).round()),
  );
  _drawLine(
    image,
    x1: sx(0.50).toInt(),
    y1: sy(0.40).toInt(),
    x2: sx(0.62).toInt(),
    y2: sy(0.56).toInt(),
    color: img.ColorRgba8(0x13, 0x13, 0x16, 220),
    thickness: math.max(3, (size * 0.012).round()),
  );
}

// --- primitives --------------------------------------------------------------

void _strokeRoundedRect(
  img.Image image, {
  required int left,
  required int top,
  required int width,
  required int height,
  required int radius,
  required img.Color color,
  required int thickness,
}) {
  // Outer
  img.drawRect(
    image,
    x1: left,
    y1: top,
    x2: left + width,
    y2: top + height,
    color: color,
    radius: radius,
    thickness: thickness,
  );
}

void _drawLine(
  img.Image image, {
  required int x1,
  required int y1,
  required int x2,
  required int y2,
  required img.Color color,
  required int thickness,
}) {
  img.drawLine(
    image,
    x1: x1,
    y1: y1,
    x2: x2,
    y2: y2,
    color: color,
    thickness: thickness,
    antialias: true,
  );
}

void _fillTriangleGradient(
  img.Image image, {
  required int ax,
  required int ay,
  required int bx,
  required int by,
  required int cx,
  required int cy,
}) {
  // Triangle bounding rect.
  final minX = [ax, bx, cx].reduce(math.min);
  final maxX = [ax, bx, cx].reduce(math.max);
  final minY = [ay, by, cy].reduce(math.min);
  final maxY = [ay, by, cy].reduce(math.max);

  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      if (!_pointInTriangle(x, y, ax, ay, bx, by, cx, cy)) continue;
      // Vertical gradient: bright at apex, deeper at base.
      final t = (y - minY) / math.max(1, maxY - minY);
      final r = _lerp(0xEF, 0xD4, t);
      final g = _lerp(0xC6, 0xAF, t);
      final b = _lerp(0x56, 0x37, t);
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }
}

int _lerp(int a, int b, double t) => (a + (b - a) * t).round();

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

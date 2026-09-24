// Regenerate launcher assets with: flutter test tool/generate_app_icons.dart
// Uses the existing Flutter renderer; no extra image libraries are required.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Generate launcher icons from the ClassLift mark',
      (tester) async {
    await tester.runAsync(() async {
      final source =
          await File('assets/icons/classlift_mark.svg').readAsString();
      final square = source
          .replaceFirst(
              '<rect x="1" y="1" width="126" height="126" rx="34" fill="url(#tile)"/>',
              '<rect width="128" height="128" fill="url(#tile)"/>')
          .replaceFirst(RegExp(r'<rect[^>]+fill="none"[^>]+/>'), '');
      final maskable = square
          .replaceFirst('<path d="M26',
              '<g transform="translate(12.8 12.8) scale(0.8)"><path d="M26')
          .replaceFirst('</svg>', '</g></svg>');
      final variants = {
        'rounded': await svg.fromSvgString(source, 'rounded'),
        'square': await svg.fromSvgString(square, 'square'),
        'maskable': await svg.fromSvgString(maskable, 'maskable'),
      };
      final cache = <String, Uint8List>{};
      Future<Uint8List> render(String variant, int size,
          {bool opaque = false}) async {
        final key = '$variant-$size-$opaque';
        if (cache.containsKey(key)) return cache[key]!;
        final root = variants[variant]!;
        final recorder = ui.PictureRecorder();
        // The recording bounds must match the output, including 1024px icons.
        final canvas = ui.Canvas(
            recorder, ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));
        root.scaleCanvasToViewBox(canvas, ui.Size.square(size.toDouble()));
        root.draw(canvas, root.viewport.viewBoxRect);
        final picture = recorder.endRecording();
        final image = await picture.toImage(size, size);
        final data =
            await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
        final bytes =
            encodePng(data!.buffer.asUint8List(), size, opaque: opaque);
        image.dispose();
        picture.dispose();
        return cache[key] = bytes;
      }

      Future<void> save(String path, String variant, int size,
          {bool opaque = false}) async {
        await File(path)
            .writeAsBytes(await render(variant, size, opaque: opaque));
      }

      for (final catalog in [
        'ios/Runner/Assets.xcassets/AppIcon.appiconset',
        'macos/Runner/Assets.xcassets/AppIcon.appiconset'
      ]) {
        final contents =
            jsonDecode(await File('$catalog/Contents.json').readAsString())
                as Map<String, dynamic>;
        for (final entry in contents['images'] as List) {
          final size = (double.parse(
                      (entry['size'] as String).split('x').first) *
                  double.parse((entry['scale'] as String).replaceAll('x', '')))
              .round();
          final isIos = catalog.startsWith('ios/');
          await save('$catalog/${entry['filename']}',
              isIos ? 'square' : 'rounded', size,
              opaque: isIos);
        }
      }
      for (final density in {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192
      }.entries) {
        await save(
            'android/app/src/main/res/mipmap-${density.key}/ic_launcher.png',
            'rounded',
            density.value);
      }
      for (final size in [192, 512]) {
        await save('web/icons/Icon-$size.png', 'rounded', size);
        await save('web/icons/Icon-maskable-$size.png', 'maskable', size,
            opaque: true);
      }
      await save('web/favicon.png', 'rounded', 32);
      final icoSizes = [16, 24, 32, 48, 64, 128, 256];
      final frames = <Uint8List>[];
      for (final size in icoSizes) {
        frames.add(await render('rounded', size));
      }
      final header = ByteData(6 + 16 * frames.length)
        ..setUint16(2, 1, Endian.little)
        ..setUint16(4, frames.length, Endian.little);
      var offset = header.lengthInBytes;
      for (var i = 0; i < frames.length; i++) {
        final base = 6 + 16 * i;
        header.setUint8(base, icoSizes[i] % 256);
        header.setUint8(base + 1, icoSizes[i] % 256);
        header.setUint16(base + 4, 1, Endian.little);
        header.setUint16(base + 6, 32, Endian.little);
        header.setUint32(base + 8, frames[i].length, Endian.little);
        header.setUint32(base + 12, offset, Endian.little);
        offset += frames[i].length;
      }
      await File('windows/runner/resources/app_icon.ico').writeAsBytes([
        ...header.buffer.asUint8List(),
        for (final frame in frames) ...frame,
      ]);
    });
  });
}

/// Encode RGB for iOS (no alpha channel), RGBA for transparent desktop icons.
Uint8List encodePng(Uint8List rgba, int size, {required bool opaque}) {
  final channels = opaque ? 3 : 4;
  final rows = Uint8List(size * (1 + size * channels));
  var out = 0;
  for (var y = 0; y < size; y++) {
    rows[out++] = 0; // PNG filter: none.
    for (var x = 0; x < size; x++) {
      final pixel = (y * size + x) * 4;
      if (opaque && rgba[pixel + 3] != 255) {
        throw StateError(
            'Opaque launcher asset contains transparency at $x,$y');
      }
      for (var c = 0; c < channels; c++) {
        rows[out++] = rgba[pixel + c];
      }
    }
  }
  final header = ByteData(13)
    ..setUint32(0, size)
    ..setUint32(4, size)
    ..setUint8(8, 8)
    ..setUint8(9, opaque ? 2 : 6);
  final result = BytesBuilder()..add([137, 80, 78, 71, 13, 10, 26, 10]);
  void chunk(String type, List<int> data) {
    final payload = <int>[...ascii.encode(type), ...data];
    var crc = 0xffffffff;
    for (final byte in payload) {
      crc ^= byte;
      for (var bit = 0; bit < 8; bit++) {
        crc = (crc >> 1) ^ ((crc & 1) != 0 ? 0xedb88320 : 0);
      }
    }
    result.add((ByteData(4)..setUint32(0, data.length)).buffer.asUint8List());
    result.add(payload);
    result.add(
        (ByteData(4)..setUint32(0, crc ^ 0xffffffff)).buffer.asUint8List());
  }

  chunk('IHDR', header.buffer.asUint8List());
  chunk('IDAT', ZLibEncoder().convert(rows));
  chunk('IEND', []);
  return result.takeBytes();
}

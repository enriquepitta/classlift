// Regenerate with: flutter test --no-test-assets tool/generate_app_icons.dart
// Uses the existing Flutter renderer; no extra image libraries are required.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:classlift/utils/classlift_colors.dart';
import 'package:flutter_test/flutter_test.dart';

enum IconStyle {
  square(opaque: true),
  rounded,
  // Android draws 108dp layers through a 72dp visible mask.
  adaptive(imageScale: 76 / 108, opaque: true),
  monochrome(imageScale: 76 / 108);

  const IconStyle({
    this.imageScale = 1,
    this.opaque = false,
  });

  final double imageScale;
  final bool opaque;
}

void main() {
  testWidgets('Generate launcher icons from the ClassLift artwork',
      (tester) async {
    await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(
        await File('tool/classlift_app_icon.jpg').readAsBytes(),
      );
      final source = (await codec.getNextFrame()).image;
      codec.dispose();
      addTearDown(source.dispose);
      expect(source.width, source.height);
      final coloredSource = await _useCalendarBlue(source);
      addTearDown(coloredSource.dispose);

      final cache = <(IconStyle, int), Uint8List>{};
      Future<Uint8List> render(IconStyle style, int size) async {
        final key = (style, size);
        final cached = cache[key];
        if (cached != null) return cached;

        final side = size.toDouble();
        final bounds = ui.Offset.zero & ui.Size.square(side);
        final imageSide = side * style.imageScale;
        final scale = imageSide / source.width;
        final inset = (side - imageSide) / 2;
        // Extend the edge pixels into the margins used by adaptive masks.
        final shader = ui.ImageShader(
          style == IconStyle.monochrome ? source : coloredSource,
          ui.TileMode.clamp,
          ui.TileMode.clamp,
          Float64List(16)
            ..[0] = scale
            ..[5] = scale
            ..[10] = 1
            ..[12] = inset
            ..[13] = inset
            ..[15] = 1,
          filterQuality: ui.FilterQuality.high,
        );
        final paint = ui.Paint()..shader = shader;
        if (style == IconStyle.monochrome) {
          // Both letters have a low red channel against the pale artwork.
          // Turn that contrast into an alpha mask for Android's themed icon.
          paint.colorFilter = const ui.ColorFilter.matrix([
            0, 0, 0, 0, 255, // Red
            0, 0, 0, 0, 255, // Green
            0, 0, 0, 0, 255, // Blue
            -3, 0, 0, 0, 510, // Alpha
          ]);
        }

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder, bounds);
        if (style == IconStyle.rounded) {
          canvas.clipRRect(
            ui.RRect.fromRectAndRadius(bounds, ui.Radius.circular(side * 0.24)),
          );
        }
        canvas.drawRect(bounds, paint);
        final picture = recorder.endRecording();
        final image = await picture.toImage(size, size);
        final data =
            await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
        image.dispose();
        picture.dispose();
        shader.dispose();
        return cache[key] = encodePng(
          data!.buffer.asUint8List(),
          size,
          opaque: style.opaque,
        );
      }

      Future<void> save(String path, IconStyle style, int size) async {
        final file = File(path);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(await render(style, size));
      }

      const iosCatalog = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
      final contents =
          jsonDecode(await File('$iosCatalog/Contents.json').readAsString())
              as Map<String, dynamic>;
      for (final entry in contents['images'] as List) {
        final points = double.parse((entry['size'] as String).split('x').first);
        final scale = int.parse((entry['scale'] as String).replaceAll('x', ''));
        final size = (points * scale).round();
        await save('$iosCatalog/${entry['filename']}', IconStyle.square, size);
      }
      const androidResources = 'android/app/src/main/res';
      for (final density in {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192
      }.entries) {
        await save('$androidResources/mipmap-${density.key}/ic_launcher.png',
            IconStyle.rounded, density.value);
      }
      await save('$androidResources/drawable-nodpi/ic_launcher_background.png',
          IconStyle.adaptive, 432);
      await save('$androidResources/drawable-nodpi/ic_launcher_monochrome.png',
          IconStyle.monochrome, 432);

      const splashSize = 144;
      const iosLaunchImages = 'ios/Runner/Assets.xcassets/LaunchImage.imageset';
      for (final scale in [1, 2, 3]) {
        final suffix = scale == 1 ? '' : '@${scale}x';
        await save('$iosLaunchImages/LaunchImage$suffix.png', IconStyle.rounded,
            splashSize * scale);
      }
      await save('$androidResources/drawable-xxhdpi/launch_image.png',
          IconStyle.rounded, splashSize * 3);
      await save('assets/images/classlift_splash.png', IconStyle.rounded,
          splashSize * 3);
    });
  });
}

Future<ui.Image> _useCalendarBlue(ui.Image source) async {
  final data =
      await source.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
  final rgba = data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final calendarBlue = ClassliftColors.calendarSurface.toARGB32();
  final replacement = [
    for (final shift in [16, 8, 0]) calendarBlue >> shift & 255
  ];
  const original = [1, 89, 242];

  for (var pixel = 0; pixel < rgba.length; pixel += 4) {
    // The electric-blue L has much higher blue–green contrast than the
    // navy C and the pale wave. Partial coverage keeps its edges smooth.
    final chroma = rgba[pixel + 2] - rgba[pixel + 1];
    if (chroma <= 54) continue;
    final coverage = ((chroma - 54) / (150 - 54)).clamp(0.0, 1.0);
    for (var channel = 0; channel < replacement.length; channel++) {
      final index = pixel + channel;
      final shift = (replacement[channel] - original[channel]) * coverage;
      rgba[index] = coverage == 1
          ? replacement[channel]
          : (rgba[index] + shift).round().clamp(0, 255);
    }
  }

  final image = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    rgba,
    source.width,
    source.height,
    ui.PixelFormat.rgba8888,
    image.complete,
  );
  return image.future;
}

/// Encode RGB for opaque icons and RGBA for artwork with transparency.
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

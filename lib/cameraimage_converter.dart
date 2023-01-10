library cameraimage_converter;

import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart';
import 'package:camera/camera.dart';

class CameraImageConverter {
  CameraImageConverter._();

  ///
  /// ```
  /// final Image? png = PngDecoder().decode(result);
  /// ```
  static Future<Uint8List?> convertImageToPng(
    CameraImage cameraImage, {
    bool singleFrame = false,
  }) async {
    try {
      Image? image;
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        image = _convertYUV420(cameraImage);
      } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        image = _convertBGRA8888(cameraImage);
      }

      // Convert to png
      Uint8List? png;
      if (image is Image) {
        png = PngEncoder().encode(image, singleFrame: singleFrame);
      }

      return png;
    } catch (e) {
      log('ERROR: ${e.toString()}');
    }
    return null;
  }

  ///
  /// ```
  /// final Image? jpeg = JpegDecoder().decode(bytes);
  /// ```
  static Future<Uint8List?> convertImageToJpeg(
    CameraImage cameraImage, {
    int quality = 100,
    bool singleFrame = false,
  }) async {
    try {
      Image? image;
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        image = _convertYUV420(cameraImage);
      } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        image = _convertBGRA8888(cameraImage);
      }

      // Convert to jpeg
      Uint8List? jpeg;
      if (image is Image) {
        jpeg = JpegEncoder(quality: quality)
            .encode(image, singleFrame: singleFrame);
      }

      return jpeg;
    } catch (e) {
      log('ERROR: ${e.toString()}');
    }
    return null;
  }

  /// CameraImage YUV420_888 -> Image (compresion:0, filter: none)
  /// Black
  static Image _convertYUV420(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;
    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!;
    // https://gist.github.com/Alby-o/fe87e35bc21d534c8220aed7df028e03?permalink_comment_id=3989031#gistcomment-3989031
    const shift = (0xFF << 24);

    // Create Image buffer
    final Image image = Image(width: width, height: height);
    final data = image.data!.toUint8List();
    // Fill image buffer with plane[0] from YUV420_888
    for (int x = 0; x < image.width; x++) {
      for (int y = 0; y < image.height; y++) {
        final int uvIndex =
            uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int index = y * width + x;

        final yp = cameraImage.planes[0].bytes[index];
        final up = cameraImage.planes[1].bytes[uvIndex];
        final vp = cameraImage.planes[2].bytes[uvIndex];
        // Calculate pixel color
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

        // color: 0x FF  FF  FF  FF
        //           A   B   G   R
        data[index] = shift | (b << 16) | (g << 8) | r;
      }
    }
    return Image.fromBytes(
      width: width,
      height: height,
      bytes: data.buffer,
    );
  }

  /// CameraImage BGRA8888 -> Image
  /// Color
  static Image _convertBGRA8888(CameraImage image) {
    return Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
    );
  }
}

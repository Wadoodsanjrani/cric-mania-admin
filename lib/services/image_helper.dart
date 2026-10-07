import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Image Helper — File to Base64 (compressed)
/// Firestore ke 1 MB document limit ko respect karta hai
class ImageHelper {
  /// Convert File to base64 string (compressed to ~200 KB max)
  ///
  /// [maxWidth]  — max width in pixels (default: 600)
  /// [quality]   — JPEG quality (default: 70)
  static Future<String> fileToBase64(
    File file, {
    int maxWidth = 600,
    int quality = 70,
  }) async {
    try {
      // Read file bytes
      final bytes = await file.readAsBytes();

      // Decode image
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Invalid image format');
      }

      // Resize if too large
      if (image.width > maxWidth) {
        image = img.copyResize(
          image,
          width: maxWidth,
          interpolation: img.Interpolation.linear,
        );
      }

      // Encode as JPEG with quality
      final compressed = img.encodeJpg(image, quality: quality);

      // Convert to base64 with data URI prefix
      final base64String = base64Encode(compressed);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      debugPrint('ImageHelper.fileToBase64 error: $e');
      rethrow;
    }
  }

  /// Decode base64 string back to bytes (for displaying)
  static Uint8List base64ToBytes(String base64String) {
    try {
      // Remove data URI prefix if present
      final pureBase64 = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;
      return base64Decode(pureBase64);
    } catch (e) {
      debugPrint('ImageHelper.base64ToBytes error: $e');
      return Uint8List(0);
    }
  }

  /// Get size of base64 string in KB
  static double base64SizeKB(String base64String) {
    return base64String.length / 1024;
  }

  /// Check if base64 string is safe for Firestore (under 800 KB)
  static bool isSafeForFirestore(String base64String) {
    return base64SizeKB(base64String) < 800;
  }
}
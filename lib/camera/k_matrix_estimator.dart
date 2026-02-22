/// Estimates or uses camera intrinsic matrix (K) for display.
/// Uses LENS_INTRINSIC_CALIBRATION when valid; otherwise estimates from
/// availableFocalLengths (mm), sensor physicalSize (mm), and pixelArraySize.
library;

/// Returns [fx, fy, cx, cy] in pixels, or null if unavailable.
///
/// [intrinsics] from LENS_INTRINSIC_CALIBRATION (length >= 5, not all near zero).
/// [characteristics] full map from getCameraCharacteristics (for fallback).
List<double>? resolveKMatrix(
  List<double>? intrinsics,
  Map<String, dynamic>? characteristics,
) {
  if (_isValidIntrinsics(intrinsics)) {
    return intrinsics!.length >= 4
        ? intrinsics.sublist(0, 4)
        : null;
  }
  return estimateKFromCharacteristics(characteristics);
}

bool _isValidIntrinsics(List<double>? intrinsics) {
  if (intrinsics == null || intrinsics.length < 5) return false;
  const epsilon = 1e-6;
  if (intrinsics.every((v) => v.abs() < epsilon)) return false;
  return true;
}

/// Estimate K from focal length (mm), sensor physical size (mm), pixel array size.
/// Keys (Android): android.lens.info.availableFocalLengths, android.sensor.info.physicalSize,
/// android.sensor.info.pixelArraySize.
List<double>? estimateKFromCharacteristics(Map<String, dynamic>? characteristics) {
  if (characteristics == null) return null;

  // availableFocalLengths: list of numbers (mm), use first
  final focalList = characteristics['android.lens.info.availableFocalLengths'];
  double? focalMm;
  if (focalList is List && focalList.isNotEmpty) {
    final first = focalList.first;
    if (first is num) focalMm = first.toDouble();
  }
  if (focalMm == null || focalMm <= 0) return null;

  // physicalSize: "4.71x3.49" (width x height mm)
  final physicalStr = characteristics['android.sensor.info.physicalSize'];
  if (physicalStr is! String) return null;
  final physical = _parseSize(physicalStr);
  if (physical == null) return null;

  // pixelArraySize: "4208x3120"
  final pixelStr = characteristics['android.sensor.info.pixelArraySize'];
  if (pixelStr is! String) return null;
  final pixel = _parseSize(pixelStr);
  if (pixel == null) return null;

  final sensorWidthMm = physical.$1;
  final sensorHeightMm = physical.$2;
  final widthPx = pixel.$1.toDouble();
  final heightPx = pixel.$2.toDouble();
  if (sensorWidthMm <= 0 || sensorHeightMm <= 0 || widthPx <= 0 || heightPx <= 0) {
    return null;
  }

  final fx = (focalMm / sensorWidthMm) * widthPx;
  final fy = (focalMm / sensorHeightMm) * heightPx;
  final cx = widthPx / 2;
  final cy = heightPx / 2;

  return [fx, fy, cx, cy];
}

/// Parses "4.71x3.49" or "4208x3120" -> (width, height).
(double, double)? _parseSize(String s) {
  final parts = s.split(RegExp(r'[x×]'));
  if (parts.length != 2) return null;
  final w = double.tryParse(parts[0].trim());
  final h = double.tryParse(parts[1].trim());
  if (w == null || h == null || w <= 0 || h <= 0) return null;
  return (w, h);
}

import 'dart:math';

import 'package:webrtc_interface/webrtc_interface.dart';

import 'utils.dart';

enum CameraFocusMode { auto, locked }

enum CameraExposureMode { auto, locked }

class CameraUtils {
  static Future<void> setZoom(
      MediaStreamTrack videoTrack, double zoomLevel) async {
    if (WebRTC.platformIsAndroid || WebRTC.platformIsIOS) {
      await WebRTC.invokeMethod(
        'mediaStreamTrackSetZoom',
        <String, dynamic>{'trackId': videoTrack.id, 'zoomLevel': zoomLevel},
      );
    } else {
      throw Exception('setZoom only support for mobile devices!');
    }
  }

  /// Set manual focus distance in diopters (Android API 28+).
  /// 0 = infinity; larger values = closer focus.
  static Future<void> setFocusDistance(
      MediaStreamTrack videoTrack, double diopters) async {
    if (WebRTC.platformIsAndroid) {
      await WebRTC.invokeMethod(
        'mediaStreamTrackSetFocusDistance',
        <String, dynamic>{'trackId': videoTrack.id, 'diopters': diopters},
      );
    }
    // iOS / other: no-op (no API exposed)
  }

  /// Returns max focus distance in diopters for the camera (Android).
  /// 0 means fixed focus (infinity only).
  static Future<double> getMaxFocusDistanceDiopters(
      MediaStreamTrack videoTrack) async {
    if (WebRTC.platformIsAndroid) {
      final result = await WebRTC.invokeMethod(
        'mediaStreamTrackGetMaxFocusDistanceDiopters',
        <String, dynamic>{'trackId': videoTrack.id},
      );
      return (result as num?)?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  /// Returns camera intrinsic calibration [fx, fy, cx, cy, ...] (Android).
  /// Null if not supported (e.g. LENS_INTRINSIC_CALIBRATION unavailable).
  static Future<List<double>?> getCameraIntrinsics(
      MediaStreamTrack videoTrack) async {
    if (WebRTC.platformIsAndroid) {
      final result = await WebRTC.invokeMethod(
        'mediaStreamTrackGetCameraIntrinsics',
        <String, dynamic>{'trackId': videoTrack.id},
      );
      if (result == null) return null;
      final list = result as List<dynamic>?;
      if (list == null || list.length < 4) return null;
      return list.map((e) => (e as num).toDouble()).toList();
    }
    return null;
  }

  /// Returns all camera characteristics as a map (Android).
  /// Keys are e.g. "android.lens.facing", values are String, num, bool, or List.
  static Future<Map<String, dynamic>?> getCameraCharacteristics(
      MediaStreamTrack videoTrack) async {
    if (WebRTC.platformIsAndroid) {
      final result = await WebRTC.invokeMethod(
        'mediaStreamTrackGetCameraCharacteristics',
        <String, dynamic>{'trackId': videoTrack.id},
      );
      if (result == null) return null;
      return Map<String, dynamic>.from(result as Map);
    }
    return null;
  }

  /// Set the exposure point for the camera, focusMode can be:
  /// 'auto', 'locked'
  static Future<void> setFocusMode(
      MediaStreamTrack videoTrack, CameraFocusMode focusMode) async {
    if (WebRTC.platformIsAndroid || WebRTC.platformIsIOS) {
      await WebRTC.invokeMethod(
        'mediaStreamTrackSetFocusMode',
        <String, dynamic>{
          'trackId': videoTrack.id,
          'focusMode': focusMode.name,
        },
      );
    } else {
      throw Exception('setFocusMode only support for mobile devices!');
    }
  }

  static Future<void> setFocusPoint(
      MediaStreamTrack videoTrack, Point<double>? point) async {
    if (WebRTC.platformIsAndroid || WebRTC.platformIsIOS) {
      await WebRTC.invokeMethod(
        'mediaStreamTrackSetFocusPoint',
        <String, dynamic>{
          'trackId': videoTrack.id,
          'focusPoint': {
            'reset': point == null,
            'x': point?.x,
            'y': point?.y,
          },
        },
      );
    } else {
      throw Exception('setFocusPoint only support for mobile devices!');
    }
  }

  static Future<void> setExposureMode(
      MediaStreamTrack videoTrack, CameraExposureMode exposureMode) async {
    if (WebRTC.platformIsAndroid || WebRTC.platformIsIOS) {
      await WebRTC.invokeMethod(
        'mediaStreamTrackSetExposureMode',
        <String, dynamic>{
          'trackId': videoTrack.id,
          'exposureMode': exposureMode.name,
        },
      );
    } else {
      throw Exception('setExposureMode only support for mobile devices!');
    }
  }

  static Future<void> setExposurePoint(
      MediaStreamTrack videoTrack, Point<double>? point) async {
    if (WebRTC.platformIsAndroid || WebRTC.platformIsIOS) {
      await WebRTC.invokeMethod(
        'mediaStreamTrackSetExposurePoint',
        <String, dynamic>{
          'trackId': videoTrack.id,
          'exposurePoint': {
            'reset': point == null,
            'x': point?.x,
            'y': point?.y,
          },
        },
      );
    } else {
      throw Exception('setExposurePoint only support for mobile devices!');
    }
  }
}

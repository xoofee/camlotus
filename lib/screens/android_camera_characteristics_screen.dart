import 'package:flutter/material.dart';

/// Android Camera2 CameraCharacteristics enum value names for display.
/// See https://developer.android.com/reference/android/hardware/camera2/CameraMetadata
const Map<String, Map<int, String>> _androidCameraEnumNames = {
  'android.lens.facing': {0: 'BACK', 1: 'FRONT', 2: 'EXTERNAL'},
  'android.lens.info.focusDistanceCalibration': {
    0: 'UNCALIBRATED',
    1: 'APPROXIMATE',
    2: 'CALIBRATED',
  },
  'android.control.afAvailableModes': {
    0: 'OFF',
    1: 'AUTO',
    2: 'MACRO',
    3: 'CONTINUOUS_VIDEO',
    4: 'CONTINUOUS_PICTURE',
    5: 'EDOF',
  },
  'android.control.aeAvailableModes': {
    0: 'OFF',
    1: 'ON',
    2: 'ON_AUTO_FLASH',
    3: 'ON_ALWAYS_FLASH',
    4: 'ON_AUTO_FLASH_REDEYE',
  },
  'android.info.supportedHardwareLevel': {
    0: 'LEGACY',
    1: 'LIMITED',
    2: 'FULL',
    3: 'LEVEL_3',
  },
  'android.scaler.croppingType': {
    0: 'CENTER_ONLY',
    1: 'FREE_CROP',
  },
  'android.sensor.info.colorFilterArrangement': {
    0: 'RGGB',
    1: 'GRBG',
    2: 'GBRG',
    3: 'BAYER_BGGR',
  },
  'android.sensor.referenceIlluminant1': {
    0: 'DAYLIGHT',
    1: 'FLUORESCENT',
    2: 'TUNGSTEN',
    3: 'FLASH',
    4: 'FINE_WEATHER',
    5: 'CLOUDY_WEATHER',
    6: 'SHADE',
    7: 'TWILIGHT',
    8: 'FLUORESCENT_HIGH',
    9: 'WARM_FLUORESCENT',
    10: 'FLUORESCENT_LOW',
    11: 'INCANDESCENT',
    12: 'ISO_STUDIO_TUNGSTEN',
    17: 'STANDARD_A',
    18: 'STANDARD_B',
    19: 'STANDARD_C',
    20: 'D50',
    21: 'D55',
    22: 'D65',
    23: 'D75',
    24: 'D50',
  },
  'android.statistics.info.availableFaceDetectModes': {
    0: 'OFF',
    1: 'SIMPLE',
    2: 'FULL',
  },
  'android.tonemap.availableToneMapModes': {
    0: 'CONTRAST_CURVE',
    1: 'FAST',
    2: 'HIGH_QUALITY',
  },
  'android.edge.availableEdgeModes': {
    0: 'OFF',
    1: 'FAST',
    2: 'HIGH_QUALITY',
    3: 'ZERO_SHUTTER_LAG',
  },
  'android.noiseReduction.availableNoiseReductionModes': {
    0: 'OFF',
    1: 'FAST',
    2: 'HIGH_QUALITY',
    3: 'MINIMAL',
    4: 'ZERO_SHUTTER_LAG',
  },
  'android.shading.availableModes': {
    0: 'OFF',
    1: 'FAST',
    2: 'HIGH_QUALITY',
  },
  'android.hotPixel.availableHotPixelModes': {
    0: 'OFF',
    1: 'FAST',
    2: 'HIGH_QUALITY',
  },
  'android.colorCorrection.availableAberrationModes': {
    0: 'OFF',
    1: 'FAST',
    2: 'HIGH_QUALITY',
  },
};

/// Keys to show in the top summary list (order preserved).
const List<String> _topKeys = [
  'android.sensor.info.physicalSize',
  'android.lens.info.availableFocalLengths',
  'android.sensor.info.pixelArraySize',
  'android.lens.info.minimumFocusDistance',
];

String _formatValue(String key, dynamic value) {
  if (value == null) return 'null';
  final enumMap = _androidCameraEnumNames[key];
  if (value is List) {
    final list = value;
    if (enumMap != null && list.every((e) => e is int)) {
      final names = list.map((e) => enumMap[e as int] ?? e.toString()).toList();
      return names.join(', ');
    }
    return list.toString();
  }
  if (value is int && enumMap != null) {
    final name = enumMap[value];
    if (name != null) return '$name ($value)';
  }
  return value.toString();
}

/// Displays Android Camera2 characteristics (from getCameraCharacteristics).
/// Shows a top summary of selected keys, then full table with enum names where known.
class AndroidCameraCharacteristicsScreen extends StatelessWidget {
  const AndroidCameraCharacteristicsScreen({
    super.key,
    required this.characteristics,
    this.cameraId,
  });

  final Map<String, dynamic> characteristics;
  final String? cameraId;

  List<MapEntry<String, dynamic>> _orderedEntries() {
    final topEntries = <MapEntry<String, dynamic>>[];
    for (final k in _topKeys) {
      if (characteristics.containsKey(k)) {
        topEntries.add(MapEntry(k, characteristics[k]));
      }
    }
    final rest = characteristics.entries
        .where((e) => !_topKeys.contains(e.key))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return [...topEntries, ...rest];
  }

  @override
  Widget build(BuildContext context) {
    final ordered = _orderedEntries();
    final topEntries = ordered.where((e) => _topKeys.contains(e.key)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          cameraId != null
              ? 'Camera characteristics ($cameraId)'
              : 'Camera characteristics (Android)',
        ),
      ),
      body: ordered.isEmpty
          ? const Center(child: Text('No characteristics available'))
          : ListView(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'Key',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'Value',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 1),
                ...ordered.asMap().entries.map((pair) {
                  final index = pair.key;
                  final e = pair.value;
                  final valueStr = _formatValue(e.key, e.value);
                  final row = Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: SelectableText(
                            e.key,
                            maxLines: null,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: SelectableText(
                            valueStr,
                            maxLines: null,
                          ),
                        ),
                      ),
                    ],
                  );
                  return Container(
                    color: index.isEven ? Colors.grey.shade200 : null,
                    child: row,
                  );
                }),
              ],
            ),
    );
  }
}

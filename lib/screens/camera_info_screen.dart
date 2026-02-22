import 'package:flutter/material.dart';

/// Displays camera characteristics in a table (e.g. from Android getCameraCharacteristics).
class CameraInfoScreen extends StatelessWidget {
  const CameraInfoScreen({
    super.key,
    required this.characteristics,
    this.cameraId,
  });

  final Map<String, dynamic> characteristics;
  final String? cameraId;

  @override
  Widget build(BuildContext context) {
    final entries = characteristics.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      appBar: AppBar(
        title: Text(cameraId != null ? 'Camera info ($cameraId)' : 'Camera info'),
      ),
      body: entries.isEmpty
          ? const Center(child: Text('No characteristics available'))
          : ListView(
              children: [
                // Header row: Key | Value, each half width
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
                ...entries.asMap().entries.map((pair) {
                  final index = pair.key;
                  final e = pair.value;
                  final valueStr = e.value is List
                      ? e.value.toString()
                      : e.value.toString();
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

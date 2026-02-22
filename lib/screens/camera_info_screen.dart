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
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('Key', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Value', style: TextStyle(fontWeight: FontWeight.w600))),
                  ],
                  rows: entries.map((e) {
                    final value = e.value;
                    final valueStr = value is List
                        ? value.toString()
                        : value.toString();
                    final truncated = valueStr.length > 200
                        ? '${valueStr.substring(0, 200)}…'
                        : valueStr;
                    return DataRow(
                      cells: [
                        DataCell(SelectableText(e.key)),
                        DataCell(SelectableText(truncated)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }
}

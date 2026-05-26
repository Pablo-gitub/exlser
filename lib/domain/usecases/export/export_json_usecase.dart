import 'dart:convert';
import 'dart:typed_data';

import 'package:exlser/core/serializers/dataset_json_serializer.dart';
import 'package:exlser/domain/entities/exported_file.dart';
import 'package:exlser/domain/usecases/export/export_dataset_data.dart';
import 'package:exlser/domain/value_objects/export_format.dart';

class ExportJsonUseCase {
  const ExportJsonUseCase();

  ExportedFile call(ExportDatasetData data) {
    const encoder = JsonEncoder.withIndent('  ');
    final json = encoder.convert(DatasetJsonSerializer.dataset(data));

    return ExportedFile(
      name: _sanitizeFileName(data.dataset.name, fallback: 'dataset'),
      extension: ExportFormat.json.extension,
      mimeType: 'application/json',
      format: ExportFormat.json,
      bytes: Uint8List.fromList(utf8.encode(json)),
    );
  }

  String _sanitizeFileName(String value, {required String fallback}) {
    final sanitized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    return sanitized.isEmpty ? fallback : sanitized;
  }
}

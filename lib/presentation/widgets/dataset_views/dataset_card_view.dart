import 'package:easy_localization/easy_localization.dart';
import 'package:exel_category/core/constants/app_strings.dart';
import 'package:exel_category/core/serializers/dataset_json_serializer.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

class DatasetCardView extends StatelessWidget {
  final List<DatasetColumn> columns;
  final List<Map<String, dynamic>> rows;

  const DatasetCardView({
    super.key,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    if (columns.isEmpty || rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      itemCount: rows.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final row = rows[index];

        return _DatasetRowCard(
          columns: columns,
          row: row,
        );
      },
    );
  }
}

class _DatasetRowCard extends StatelessWidget {
  final List<DatasetColumn> columns;
  final Map<String, dynamic> row;

  const _DatasetRowCard({
    required this.columns,
    required this.row,
  });

  @override
  Widget build(BuildContext context) {
    final rowJson = DatasetJsonSerializer.compactRowJson(
      columns: columns,
      row: row,
    );

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final qrSize = constraints.maxWidth < 380 ? 96.0 : 116.0;
            final content = _DatasetCardFields(
              columns: columns,
              row: row,
            );
            final qr = DatasetRowQrCode(
              data: rowJson,
              dimension: qrSize,
            );

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: content),
                  const VerticalDivider(width: 24),
                  qr,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DatasetCardFields extends StatelessWidget {
  final List<DatasetColumn> columns;
  final Map<String, dynamic> row;

  const _DatasetCardFields({
    required this.columns,
    required this.row,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final column in columns) ...[
          Text(
            column.originalName,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 2),
          Text(_formatCellValue(row[column.dbName])),
          if (column != columns.last) const Divider(height: 16),
        ],
      ],
    );
  }
}

class DatasetRowQrCode extends StatelessWidget {
  final String data;
  final double dimension;

  const DatasetRowQrCode({
    super.key,
    required this.data,
    this.dimension = 116,
  });

  @override
  Widget build(BuildContext context) {
    final image = _tryCreateQrImage(data);

    if (image == null) {
      return Tooltip(
        message: AppStrings.datasetWorkspaceQrUnavailable.tr(),
        child: SizedBox.square(
          dimension: dimension,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.qr_code_2),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: AppStrings.datasetWorkspaceQrTooltip.tr(),
      child: SizedBox.square(
        dimension: dimension,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: CustomPaint(
              painter: _QrPainter(image),
            ),
          ),
        ),
      ),
    );
  }

  QrImage? _tryCreateQrImage(String data) {
    try {
      final code = QrCode.fromData(
        data: data,
        errorCorrectLevel: QrErrorCorrectLevel.L,
      );
      return QrImage(code);
    } catch (_) {
      return null;
    }
  }
}

class _QrPainter extends CustomPainter {
  final QrImage image;

  _QrPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final moduleSize = size.shortestSide / image.moduleCount;
    final offsetX = (size.width - moduleSize * image.moduleCount) / 2;
    final offsetY = (size.height - moduleSize * image.moduleCount) / 2;

    for (var x = 0; x < image.moduleCount; x++) {
      for (var y = 0; y < image.moduleCount; y++) {
        if (!image.isDark(y, x)) continue;

        canvas.drawRect(
          Rect.fromLTWH(
            offsetX + x * moduleSize,
            offsetY + y * moduleSize,
            moduleSize,
            moduleSize,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) {
    return oldDelegate.image != image;
  }
}

String _formatCellValue(dynamic value) {
  if (value == null) return '';

  return value.toString();
}

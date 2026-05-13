import 'package:exel_category/domain/entities/parsed_sheet.dart';

abstract class SpreadsheetParser {
  Future<List<ParsedSheet>> parsePath(String path);

  Future<List<ParsedSheet>> parseBytes(List<int> bytes);
}

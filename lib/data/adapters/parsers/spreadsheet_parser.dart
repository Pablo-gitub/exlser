import 'package:exel_category/domain/entities/parsed_sheet.dart';

abstract class SpreadsheetParser {
  Future<List<ParsedSheet>> parse(String filePath);
}
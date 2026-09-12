import 'package:exlser/domain/entities/parsed_sheet.dart';

abstract class SpreadsheetParser {
  Future<List<ParsedSheet>> parsePath(
    String path, {
    bool detectMultipleTables = true,
  });

  Future<List<ParsedSheet>> parseBytes(
    List<int> bytes, {
    bool detectMultipleTables = true,
  });
}

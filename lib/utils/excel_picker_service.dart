// services/excel_picker_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:xml/xml.dart';

// services/excel_picker_service.dart
class ExcelPickerService {
  static Future<Map<String, dynamic>> pickSheets() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result == null) throw Exception('Selección cancelada');

    final filePath = result.files.single.path!;
    final bytes = await File(filePath).readAsBytes();
    final sheets = filePath.toLowerCase().endsWith('.xlsx')
        ? _readXlsxSheetNames(bytes)
        : Excel.decodeBytes(bytes).tables.keys.toList();
    if (sheets.isEmpty) throw Exception('Sin hojas en el Excel');

    return {
      'sheets': sheets,
      'path': filePath,
    };
  }

  static List<String> _readXlsxSheetNames(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes, verify: false);
    final workbookFiles =
        archive.files.where((file) => file.name == 'xl/workbook.xml');
    if (workbookFiles.isEmpty || workbookFiles.first.content is! List<int>) {
      throw const FormatException(
          'El archivo Excel no contiene un libro válido.');
    }

    final workbook = XmlDocument.parse(
      utf8.decode(workbookFiles.first.content as List<int>),
    );
    return workbook
        .findAllElements('sheet')
        .map((sheet) => sheet.getAttribute('name'))
        .whereType<String>()
        .toList();
  }
}

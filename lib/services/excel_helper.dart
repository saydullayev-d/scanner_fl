import 'dart:io';
import 'package:excel/excel.dart';

class ExcelHelper {
  final String filePath;

  ExcelHelper({required this.filePath});

  /// Создает новый Excel файл, если его нет.
  Future<void> createExcelFile() async {
    final file = File(filePath);
    if (!await file.exists()) {
      var excel = Excel.createExcel();
      Sheet sheet = excel['ScannedData'];
      sheet.appendRow(['Data']); // Заголовок таблицы
      file.writeAsBytesSync(excel.save()!);
    }
  }

  /// Проверяет, есть ли данные в Excel.
  Future<bool> isDataUnique(String data) async {
    final file = File(filePath);
    var bytes = file.readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    Sheet? sheet = excel['ScannedData'];
    if (sheet == null) return true;

    for (var row in sheet.rows.skip(1)) { // Пропускаем заголовок
      if (row.isNotEmpty && row.first?.value == data) {
        return false;
      }
    }
    return true;
  }

  /// Добавляет новые данные в Excel.
  Future<void> addData(String data) async {
    final file = File(filePath);
    var bytes = file.readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    Sheet? sheet = excel['ScannedData'];
    if (sheet != null) {
      sheet.appendRow([data]);
      file.writeAsBytesSync(excel.save()!);
    }
  }
}

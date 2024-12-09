import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class ExcelHelper {
  String? filePath;

  /// Инициализация пути к файлу
  Future<void> initializeFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final formatter = DateFormat('dd-MM-yyyy');
    final currentDate = formatter.format(now);

    // Задаем путь к файлу
    filePath = '${directory.path}/$currentDate.xlsx';
  }

  /// Создает Excel файл, если он не существует
  Future<void> createExcelFile() async {
    await initializeFilePath();
    final file = File(filePath!);
    final now = DateTime.now();
    final formatter = DateFormat('dd-MM-yyyy');
    final currentDate = formatter.format(now);
    if (!await file.exists()) {
      try {
        var excel = Excel.createExcel();
        // Работать с первым листом
        var firstSheet = excel.tables.keys.first;
        var sheet = excel[firstSheet];
        sheet.appendRow(['Счёт фактура от $currentDate']); // Добавляем заголовок
        // Сохраняем файл
        List<int> bytes = excel.encode()!;
        await file.writeAsBytes(bytes, flush: true);
      } catch (e) {
        print('Error creating Excel file: $e');
      }
    }
  }

  /// Проверяет, есть ли данные в Excel
  Future<bool> isDataUnique(String data) async {
    await createExcelFile(); // Убедимся, что файл существует
    final file = File(filePath!);
    var bytes = file.readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    // Работаем с первым листом
    var firstSheetName = excel.tables.keys.first;
    Sheet? sheet = excel[firstSheetName];
    if (sheet == null) return true;

    for (var row in sheet.rows.skip(1)) { // Пропускаем заголовок
      if (row.isNotEmpty && row.first?.value == data) {
        return false;
      }
    }
    return true;
  }

  /// Добавляет новые данные в первый лист Excel
  Future<void> addData(String data) async {
    await createExcelFile(); // Убедимся, что файл существует
    final file = File(filePath!);
    var bytes = file.readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    // Работаем с первым листом
    var firstSheetName = excel.tables.keys.first;
    Sheet? sheet = excel[firstSheetName];
    if (sheet != null) {
      sheet.appendRow([data]); // Добавляем новую строку
      file.writeAsBytesSync(excel.save()!); // Сохраняем изменения
    } else {
      print('Ошибка: Первый лист не найден!');
    }
  }

  /// Получает список всех Excel файлов в каталоге
  Future<List<String>> getExcelFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync().where((file) {
        return file is File && file.path.endsWith('.xlsx');
      }).map((file) => file.path).toList();
      return files;
    } catch (e) {
      print('Error getting Excel files: $e');
      return [];
    }
  }
}

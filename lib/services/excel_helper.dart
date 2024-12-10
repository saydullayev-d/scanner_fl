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
        var firstSheet = excel.tables.keys.first;
        var sheet = excel[firstSheet];
        sheet.appendRow(['Счёт фактура от $currentDate']); // Заголовок добавляется только один раз
        file.writeAsBytesSync(excel.save()!, flush: true);
      } catch (e) {
        print('Ошибка при создании файла Excel: $e');
      }
    }
  }

  /// Проверяет, есть ли данные в Excel
  Future<bool> isDataUnique(String data) async {
    await createExcelFile();
    final file = File(filePath!);
    var bytes = file.readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    var firstSheetName = excel.tables.keys.first;
    Sheet? sheet = excel[firstSheetName];
    if (sheet == null) return true;

    for (var row in sheet.rows) {
      // Проверяем, что в строке есть хотя бы одна ячейка, и она равна искомому значению
      if (row.isNotEmpty && row.first?.value?.toString() == data) {
        print('Найдено дублирующееся значение: $data');
        return false;
      }
    }
    return true;
  }



  /// Добавляет новые данные в первый лист Excel
  Future<void> addData(String data) async {
    await createExcelFile();
    final file = File(filePath!);
    var bytes = file.readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    var firstSheetName = excel.tables.keys.first;
    Sheet? sheet = excel[firstSheetName];
    if (sheet != null) {
      // Проверяем уникальность перед добавлением
      if (await isDataUnique(data)) {
        sheet.appendRow([data]);
        // Сохраняем изменения в файл
        file.writeAsBytesSync(excel.save()!, flush: true);
        print('Данные добавлены: $data');
      } else {
        print('Данные уже существуют: $data');
      }
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

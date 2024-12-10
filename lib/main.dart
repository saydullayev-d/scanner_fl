import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scanner/services/excel_helper.dart';
import 'package:scanner/view/scanner_page.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Сканнер',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ScannerPage(),
    );
  }
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final ExcelHelper _excelHelper = ExcelHelper(); // Экземпляр ExcelHelper
  List<String> files = []; // Список путей к файлам Excel

  @override
  void initState() {
    super.initState();
    _loadExcelFiles(); // Загрузка файлов при запуске
  }

  Future<void> _loadExcelFiles() async {
    try {
      final excelFiles = await _excelHelper.getExcelFiles(); // Получаем файлы
      setState(() {
        files = excelFiles; // Обновляем состояние
      });
    } catch (e) {
      print('Error loading Excel files: $e');
    }
  }

  Future<void> _clearFiles() async {
    try {
      for (final filePath in files) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete(); // Удаление файла
        }
      }
      setState(() {
        files.clear(); // Очистка списка файлов
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Все файлы успешно удалены')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении файлов: $e')),
      );
      print('Ошибка при удалении файлов: $e');
    }
  }

  void _openScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScannerPage(),
      ),
    ).then((_) => _loadExcelFiles()); // Обновляем список файлов при возврате
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Сканнер',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            tooltip: 'Очистить файлы',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Подтверждение'),
                    content: const Text('Вы уверены, что хотите удалить все файлы?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Отмена'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Удалить'),
                      ),
                    ],
                  );
                },
              );
              if (confirm == true) {
                await _clearFiles();
              }
            },
          ),
        ],
      ),
      body: files.isEmpty
          ? const Center(child: Text('Нет доступных файлов'))
          : ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          final fileName = files[index].split('/').last; // Получаем имя файла
          return ListTile(
            leading: const Icon(Icons.insert_drive_file),
            title: Text(fileName),
            trailing: IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Поделиться',
              onPressed: () {
                try {
                  Share.shareXFiles([XFile(files[index])]); // Поделиться файлом
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка при отправке: $e')),
                  );
                  print('Ошибка: $e');
                }
              },
            ),
            onTap: () async {
              try {
                // Открытие файла с помощью open_file
                final result = await OpenFile.open(files[index]);
                if (result.type != ResultType.done) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Не удалось открыть файл: ${result.message}')),
                  );
                  debugPrint(result.message);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: $e')),
                );
                debugPrint('Ошибка: $e');
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openScanner(context),
        tooltip: 'Открыть сканнер',
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}

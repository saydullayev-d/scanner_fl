import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scanner/services/excel_helper.dart';
import 'package:scanner/view/scanner_page.dart';
import 'package:open_file/open_file.dart';

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
            icon: const Icon(Icons.qr_code, color: Colors.white),
            tooltip: 'Открыть сканнер',
            onPressed: () => _openScanner(context),
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
    );
  }
}

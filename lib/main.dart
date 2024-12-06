import 'package:flutter/material.dart';

import 'package:scanner/view/scanner_page.dart';

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

class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  void _openScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScannerPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Пример данных для списка
    final List<String> items = List<String>.generate(20, (index) => 'Элемент ${index + 1}');

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
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.document_scanner),
            title: Text(items[index]),
            onTap: () {
              // Действие при нажатии на элемент
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Вы выбрали: ${items[index]}')),
              );
            },
          );
        },
      ),
    );
  }
}

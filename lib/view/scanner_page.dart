import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:another_flushbar/flushbar.dart';
import 'dart:async';
import 'dart:io';
import 'package:excel/excel.dart';

import 'package:scanner/services/excel_helper.dart'; // Подключение ExcelHelper

class CameraScannerPage extends StatefulWidget {
  @override
  State<CameraScannerPage> createState() => _CameraScannerPageState();
}

class _CameraScannerPageState extends State<CameraScannerPage> {
  final MobileScannerController controller = MobileScannerController();
  bool isScanningPaused = false; // Флаг для паузы после сканирования
  late ExcelHelper excelHelper;

  @override
  void initState() {
    super.initState();
    // Инициализация ExcelHelper с указанием пути к файлу
    excelHelper = ExcelHelper(filePath: 'scanned_data.xlsx');
    _initializeExcelFile();
  }

  Future<void> _initializeExcelFile() async {
    await excelHelper.createExcelFile(); // Убедиться, что файл существует
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Сканер"),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Камера с функцией сканирования
          MobileScanner(
            controller: controller,
            onDetect: (capture) async {
              if (isScanningPaused) return; // Игнорировать новые события
              isScanningPaused = true; // Установить флаг паузы
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  await _handleScannedData(barcode.rawValue!);
                } else {
                  _showScanErrorNotification(context);
                }
              }
              await Future.delayed(const Duration(seconds: 4)); // Задержка 4 секунды
              isScanningPaused = false; // Сбросить флаг паузы
            },
          ),
          // Разметка границ сканера с затемнением
          Center(
            child: CustomPaint(
              size: MediaQuery.of(context).size,
              painter: ScannerOverlayPainter(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 4.0,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () {
                print("pressed");
              },
              icon: const Icon(
                Icons.check_circle_outline_rounded,
                size: 50,
                color: Color(0xFF334050),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Обработка отсканированных данных
  Future<void> _handleScannedData(String scannedData) async {
    if (await excelHelper.isDataUnique(scannedData)) {
      await excelHelper.addData(scannedData);
      _showScanSuccessNotification(context, "Код добавлен: $scannedData");
    } else {
      _showScanSuccessNotification(context, "Код уже существует: $scannedData");
    }
  }

  // Уведомление об успешном сканировании
  void _showScanSuccessNotification(BuildContext context, String message) {
    Flushbar(
      message: message,
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.green,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      flushbarPosition: FlushbarPosition.BOTTOM,
      icon: const Icon(
        Icons.check_circle,
        color: Colors.white,
      ),
    ).show(context);
  }

  // Уведомление о проблеме при сканировании
  void _showScanErrorNotification(BuildContext context) {
    Flushbar(
      message: 'Не удалось считать код. Попробуйте снова.',
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.red,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      flushbarPosition: FlushbarPosition.BOTTOM,
      icon: const Icon(
        Icons.error,
        color: Colors.white,
      ),
    ).show(context);
  }
}

// Кастомный рисовальщик для границ и затемнения
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintBackground = Paint()
      ..color = Colors.black26.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final screenRect = Rect.fromLTWH(0, 0, size.width, size.height);

    final double scanBoxSize = 250;
    final double scanBoxLeft = (size.width - scanBoxSize) / 2;
    final double scanBoxTop = (size.height - scanBoxSize) / 2;
    final Rect scanBoxRect =
    Rect.fromLTWH(scanBoxLeft, scanBoxTop, scanBoxSize, scanBoxSize);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(screenRect),
        Path()..addRect(scanBoxRect),
      ),
      paintBackground,
    );

    final paintBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(scanBoxRect, paintBorder);

    final paintCorners = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final double cornerLength = 30;

    // Верхний левый угол
    canvas.drawLine(
        scanBoxRect.topLeft,
        scanBoxRect.topLeft.translate(cornerLength, 0),
        paintCorners);
    canvas.drawLine(
        scanBoxRect.topLeft,
        scanBoxRect.topLeft.translate(0, cornerLength),
        paintCorners);

    // Верхний правый угол
    canvas.drawLine(
        scanBoxRect.topRight,
        scanBoxRect.topRight.translate(-cornerLength, 0),
        paintCorners);
    canvas.drawLine(
        scanBoxRect.topRight,
        scanBoxRect.topRight.translate(0, cornerLength),
        paintCorners);

    // Нижний левый угол
    canvas.drawLine(
        scanBoxRect.bottomLeft,
        scanBoxRect.bottomLeft.translate(cornerLength, 0),
        paintCorners);
    canvas.drawLine(
        scanBoxRect.bottomLeft,
        scanBoxRect.bottomLeft.translate(0, -cornerLength),
        paintCorners);

    // Нижний правый угол
    canvas.drawLine(
        scanBoxRect.bottomRight,
        scanBoxRect.bottomRight.translate(-cornerLength, 0),
        paintCorners);
    canvas.drawLine(
        scanBoxRect.bottomRight,
        scanBoxRect.bottomRight.translate(0, -cornerLength),
        paintCorners);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

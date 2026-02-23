import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;
import 'package:text_recognition_pipeline/native_text_recognition_pipeline.dart';

Future<bool> createSearchablePdf(
  Uint8List imageBytes,
  List<RecognitionResult> items,
) async {
  final prefs = await SharedPreferences.getInstance();
  final showTextOnScan = prefs.getBool('showTextOnScan') ?? false;

  final fontData = await rootBundle.load("assets/fonts/OpenSans-Regular.ttf");
  final ttf = pw.Font.ttf(fontData);

  final pdf = pw.Document();
  final pdfImage = pw.MemoryImage(imageBytes);

  final codec = await ui.instantiateImageCodec(imageBytes);
  final frameInfo = await codec.getNextFrame();
  final imageWidth = frameInfo.image.width.toDouble();
  final imageHeight = frameInfo.image.height.toDouble();

  final validItems = items.where((item) {
    return item.text.trim().isNotEmpty &&
        item.width > 0 &&
        item.height > 0 &&
        !item.x.isNaN &&
        !item.y.isNaN;
  }).toList();

  final List<RecognitionResult> normalizedItems = [];
  List<RecognitionResult> currentLine = [];

  for (var item in validItems) {
    currentLine.add(item);
    
    if (item.isEndOfLine || item == validItems.last) {
      if (currentLine.isNotEmpty) {
        final lineY = currentLine.map((e) => e.y).reduce((a, b) => a < b ? a : b);
        final lineHeight = currentLine.map((e) => e.height).reduce((a, b) => a > b ? a : b);
        
        for (var wordItem in currentLine) {
          normalizedItems.add(
            RecognitionResult(
              text: wordItem.text,
              x: wordItem.x,
              y: lineY,
              width: wordItem.width,
              height: lineHeight,
              isEndOfLine: wordItem.isEndOfLine,
            )
          );
        }
        currentLine.clear();
      }
    }
  }
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(imageWidth, imageHeight),
      margin: pw.EdgeInsets.zero,
      build: (pw.Context context) {
        return pw.Stack(
          children: [
            pw.FullPage(
              ignoreMargins: true,
              child: pw.Image(pdfImage, fit: pw.BoxFit.cover),
            ),
            ...normalizedItems.map((item) {
              return pw.Positioned(
                left: item.x.toDouble(),
                top: item.y.toDouble(),
                child: pw.Container(
                  width: item.width.toDouble(),
                  height: item.height.toDouble(),
                  child: pw.FittedBox(
                    fit: pw.BoxFit.fill, 
                    child: pw.Text(
                      item.text,
                      softWrap: false,
                      style: pw.TextStyle(
                        font: ttf,
                        renderingMode: showTextOnScan ? null : PdfTextRenderingMode.invisible,
                        fontSize: item.height > 0 ? item.height.toDouble() : 1.0,
                        color: PdfColors.red
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    ),
  );
  return writeFile(pdf);
}

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<File> setLocalFileReference(String fileName) async {
  final path = await _localPath;
  return File('$path/$fileName');
}

Future<void> deleteFile(File file) async {
  try {
    if (await file.exists()) {
      await file.delete();
    }
  } catch (e) {
    // Error in getting access to the file.
  }
}

Future<bool> writeFile(pw.Document pdf) async {
  try {
    var file = await setLocalFileReference(
      "scanned_doc_${DateTime.now().millisecondsSinceEpoch}.pdf",
    );
    await file.writeAsBytes(await pdf.save());
    print("File written at $file");
  } catch (e) {
    print('Error in writing file=$e');
    return false;
  }
  return true;
}

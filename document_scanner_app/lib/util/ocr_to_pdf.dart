import 'dart:io';
import 'package:camera/camera.dart';
import 'package:document_scanner_app/model/ocr_item.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

// FIXME: fix the method
Future<bool> createSearchablePdf(XFile imageFile, List<OcrItem> items) async {
  final pdf = pw.Document();

  final imageBytes = await imageFile.readAsBytes();
  final pdfImage = pw.MemoryImage(imageBytes);

  final codec = await ui.instantiateImageCodec(imageBytes);
  final frameInfo = await codec.getNextFrame();
  final imageWidth = frameInfo.image.width.toDouble();
  final imageHeight = frameInfo.image.height.toDouble();

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
            ...items.map((item) {
              final bottomPosition = imageHeight - item.boundingBox.bottom;

              return pw.Positioned(
                left: item.boundingBox.left,
                bottom: bottomPosition,
                child: pw.Container(
                  width: item.boundingBox.width,
                  height: item.boundingBox.height,
                  child: pw.FittedBox(
                    fit: pw.BoxFit.fill,
                    child: pw.Text(
                      item.text,
                      style: pw.TextStyle(
                        color: PdfColors.red,
                        fontSize: item.boundingBox.height,
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

Future<bool> writeFile(pw.Document pdf) async {
  try {
    var file = await setLocalFileReference(
      "scanned_doc_${DateTime.now().millisecondsSinceEpoch}.pdf",
    );
    file.writeAsBytes(await pdf.save());
    print("File written at $file");
  } catch (e) {
    print('Error in writing file=$e');
    return false;
  }
  return true;
}
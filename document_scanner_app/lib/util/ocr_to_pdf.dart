import 'dart:io';
import 'package:camera/camera.dart';
import 'package:document_scanner_app/model/ocr_item.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui' as ui;

// FIXME: fix the method
void createSearchablePdf(XFile imageFile, List<OcrItem> items) async {
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
  writeFile(pdf);
}

void writeFile(pw.Document pdf) async {
      PermissionStatus permissionStatus = await getStoragePermission();
      if (permissionStatus == PermissionStatus.granted) {
        try {
          String? externalStoragePath = await _getDownloadPath();
          if (externalStoragePath != null) {
            externalStoragePath += "/scanned_doc_${DateTime.now().millisecondsSinceEpoch}.pdf";
            File file = File(externalStoragePath);
            await file.writeAsBytes(await pdf.save());
            print("File written at $externalStoragePath");
          }
        } catch (e) {
          print('Error in writing file=$e');
        }
      }
  }

Future<PermissionStatus> getStoragePermission() async {
    var permissionStatus = Platform.isIOS
        ? await Permission.storage.request()
        : await Permission.manageExternalStorage.request();
    if (permissionStatus.isDenied || permissionStatus.isRestricted) {

      permissionStatus = await Permission.storage.request();

      if (permissionStatus.isDenied) {
        await openAppSettings();
      }
    } else if (permissionStatus.isPermanentlyDenied) {
      await openAppSettings();
    }
    return permissionStatus;
  }

  Future<String?> _getDownloadPath() async {
    Directory? directory;
    try {
      if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      }
    } catch (e) {
      print("Cannot get download folder path with error=$e");
    }
    return directory?.path;
}
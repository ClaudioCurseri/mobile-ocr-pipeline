import 'package:camera/camera.dart';
import 'package:document_scanner_app/model/ocr_item.dart';

abstract class TextRecognitionStrategy {
  Future<List<OcrItem>> recognizeText(XFile file);
}
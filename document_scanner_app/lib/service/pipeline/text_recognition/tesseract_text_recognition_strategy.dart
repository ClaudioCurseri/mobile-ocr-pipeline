import 'package:camera/camera.dart';
import 'package:document_scanner_app/model/ocr_item.dart';
import 'package:document_scanner_app/service/pipeline/text_recognition/text_recognition_strategy.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

class TesseractTextRecognitionStrategy implements TextRecognitionStrategy {

  @override
  Future<List<OcrItem>> recognizeText(XFile file) async {
    String text = await FlutterTesseractOcr.extractHocr(file.path, language: "deu");
    return OcrItem.fromHocr(text);
  }
}
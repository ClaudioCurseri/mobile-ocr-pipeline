import 'package:camera/camera.dart';
import 'package:document_scanner_app/service/pipeline/text_recognition/text_recognition_strategy.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

class TesseractTextRecognitionStrategy implements TextRecognitionStrategy {

  @override
  Future<String> recognizeText(XFile file) async {
    var stopwatch = Stopwatch();
    stopwatch.start();
    String text = await FlutterTesseractOcr.extractHocr(file.path);
    stopwatch.stop();
    print("Elapsed time: ${stopwatch.elapsedMilliseconds}");
    return text;
  }
}
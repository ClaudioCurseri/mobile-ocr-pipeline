import 'dart:io';

import 'package:camera/camera.dart';
import 'package:document_scanner_app/model/ocr_item.dart';
import 'package:document_scanner_app/service/pipeline/text_recognition/text_recognition_strategy.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MlkitTextRecognitionStrategy implements TextRecognitionStrategy {

  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<List<OcrItem>> recognizeText(XFile file) async {
    final inputFile = File(file.path);
    final inputImage = InputImage.fromFile(inputFile);

    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    return OcrItem.fromRecognizedText(recognizedText);
  }
}
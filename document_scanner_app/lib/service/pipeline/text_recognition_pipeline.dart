

import 'package:camera/camera.dart';
import 'package:document_scanner_app/service/pipeline/text_recognition/tesseract_text_recognition_strategy.dart';
import 'package:document_scanner_app/service/pipeline/text_recognition/text_recognition_strategy.dart';
import 'package:document_scanner_app/util/ocr_to_pdf.dart';

class TextRecognitionPipeline {

  final TextRecognitionStrategy _textRecognitionStrategy = TesseractTextRecognitionStrategy();

  void scanDocument(XFile file) async {
    // TODO: add missing preproccing and postprocessing steps
    // TODO: use different text recognition strategies
    var ocrPositions = await _textRecognitionStrategy.recognizeText(file);
    createSearchablePdf(file, ocrPositions);

  }
}
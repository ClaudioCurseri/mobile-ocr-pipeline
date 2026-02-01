

import 'package:camera/camera.dart';
import 'package:document_scanner_app/service/pipeline/text_recognition/mlkit_text_recognition_strategy.dart';
import 'package:document_scanner_app/service/pipeline/text_recognition/text_recognition_strategy.dart';
import 'package:document_scanner_app/util/ocr_to_pdf.dart';
import 'package:text_recognition_pipeline/native_text_recognition_pipeline.dart';

class TextRecognitionPipeline {

// final NativeTextRecognitionPipeline textRecognitionPipeline = NativeTextRecognitionPipeline();
final TextRecognitionStrategy textRecognitionStrategy = MlkitTextRecognitionStrategy();

  Future<bool> scanDocument(XFile file) async {
    var scanSuccessful = false;
    try {
    //textRecognitionPipeline.initTesseract();
    //textRecognitionPipeline.setImage(file.path);

    //textRecognitionPipeline.setPreprocessingConfig(config);
    //textRecognitionPipeline.setPostprocessingConfig(config);

    //textRecognitionPipeline.preprocessingStep();
    //textRecognitionPipeline.textRecognitionStep();
    //textRecognitionPipeline.postprocessingStep();

    //final recognitionResult = textRecognitionPipeline.getRecognitionResult();
    final ocrPositions = await textRecognitionStrategy.recognizeText(file);
    scanSuccessful = await createSearchablePdf(file, ocrPositions);
    scanSuccessful = true;
    } on Exception catch (e) {
      print("An error occured while scanning the document: $e");
    }
    return scanSuccessful;
  }
}
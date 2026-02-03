import 'package:camera/camera.dart';
import 'package:document_scanner_app/util/utils.dart';
import 'package:text_recognition_pipeline/native_text_recognition_pipeline.dart';

class TextRecognitionPipeline {
  final NativeTextRecognitionPipeline textRecognitionPipeline =
      NativeTextRecognitionPipeline();

  Future<void> initialize() async {
    await textRecognitionPipeline.initTesseract();
  }

  void setPreprocessingConfig(PreprocessingConfig config) {
    textRecognitionPipeline.setPreprocessingConfig(config);
  }

  void setPostProcessingConfig(PostprocessingConfig config) {
    textRecognitionPipeline.setPostprocessingConfig(config);
  }

  Future<bool> scanDocument(XFile file) async {
    var scanSuccessful = false;
    try {
      textRecognitionPipeline.setImage(file.path);

      await textRecognitionPipeline.preprocessingStep();
      await textRecognitionPipeline.textRecognitionStep();
      await textRecognitionPipeline.postprocessingStep();

      final imageBytes = textRecognitionPipeline.getImage();

      if (imageBytes != null) {
        final recognitionResult = textRecognitionPipeline
            .getRecognitionResult();
        scanSuccessful = await createSearchablePdf(
          imageBytes,
          recognitionResult,
        );
      }
    } on Exception catch (e) {
      print("An error occured while scanning the document: $e");
    }
    return scanSuccessful;
  }

  void done() {
    textRecognitionPipeline.dispose();
  }
}

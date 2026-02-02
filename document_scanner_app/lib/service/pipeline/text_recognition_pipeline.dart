import 'package:camera/camera.dart';
import 'package:document_scanner_app/util/ocr_to_pdf.dart';
import 'package:text_recognition_pipeline/native_text_recognition_pipeline.dart';

class TextRecognitionPipeline {

  final NativeTextRecognitionPipeline textRecognitionPipeline = NativeTextRecognitionPipeline();
  PreprocessingConfig preprocessingConfig = PreprocessingConfig(
    grayscale: true,
    unsharpMasking: true,
    binary: true,
    dewarp: true,
    resize: true
  );
  PostprocessingConfig postprocessingConfig = PostprocessingConfig(
    useTopResultFromDictionary: false,
    useContext: false
  );

  Future<bool> scanDocument(XFile file) async {
    var scanSuccessful = false;
    try {
    await textRecognitionPipeline.initTesseract();
    textRecognitionPipeline.setImage(file.path);

    textRecognitionPipeline.setPreprocessingConfig(preprocessingConfig);
    textRecognitionPipeline.setPostprocessingConfig(postprocessingConfig);

    await textRecognitionPipeline.preprocessingStep();
    await textRecognitionPipeline.textRecognitionStep();
    await textRecognitionPipeline.postprocessingStep();

    final imageBytes = textRecognitionPipeline.getImage();

    if (imageBytes != null) {
      final recognitionResult = textRecognitionPipeline.getRecognitionResult();
      scanSuccessful = await createSearchablePdf(imageBytes, recognitionResult);
      print("yes");
    }
    print("hi");
    } on Exception catch (e) {
      print("An error occured while scanning the document: $e");
    }
    return scanSuccessful;
  }

  void done() {
    textRecognitionPipeline.dispose();
  }
}
import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:scan_local/util/utils.dart';
import 'package:text_recognition_pipeline/native_text_recognition_pipeline.dart';

class TextRecognitionPipeline {
  final NativeTextRecognitionPipeline textRecognitionPipeline =
      NativeTextRecognitionPipeline();
  var unigramDictionariesInitialized = false;
  var bigramDictionariesInitialized = false;

  Future<void> initialize() async {
    await textRecognitionPipeline.initTesseract();
  }

  void setPreprocessingConfig(PreprocessingConfig config) {
    textRecognitionPipeline.setPreprocessingConfig(config);
  }

  void setPostProcessingConfig(PostprocessingConfig config) {
    textRecognitionPipeline.setPostprocessingConfig(config);
  }

  Future<bool> initUnigramDictionaries() async {
    if (unigramDictionariesInitialized) return true;
    final initialized = await textRecognitionPipeline.initUnigramDictionaries();
    unigramDictionariesInitialized = initialized;
    return initialized;
  }

  Future<bool> initBigramDictionaries() async {
    if (bigramDictionariesInitialized) return true;
    final initializedUnigrams = unigramDictionariesInitialized ? true : await textRecognitionPipeline.initUnigramDictionaries();
    final initializedBigrams = await textRecognitionPipeline.initBigramDictionaries();
    bigramDictionariesInitialized = initializedUnigrams && initializedBigrams;
    return bigramDictionariesInitialized;
  }

  Future<bool> scanDocument(XFile file) async {
    final scanDocumentTask = TimelineTask()..start('scanDocument');
    var scanSuccessful = false;
    try {
      await textRecognitionPipeline.setImage(file.path);

      final preTask = TimelineTask()..start('preprocessingStep');
      await textRecognitionPipeline.preprocessingStep();
      preTask.finish();
  
      final ocrTask = TimelineTask()..start('textRecognitionStep');
      await textRecognitionPipeline.textRecognitionStep();
      ocrTask.finish();
  
      final postTask = TimelineTask()..start('postprocessingStep');
      await textRecognitionPipeline.postprocessingStep();
      postTask.finish();

      final imageBytes = await textRecognitionPipeline.getImage();

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
    scanDocumentTask.finish();
    return scanSuccessful;
  }

  void done() {
    textRecognitionPipeline.dispose();
  }
}

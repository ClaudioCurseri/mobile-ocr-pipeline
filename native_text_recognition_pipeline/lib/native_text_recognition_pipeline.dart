import 'generated_bindings.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

class NativeTextRecognitionPipeline {
  late Pointer<TextRecognitionPipeline> textRecognitionPipeline;
  late Pointer<C_PreprocessingConfig> preprocessingConfig;
  late Pointer<C_PostprocessingConfig> postprocessingConfig;


  NativeTextRecognitionPipeline() {
    textRecognitionPipeline = TextRecognition_create();
    preprocessingConfig = calloc<C_PreprocessingConfig>();
    postprocessingConfig = calloc<C_PostprocessingConfig>();
  }

  void dispose() {
    TextRecognition_destroy(textRecognitionPipeline);
    calloc.free(preprocessingConfig);
    calloc.free(postprocessingConfig);
  }

  void setImage(String path) {
    final cPath = path.toNativeUtf8();

    try {
      TextRecognition_setImage(textRecognitionPipeline, cPath.cast());
    } finally {
      calloc.free(cPath);
    }
  }

  void setPreprocessingConfig(PreprocessingConfig config) {
    preprocessingConfig.ref.grayscale = config.grayscale;
    preprocessingConfig.ref.unsharpMasking = config.unsharpMasking;
    preprocessingConfig.ref.binary = config.binary;
    preprocessingConfig.ref.dewarp = config.dewarp;
    preprocessingConfig.ref.resize = config.resize;
  }

  void setPostprocessingConfig(PostprocessingConfig config) {
    postprocessingConfig.ref.useTopResultFromDictionary = config.useTopResultFromDictionary;
    postprocessingConfig.ref.useContext = config.useContext;
  }

  void initTesseract() {
    TextRecognition_initTesseract(textRecognitionPipeline);
  }

  void initUnigramDictionary(String path) {
    final cPath = path.toNativeUtf8();

    try {
      TextRecognition_initUnigramDictionary(textRecognitionPipeline, cPath.cast());
    } finally {
      calloc.free(cPath);
    }
  }

  void initBigramDictionary(String path) {
    final cPath = path.toNativeUtf8();

    try {
      TextRecognition_initBigramDictionary(textRecognitionPipeline, cPath.cast());
    } finally {
      calloc.free(cPath);
    }
  }

  void preprocessingStep() {
    TextRecognition_preprocessingStep(textRecognitionPipeline, preprocessingConfig.ref);
  }

  void textRecognitionStep() {
    TextRecognition_textRecognitionStep(textRecognitionPipeline);
  }

  void postprocessingStep() {
    TextRecognition_postprocessingStep(textRecognitionPipeline, postprocessingConfig.ref);
  }

  List<RecognitionResult> getRecognitionResult() {
    final count = TextRecognition_getResultCount(textRecognitionPipeline);
    final results = <RecognitionResult>[];

    for (var i = 0; i < count; i++) {
      final item = TextRecognition_getResultItem(textRecognitionPipeline, i);

      final word = item.word.cast<Utf8>().toDartString();

      results.add(RecognitionResult(
        text: word,
        x: item.x1,
        y: item.y1,
        width: item.x2 - item.x1,
        height: item.y2 - item.y1,
        isEndOfLine: item.is_eol
      ));
    }
    return results;
  }
}

class PreprocessingConfig {
  final bool grayscale;
  final bool unsharpMasking;
  final bool binary;
  final bool dewarp;
  final bool resize;

  PreprocessingConfig({
    required this.grayscale,
    required this.unsharpMasking,
    required this.binary,
    required this.dewarp,
    required this.resize
  });
}

class PostprocessingConfig {
  final bool useTopResultFromDictionary;
  final bool useContext;

  PostprocessingConfig({
    required this.useTopResultFromDictionary,
    required this.useContext
  });
}

class RecognitionResult {
  final String text;
  final int x;
  final int y;
  final int width;
  final int height;
  final bool isEndOfLine;

  RecognitionResult({
    required this.text,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.isEndOfLine,
  });
}
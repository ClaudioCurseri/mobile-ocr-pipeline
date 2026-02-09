import 'dart:isolate';
import 'dart:typed_data';

import 'generated_bindings.dart';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:ffi/ffi.dart';
import 'package:path_provider/path_provider.dart';

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

  Uint8List? getImage() {
    final buffer = TextRecognition_getImage(textRecognitionPipeline);

    if (buffer.imageData == nullptr || buffer.length == 0) {
      return null;
    }

    try {
      final cList = buffer.imageData.asTypedList(buffer.length);
      return Uint8List.fromList(cList);
    } finally {
      TextRecognition_freeImage(buffer);
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
    postprocessingConfig.ref.useTopResultFromDictionary =
        config.useTopResultFromDictionary;
    postprocessingConfig.ref.useContext = config.useContext;
  }

  Future<void> initTesseract() async {
    final directory = await getApplicationDocumentsDirectory();

    final tessDataFolder = Directory('${directory.path}/tessdata');
    if (!await tessDataFolder.exists()) {
      await tessDataFolder.create(recursive: true);
    }

    final traineddataFiles = ['eng.traineddata', 'lat.traineddata'];

    for (var traineddataFile in traineddataFiles) {
      final filePath = '${tessDataFolder.path}/$traineddataFile';
      final file = File(filePath);

      if (!await file.exists()) {
        final byteData = await rootBundle.load('assets/tessdata/$traineddataFile');
        await file.writeAsBytes(
          byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          ),
        );
      }
    }

    final cPath = tessDataFolder.path.toNativeUtf8();

    try {
      TextRecognition_initTesseract(textRecognitionPipeline, cPath.cast());
    } finally {
      calloc.free(cPath);
    }
  }

  Future<bool> initUnigramDictionaries() async {
    var success = false;

    final directory = await getApplicationDocumentsDirectory();

    final dictionaryFolder = Directory('${directory.path}/unigram');
    if (!await dictionaryFolder.exists()) {
      await dictionaryFolder.create(recursive: true);
    }

    final unigramDictionaries = ['frequency_dictionary_en_82_765.txt'];

    for (var dictionary in unigramDictionaries) {
      final filePath = '${directory.path}/unigram/$dictionary';
      final file = File(filePath);
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      if (!await file.exists()) {
        final byteData = await rootBundle.load('assets/unigram/$dictionary');
        await file.writeAsBytes(
          byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          ),
        );
      }
      final cPath = filePath.toNativeUtf8();
      try {
        success =
            await Isolate.run<int>(() {
              return TextRecognition_initUnigramDictionary(
                textRecognitionPipeline,
                cPath.cast(),
              );
            }) ==
            0;
      } catch (e) {
        print(e);
      } finally {
        calloc.free(cPath);
      }
    }
    return success;
  }

  Future<bool> initBigramDictionaries() async {
    var success = false;

    final directory = await getApplicationDocumentsDirectory();

    final dictionaryFolder = Directory('${directory.path}/bigram');
    if (!await dictionaryFolder.exists()) {
      await dictionaryFolder.create(recursive: true);
    }

    final bigramDictionaries = ['frequency_bigramdictionary_en_243_342.txt'];

    for (var dictionary in bigramDictionaries) {
      final filePath = '${directory.path}/bigram/$dictionary';
      final file = File(filePath);
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      if (!await file.exists()) {
        final byteData = await rootBundle.load('assets/bigram/$dictionary');
        await file.writeAsBytes(
          byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          ),
        );
      }
      final cPath = filePath.toNativeUtf8();
      try {
        success =
            await Isolate.run<int>(() {
              return TextRecognition_initBigramDictionary(
                textRecognitionPipeline,
                cPath.cast(),
              );
            }) ==
            0;
      } finally {
        calloc.free(cPath);
      }
    }
    return success;
  }

  Future<void> preprocessingStep() async {
    final ptr = textRecognitionPipeline;
    final config = preprocessingConfig.ref;
    await Isolate.run(() {
      TextRecognition_preprocessingStep(ptr, config);
    });
  }

  Future<void> textRecognitionStep() async {
    final ptr = textRecognitionPipeline;
    await Isolate.run(() {
      print("Starting Tesseract on Background Isolate...");
      TextRecognition_textRecognitionStep(ptr);
      print("Tesseract Finished!");
    });
  }

  Future<void> postprocessingStep() async {
    final ptr = textRecognitionPipeline;
    final config = postprocessingConfig.ref;
    await Isolate.run(() {
      TextRecognition_postprocessingStep(ptr, config);
    });
  }

  List<RecognitionResult> getRecognitionResult() {
    final count = TextRecognition_getResultCount(textRecognitionPipeline);
    final results = <RecognitionResult>[];

    for (var i = 0; i < count; i++) {
      final item = TextRecognition_getResultItem(textRecognitionPipeline, i);

      final word = item.word.cast<Utf8>().toDartString();

      results.add(
        RecognitionResult(
          text: word,
          x: item.x1,
          y: item.y1,
          width: item.x2 - item.x1,
          height: item.y2 - item.y1,
          isEndOfLine: item.is_eol,
        ),
      );
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
    required this.resize,
  });
}

class PostprocessingConfig {
  final bool useTopResultFromDictionary;
  final bool useContext;

  PostprocessingConfig({
    required this.useTopResultFromDictionary,
    required this.useContext,
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

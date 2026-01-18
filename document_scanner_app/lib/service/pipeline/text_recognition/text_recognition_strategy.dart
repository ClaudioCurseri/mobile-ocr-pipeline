import 'package:camera/camera.dart';

abstract class TextRecognitionStrategy {
  Future<String> recognizeText(XFile file);
}
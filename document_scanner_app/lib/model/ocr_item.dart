import 'dart:ui';
import 'package:html/parser.dart' as html_parser;

// class that represents a single OCR'd text instance
class OcrItem {
  final String text;
  final Rect boundingBox;
  final int confidence;

  const OcrItem({required this.text, required this.boundingBox, required this.confidence});

  // creates a list of OcrItems that stem from a string in the hOCR format.
  static List<OcrItem> fromHocr(String hocr) {
    final document = html_parser.parse(hocr);
    final List<OcrItem> items = [];

    final elements = document.getElementsByClassName('ocrx_word');

    final bboxPattern = RegExp(r'bbox\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)');
    final confPattern = RegExp(r'x_wconf\s+(\d+)');

    for (var element in elements) {
      final title = element.attributes['title'] ?? '';
      final bboxMatch = bboxPattern.firstMatch(title);
      final confMatch = confPattern.firstMatch(title);

      if (bboxMatch != null) {
        final left = double.parse(bboxMatch.group(1)!);
        final top = double.parse(bboxMatch.group(2)!);
        final right = double.parse(bboxMatch.group(3)!);
        final bottom = double.parse(bboxMatch.group(4)!);

        final confidence = confMatch != null ? int.parse(confMatch.group(1)!) : 0;

        items.add(OcrItem(
          text: element.text.trim(),
          boundingBox: Rect.fromLTRB(left, top, right, bottom),
          confidence: confidence
        ));
      }
    }

    return items;
  }
}
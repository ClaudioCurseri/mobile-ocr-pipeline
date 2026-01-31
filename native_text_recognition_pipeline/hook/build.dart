import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:logging/logging.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final packageName = input.packageName;
    const homebrewPrefix = '/opt/homebrew';
    final symspellPrefix = input.packageRoot
        .resolve('src/$packageName/third_party/yams-symspell/include') 
        .toFilePath();
    final cbuilder = CBuilder.library(
      name: packageName,
      assetName: '${packageName}_bindings_generated.dart',
      sources: [
        'src/$packageName/$packageName.cpp',
      ],
      flags: [
        '-x', 'c++',
        '-std=c++20',
        '-lc++',
        '-I$homebrewPrefix/include', 
        '-I$homebrewPrefix/include/opencv4',
        '-I$symspellPrefix',
        '-L$homebrewPrefix/lib',
        '-ltesseract',
        '-lleptonica',
        '-lopencv_core',
        '-lopencv_imgproc',
        '-lopencv_imgcodecs'
      ],
    );
    await cbuilder.run(
      input: input,
      output: output,
      logger: Logger('')
        ..level = .ALL
        ..onRecord.listen((record) => print(record.message)),
    );
  });
}

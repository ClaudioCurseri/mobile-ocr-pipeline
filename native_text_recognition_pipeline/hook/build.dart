import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:logging/logging.dart';
import 'package:hooks/hooks.dart';
import 'package:code_assets/code_assets.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final packageName = input.packageName;

    if (input.config.code.targetOS == OS.android) {

      final androidThirdParty = input.packageRoot
          .resolve('src/$packageName/third_party/android/');

      final includeDir = androidThirdParty.resolve('include/');
      final opencvIncludeDir = androidThirdParty.resolve('include/opencv4/');
      final libDir = androidThirdParty.resolve('lib/arm64-v8a/');

      final cbuilder = CBuilder.library(
        name: packageName,
        assetName: 'generated_bindings.dart',
        sources: [
          'src/$packageName/text_recognition_pipeline.cpp'
        ],
        flags: [
          '-x', 'c++', '-std=c++20',

          '-I${includeDir.toFilePath()}',
          '-I${opencvIncludeDir.toFilePath()}', 
          '-I${input.packageRoot.resolve('src/$packageName/third_party/yams-symspell/include').toFilePath()}',
          
          '-L${libDir.toFilePath()}',
          '-ltesseract', 
          '-lleptonica', 
          '-lopencv_java4',
        ],
      );
      
      await cbuilder.run(
        input: input,
        output: output,
        logger: Logger('')..level = Level.ALL..onRecord.listen((r) => print(r.message)),
      );

      final libsToBundle = [
        'libopencv_java4.so',
        'libtesseract.so',
        'libleptonica.so',
        'libc++_shared.so', 
      ];

      for (final libName in libsToBundle) {
        final libUri = androidThirdParty.resolve('lib/arm64-v8a/$libName');
        
        output.assets.code.add(
          CodeAsset(
            package: packageName,
            name: libName, 
            linkMode: DynamicLoadingBundled(), 
            file: libUri, 
          ),
        );
      }
    } else {
      print("Skipping Android build logic for target OS: ${input.config.code.targetOS}");
    }
  });
}
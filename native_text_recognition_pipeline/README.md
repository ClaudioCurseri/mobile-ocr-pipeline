# Native Text Recognition Pipeline

A Dart FFI Project that binds a C++ implementation of an OCR Pipeline to native code.

## Project structure

This project uses the following structure:

* `src`: Contains the native source code. The code can be executed on your system using the CMakeLists.txt to run a main.cpp file that will run the pipeline against a test dataset.

* `lib`: Contains the Dart code that defines the API of the plugin, and which
  calls into the native code using `dart:ffi`.

* `bin`: Contains the `build.dart` that performs the external native builds.

* `hook`: Contains a `build.dart` file.

* `tesseract-build`: Contains shell scripts to compile Tesseract and Leptonica from source. See the README inside for more details.

## Building and bundling native code

`build.dart` does the building of native components.

Bundling is done by Flutter based on the output from `build.dart`.

## Binding to native code

To use the native code, bindings in Dart are needed.
Regenerate the bindings by running `dart run ffigen --config ffigen.yaml`.
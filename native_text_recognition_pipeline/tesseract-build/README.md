# Using Tesseract, Leponica and OpenCV in this package

This file explains how to compile Tesseract and Leptonica from source in order to use them as well as OpenCV in the `native_text_recognition_pipeline` package.

## Android

- Goal: Acquire all required Shared Libraries (.so) and Headers (.h/.hpp).
- Make sure that all the required programs are installed on your system in order to follow the next steps.

> Important: The libraries have to be build for a certain target architecture. Currently the libraries a built for arm64-v8a, armeabi-v7a and x86_64. In the sections below, replace `TARGET_ARCH` with the respective architecture.

### 1. Building Tesseract and Leptonica From Source

Follow these steps to compile Tesseract and Leptonica from source using the provided `build_android.sh` script.

#### 1.1 Clone The Git Repositories

```bash
git clone --depth 1 --branch 5.3.4 git@github.com:tesseract-ocr/tesseract.git

git clone --depth 1 git@github.com:DanBloomberg/leptonica.git
```

#### 1.2 Provide The Android NDK Path

In the `build_tesseract.sh`, replace this line with the path to the installed NDK on your system. The NDK can be installed in Android Studio.

```bash
export ANDROID_NDK_HOME=/path/to/ndk/<version>  # <--- Replace with path to installed ndk
```

#### 1.3 Edit CMakeLists.txt

In `tesseract/CmakeLists.txt` replace:

```cmake
if(ANDROID)
  add_definitions(-DANDROID)
  find_package(CpuFeaturesNdkCompat REQUIRED)
  target_include_directories(
    libtesseract
    PRIVATE "${CpuFeaturesNdkCompat_DIR}/../../../include/ndk_compat")
  target_link_libraries(libtesseract PRIVATE CpuFeatures::ndk_compat)
endif()
```

with:

```cmake
if(ANDROID)
  add_definitions(-DANDROID)
  target_link_libraries(libtesseract)
endif()
```

#### 1.4 Run The Script

```bash
./build_android.sh
```

### 2. Integrate Tesseract And Leptonica

Inside the `install` directory, the build script will produce two directories with files that are relevant:

- include/
   - contains all headers from Tesseract and Leptonica
- lib/
   - contains the shared libraries (.so files)

The directories containing the headers have to be placed in this location:

- native_text_recognition_pipeline/src/text_recognition_pipeline/third_party/android/include/

The shared libraries have to be placed in this location:

- native_text_recognition_pipeline/src/text_recognition_pipeline/third_party/android/lib/TARGET_ARCH/

> Important: A copy from the file `libc++_shared.so` also has to be placed in this location. The file can be found somewhere in the NDK folder on your system.



### 3. Integrate OpenCV

Download the Android sdk. Then, place the headers in `opencv2/` in this location:

- native_text_recognition_pipeline/src/text_recognition_pipeline/third_party/android/include/opencv4/

The shared library has to be placed in this location:

- native_text_recognition_pipeline/src/text_recognition_pipeline/third_party/android/lib/TARGET_ARCH/

## iOS

- Goal: Acquire all required static libraries (.a) and Headers (.h/.hpp) from the XCFrameworks (.framework/.xcframework).
- Make sure that all the required programs are installed on your system in order to follow the next steps.

### 1. Building Tesseract and Leptonica From Source

Follow these steps to compile Tesseract and Leptonica from source using the provided `build_ios.sh` script. Make sure that Xcode and CMake are installed.

#### 1.1 Clone The Git Repositories

```bash
git clone --depth 1 --branch 5.3.4 git@github.com:tesseract-ocr/tesseract.git

git clone --depth 1 git@github.com:DanBloomberg/leptonica.git
```

#### 1.2 Run The Script

```bash
./build_ios.sh
```

### 2. Integrate Tesseract And Leptonica

Inside the `install_ios/xcframeworks/` directory, the build script will produce a directories with files that are relevant:

- leptonica.xcframework/
   - Created XCFramework for Leptonica
- tesseract.xcframework/
   - Created XCFramework for Tesseract

Place the XCFrameworks in this location:

- native_text_recognition_pipeline/src/text_recognition_pipeline/third_party/iOS/xcframeworks/

### 3. Integrate OpenCV

Download the iOS sdk. Then, place `opencv2.framework` in this location:

- native_text_recognition_pipeline/src/text_recognition_pipeline/third_party/iOS/xcframeworks/

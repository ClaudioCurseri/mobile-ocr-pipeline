#!/bin/bash
set -e

ROOT_DIR=$(pwd)
INSTALL_DIR=$ROOT_DIR/install_ios
IOS_PLATFORM_MIN_VERSION="12.0"

rm -rf $INSTALL_DIR
mkdir -p $INSTALL_DIR

build_lib_ios() {
    LIB_NAME=$1
    CMAKE_ARGS_EXTRA=$2
    
    BUILD_DIR=$ROOT_DIR/$LIB_NAME/build-iphoneos-arm64
    OUTPUT_DIR=$INSTALL_DIR/$LIB_NAME

    echo ">>> Building $LIB_NAME for iOS Device (arm64)..."

    rm -rf $BUILD_DIR
    mkdir -p $BUILD_DIR
    cd $BUILD_DIR

    cmake -G "Xcode" \
        -DCMAKE_SYSTEM_NAME=iOS \
        -DCMAKE_OSX_SYSROOT=iphoneos \
        -DCMAKE_OSX_ARCHITECTURES="arm64" \
        -DCMAKE_SYSTEM_PROCESSOR="arm64" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=$IOS_PLATFORM_MIN_VERSION \
        -DCMAKE_INSTALL_PREFIX=$OUTPUT_DIR \
        -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO \
        -DCMAKE_XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER="com.example.$LIB_NAME" \
        -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY="" \
        -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED=NO \
        -DBUILD_SHARED_LIBS=OFF \
        $CMAKE_ARGS_EXTRA \
        ..

    cmake --build . --config Release --target install
}

# ==========================================
# 1. Build Leptonica
# ==========================================
LEP_OPTS="-DENABLE_GIF=OFF -DENABLE_JPEG=OFF -DENABLE_PNG=OFF -DENABLE_TIFF=OFF -DENABLE_WEBP=OFF -DENABLE_ZLIB=OFF -DBUILD_PROG=OFF -DSW_BUILD=OFF"

build_lib_ios "leptonica" "$LEP_OPTS"

# ==========================================
# 2. Build Tesseract
# ==========================================
TESS_OPTS="-DBUILD_TRAINING_TOOLS=OFF -DGRAPHICS_DISABLED=ON -DOPENMP_BUILD=OFF -DDISABLE_CURL=ON -DDISABLE_ARCHIVE=ON -DLEPT_TIFF_RESULT=1 -DLEPT_OPENJPEG_RESULT=1 -DDISABLED_LEGACY_ENGINE=ON -DENABLE_LTO=OFF"

build_lib_ios "tesseract" \
    "$TESS_OPTS -DLeptonica_DIR=$INSTALL_DIR/leptonica/lib/cmake/leptonica"


# ==========================================
# 3. Create XCFrameworks
# ==========================================
echo ">>> Creating XCFrameworks..."
mkdir -p $INSTALL_DIR/xcframeworks

create_simple_xcframework() {
    LIB_NAME=$1
    
    xcodebuild -create-xcframework \
        -library "$INSTALL_DIR/$LIB_NAME/lib/lib$LIB_NAME.a" \
        -headers "$INSTALL_DIR/$LIB_NAME/include" \
        -output "$INSTALL_DIR/xcframeworks/$LIB_NAME.xcframework"
}

create_simple_xcframework "leptonica"
create_simple_xcframework "tesseract"

echo "Build Complete. Files are in $INSTALL_DIR"
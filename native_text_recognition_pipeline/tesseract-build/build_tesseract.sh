#!/bin/bash

# --- CONFIGURATION ---
export ANDROID_NDK_HOME=/path/to/ndk/<version>  # <--- Replace with path to installed ndk
export TOOLCHAIN=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake
export ANDROID_PLATFORM=android-21
export BUILD_TYPE=Release

ABIS=("arm64-v8a") 
ROOT_DIR=$(pwd)
INSTALL_DIR=$ROOT_DIR/install

NDK_TOOLCHAIN_BIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin"
STRIP_TOOL="$NDK_TOOLCHAIN_BIN/llvm-strip"

for ABI in "${ABIS[@]}"; do
    echo ">>> Building for $ABI"
    
    # ==========================================
    # 1. Build Leptonica
    # ==========================================
    rm -rf $ROOT_DIR/leptonica/build-$ABI 
    mkdir -p $ROOT_DIR/leptonica/build-$ABI
    cd $ROOT_DIR/leptonica/build-$ABI
    
    cmake -G "Unix Makefiles" \
        -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN \
        -DANDROID_ABI=$ABI \
        -DANDROID_PLATFORM=$ANDROID_PLATFORM \
        -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
        -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/$ABI \
        -DBUILD_SHARED_LIBS=ON \
        -DENABLE_GIF=OFF \
        -DENABLE_JPEG=OFF \
        -DENABLE_PNG=OFF \
        -DENABLE_TIFF=OFF \
        -DENABLE_WEBP=OFF \
        -DENABLE_ZLIB=OFF \
        -DBUILD_PROG=OFF \
        -DSW_BUILD=OFF \
        ..
        
    make -j4
    make install

    # ==========================================
    # 2. Build Tesseract
    # ==========================================
    rm -rf $ROOT_DIR/tesseract/build-$ABI
    mkdir -p $ROOT_DIR/tesseract/build-$ABI
    cd $ROOT_DIR/tesseract/build-$ABI

    cmake -G "Unix Makefiles" \
        -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN \
        -DANDROID_ABI=$ABI \
        -DANDROID_PLATFORM=$ANDROID_PLATFORM \
        -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
        -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/$ABI \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_TRAINING_TOOLS=OFF \
        -DGRAPHICS_DISABLED=ON \
        -DOPENMP_BUILD=OFF \
        -DDISABLE_CURL=ON \
        -DDISABLE_ARCHIVE=ON \
        -DLEPT_TIFF_RESULT=1 \
        -DLEPT_OPENJPEG_RESULT=1 \
        -DLeptonica_DIR=$INSTALL_DIR/$ABI/lib/cmake/leptonica \
        -DCMAKE_ANDROID_STL_TYPE=c++_shared \
        -DDISABLED_LEGACY_ENGINE=ON \
        -DENABLE_LTO=ON \
        ..

    make -j4
    make install

    # ==========================================
    # 3. STRIP DEBUG SYMBOLS
    # ==========================================
    echo ">>> Stripping symbols to reduce size..."
    $STRIP_TOOL --strip-unneeded "$INSTALL_DIR/$ABI/lib/libtesseract.so"
    $STRIP_TOOL --strip-unneeded "$INSTALL_DIR/$ABI/lib/libleptonica.so"
    
    cd $ROOT_DIR
done

echo "Build Complete. Files are in $INSTALL_DIR"
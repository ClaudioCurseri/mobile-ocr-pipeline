cmake_minimum_required(VERSION 3.31)
project(text_recognition_pipeline)

set(CMAKE_CXX_STANDARD 20)

add_subdirectory(${CMAKE_SOURCE_DIR}/third_party/yams-symspell)

find_package(OpenCV REQUIRED)
find_package(PkgConfig REQUIRED)
pkg_check_modules(Tesseract REQUIRED tesseract IMPORTED_TARGET)

add_executable(text_recognition_pipeline main.cpp
        TextRecognition.cpp
        TextRecognition.h
        Preprocessing.cpp
        Preprocessing.h
        Postprocessing.cpp
        Postprocessing.h)

target_link_libraries(${PROJECT_NAME} ${OpenCV_LIBS} PkgConfig::Tesseract yams-symspell)
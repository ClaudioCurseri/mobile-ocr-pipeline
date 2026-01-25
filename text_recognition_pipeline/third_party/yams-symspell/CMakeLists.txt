cmake_minimum_required(VERSION 3.10)
project(yams-symspell)

file(GLOB_RECURSE LIB_SOURCES
        "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp"
        "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp"
)

add_library(yams-symspell STATIC ${LIB_SOURCES})

target_include_directories(yams-symspell PUBLIC
        "${CMAKE_CURRENT_SOURCE_DIR}/include"
)
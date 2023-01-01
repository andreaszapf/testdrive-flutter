cmake_minimum_required(VERSION 3.10.2...3.15)

add_library(findaudiofiles STATIC
  include/find_audiofiles/find_audiofiles.h
  src/find_audiofiles.cpp)

target_include_directories(findaudiofiles PUBLIC include)

target_compile_features(findaudiofiles PRIVATE cxx_std_17)

target_link_libraries(findaudiofiles PRIVATE readerwriterqueue)

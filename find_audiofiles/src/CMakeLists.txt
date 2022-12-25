# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(find_audiofiles_library VERSION 0.0.1 LANGUAGES C)

add_library(find_audiofiles SHARED
  "find_audiofiles.c"
)

set_target_properties(find_audiofiles PROPERTIES
  PUBLIC_HEADER find_audiofiles.h
  OUTPUT_NAME "find_audiofiles"
)

target_compile_definitions(find_audiofiles PUBLIC DART_SHARED_LIB)

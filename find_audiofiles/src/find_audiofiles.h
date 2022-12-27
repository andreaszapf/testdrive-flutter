#include "find_audiofiles/find_audiofiles.h"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#if _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

FFI_PLUGIN_EXPORT intptr_t faf_first_wrapper(
  const char* path, faf_context** context, faf_filesystem_entry** entry);

FFI_PLUGIN_EXPORT intptr_t faf_next_wrapper(
  faf_context* context, faf_filesystem_entry** entry);

FFI_PLUGIN_EXPORT void faf_close_wrapper(faf_context* context);

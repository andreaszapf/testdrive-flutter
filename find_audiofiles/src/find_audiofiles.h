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

#if defined(__cplusplus)
extern "C" {
#endif

FFI_PLUGIN_EXPORT intptr_t faf_first_wrapper(
  const char* path, faf_context** context, faf_filesystem_entry** entry);

FFI_PLUGIN_EXPORT intptr_t faf_next_wrapper(
  faf_context* context, faf_filesystem_entry** entry);

FFI_PLUGIN_EXPORT void faf_close_wrapper(faf_context* context);

typedef struct audiofile_scanner audiofile_scanner;
typedef void (*audiofile_scanner_callback)(faf_filesystem_entry* entry);

FFI_PLUGIN_EXPORT audiofile_scanner* make_audiofile_scanner(
	const char* directory, int* error_code);

FFI_PLUGIN_EXPORT int audiofile_scanner_scan(
  audiofile_scanner* scanner, audiofile_scanner_callback callback);

FFI_PLUGIN_EXPORT int audiofile_scanner_cancel_scan(audiofile_scanner* scanner);

FFI_PLUGIN_EXPORT void audiofile_scanner_close(audiofile_scanner* scanner);

#if defined(__cplusplus)
}
#endif

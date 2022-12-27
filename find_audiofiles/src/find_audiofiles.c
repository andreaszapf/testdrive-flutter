#include "find_audiofiles.h"

#include "find_audiofiles/find_audiofiles.h"

FFI_PLUGIN_EXPORT intptr_t faf_first_wrapper(
  const char* path, faf_context** context, faf_filesystem_entry** entry)
{
  return faf_first(path, context, entry);
}

FFI_PLUGIN_EXPORT intptr_t faf_next_wrapper(
  faf_context* context, faf_filesystem_entry** entry)
{
  return faf_next(context, entry);
}

FFI_PLUGIN_EXPORT void faf_close_wrapper(faf_context* context)
{
  faf_close(context);
}

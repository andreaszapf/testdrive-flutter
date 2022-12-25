#pragma once

#ifdef __cplusplus
class faf_context;
#else
typedef struct faf_context faf_context;
#endif

typedef struct faf_filesystem_entry faf_filesystem_entry;
struct faf_filesystem_entry
{
  const char* path;
};

#if defined(__cplusplus)
extern "C" {
#endif

int faf_first(const char* path, faf_context** context, faf_filesystem_entry** entry);

int faf_next(faf_context* context, faf_filesystem_entry** entry);

void faf_close(faf_context* context);

#if defined(__cplusplus)
}
#endif

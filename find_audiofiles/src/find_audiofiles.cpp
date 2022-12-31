#include "find_audiofiles.h"

#include "find_audiofiles/audiofile_scanner.hpp"
#include "find_audiofiles/find_audiofiles.h"

#include <memory>

namespace fs = std::filesystem;

intptr_t faf_first_wrapper(const char* path,
                           faf_context** context,
                           faf_filesystem_entry** entry)
{
  return faf_first(path, context, entry);
}

intptr_t faf_next_wrapper(faf_context* context, faf_filesystem_entry** entry)
{
  return faf_next(context, entry);
}

void faf_close_wrapper(faf_context* context)
{
  faf_close(context);
}

struct audiofile_scanner : public find_audiofiles::faf_audiofile_scanner
{
  using find_audiofiles::faf_audiofile_scanner::faf_audiofile_scanner;
};

audiofile_scanner* make_audiofile_scanner(const char* directory, int* error_code)
{
  const auto set_out_error = [&](const std::error_code error) {
    if (error_code)
    {
      *error_code = error.value();
    }
  };

  set_out_error(std::error_code());

  if (!directory)
  {
    set_out_error(std::make_error_code(std::errc::invalid_argument));
    return {};
  }

  auto scanner = std::make_unique<audiofile_scanner>(fs::u8path(directory));
  return scanner.release();
}

int audiofile_scanner_scan(
  audiofile_scanner* scanner, audiofile_scanner_callback callback)
{
  if (!scanner)
  {
    return std::make_error_code(std::errc::invalid_argument).value();
  }

  const auto error = scanner->scan(
    [&](const find_audiofiles::faf_audiofile& audiofile) {
      auto path_storage = audiofile.path.u8string();
      auto entry = faf_filesystem_entry{path_storage.c_str()};
      callback(&entry);
    });

  return error.value();
}

int audiofile_scanner_cancel_scan(audiofile_scanner* scanner)
{
  if (!scanner)
  {
    return std::make_error_code(std::errc::invalid_argument).value();
  }

  scanner->cancel_scan();
  return 0;
}

void audiofile_scanner_close(audiofile_scanner* scanner)
{
  delete scanner;
}

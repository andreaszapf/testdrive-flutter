#pragma once

#include <filesystem>
#include <functional>
#include <memory>
#include <system_error>

namespace find_audiofiles
{

struct faf_audiofile
{
  std::filesystem::path path;
};

class faf_audiofile_scanner
{
public:
  using scan_callback = std::function<void (const faf_audiofile&)>;

  explicit faf_audiofile_scanner(const std::filesystem::path& directory);

  ~faf_audiofile_scanner();

  std::error_code scan(const scan_callback& callback);

  // Call to cancel a running scan. Can be called from within the callback or from a 
  // different thread.
  void cancel_scan();

private:
  class impl;

  std::unique_ptr<impl> impl_;
};

} // namespace find_audiofiles

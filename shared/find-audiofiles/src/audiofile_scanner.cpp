#include "find_audiofiles/audiofile_scanner.hpp"

#include "audiofile_iterator.hpp"

#include <atomic>
#include <filesystem>

namespace fs = std::filesystem;

namespace find_audiofiles
{

class faf_audiofile_scanner::impl
{
public:
  explicit impl(const fs::path& directory)
    : directory_{directory}
  {
  }

  std::error_code scan(const faf_audiofile_scanner::scan_callback& callback)
  {
    if (!callback)
    {
      return std::make_error_code(std::errc::invalid_argument);
    }

    if (was_canceled_.load(std::memory_order_relaxed))
    {
      return std::make_error_code(std::errc::operation_canceled);
    }

    std::error_code error;
    auto iterator = audiofile_iterator(directory_, error);
    while (!error && !iterator.at_end())
    {
      if (was_canceled_.load(std::memory_order_relaxed))
      {
        error = std::make_error_code(std::errc::operation_canceled);
        break;
      }

      callback(faf_audiofile{iterator.current().path()});

      if (was_canceled_.load(std::memory_order_relaxed))
      {
        error = std::make_error_code(std::errc::operation_canceled);
        break;
      }

      error = iterator.move_next();
    }

    return error;
  }

  void cancel_scan() { was_canceled_.store(true, std::memory_order_relaxed); }

private:
  fs::path directory_;
  std::atomic<bool> was_canceled_{false};
};

faf_audiofile_scanner::faf_audiofile_scanner(const fs::path& directory)
  : impl_{std::make_unique<impl>(directory)}
{
}

faf_audiofile_scanner::~faf_audiofile_scanner() = default;

std::error_code faf_audiofile_scanner::scan(const scan_callback& callback)
{
  return impl_->scan(callback);
}

void faf_audiofile_scanner::cancel_scan()
{
  return impl_->cancel_scan();
}

} // namespace find_audiofiles

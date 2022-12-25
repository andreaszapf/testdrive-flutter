#include "find_audiofiles/find_audiofiles.h"

#include <algorithm>
#include <array>
#include <cassert>
#include <filesystem>
#include <memory>
#include <optional>
#include <variant>

namespace fs = std::filesystem;

namespace
{
using directory_iterator = fs::recursive_directory_iterator;

bool is_audio_file_path(const fs::path& path) noexcept
{
  static const auto audio_file_extensions =
    std::array<fs::path, 6>{{".mp3", ".m4a", ".m4b", ".MP3", ".M4A", ".M4B"}};

  const auto ext = path.extension();
  return !ext.empty()
         && std::any_of(audio_file_extensions.begin(), audio_file_extensions.end(),
                        [&](const auto x) { return x == ext; });
}

class audiofile_iterator
{
public:
  audiofile_iterator(const fs::path& path, std::error_code& error) noexcept
    : directory_iterator_{path, fs::directory_options::skip_permission_denied, error}
  {
    if (error || at_end())
    {
      return;
    }

    if (!error && !at_audiofile(error) && !error)
    {
      error = move_next();
    }
  }

  bool at_end() const noexcept { return directory_iterator_ == end(directory_iterator_); }
  const auto& current() const noexcept { return *directory_iterator_; }

  std::error_code move_next() noexcept
  {
    std::error_code err;
    for (directory_iterator_ = directory_iterator_.increment(err);
         directory_iterator_ != end(directory_iterator_);
         directory_iterator_ = directory_iterator_.increment(err))
    {
      if (at_audiofile(err))
      {
        break;
      }
    }
    return err;
  }

private:
  bool at_audiofile(std::error_code& error) const noexcept
  {
    return !at_end() && directory_iterator_->is_regular_file(error) && !error
           && is_audio_file_path(directory_iterator_->path());
  }

  directory_iterator directory_iterator_;
};

class filesystem_entry_wrapper
{
public:
  faf_filesystem_entry* entry() noexcept
  {
    return entry_.has_value() ? &(*entry_) : nullptr;
  }

  void update(const audiofile_iterator& iterator) noexcept
  {
    if (iterator.at_end())
    {
      entry_ = std::nullopt;
      entry_path_storage_.clear();
    }
    else
    {
      entry_path_storage_ = iterator.current().path().u8string();
      entry_ = faf_filesystem_entry{entry_path_storage_.c_str()};
    }
  }

private:
  std::optional<faf_filesystem_entry> entry_;
  std::string entry_path_storage_;
};

} // namespace

class faf_context
{
public:
  faf_context(fs::path path, std::error_code& error) noexcept
    : iterator_{path, error}
  {
    entry_wrapper_.update(iterator_);
  }

  faf_filesystem_entry* entry() noexcept { return entry_wrapper_.entry(); }

  std::error_code move_next() noexcept
  {
    const auto error = iterator_.move_next();
    entry_wrapper_.update(iterator_);
    return error;
  }

private:
  audiofile_iterator iterator_;
  filesystem_entry_wrapper entry_wrapper_;
};

int faf_first(const char* path, faf_context** context, faf_filesystem_entry** entry)
{
  if (context)
  {
    *context = nullptr;
  }

  if (entry)
  {
    *entry = nullptr;
  }

  if (path == nullptr || context == nullptr || entry == nullptr)
  {
    return std::make_error_code(std::errc::invalid_argument).value();
  }

  std::error_code error;
  auto new_context = std::make_unique<faf_context>(fs::u8path(path), error);
  if (!error)
  {
    *entry = new_context->entry();
    *context = new_context.release();
  }

  return error.value();
}

int faf_next(faf_context* context, faf_filesystem_entry** entry)
{
  if (entry)
  {
    *entry = nullptr;
  }

  if (context == nullptr || entry == nullptr)
  {
    return std::make_error_code(std::errc::invalid_argument).value();
  }

  const auto error = context->move_next();
  *entry = context->entry();
  return error.value();
}

void faf_close(faf_context* context)
{
  delete context;
}

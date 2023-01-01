#include "find_audiofiles/find_audiofiles.h"

#include <readerwritercircularbuffer.h>

#include <algorithm>
#include <array>
#include <atomic>
#include <filesystem>
#include <memory>
#include <optional>
#include <thread>
#include <variant>

namespace fs = std::filesystem;

namespace
{

constexpr size_t queue_capacity = 1;

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

  void update(const fs::path& path) noexcept
  {
    entry_path_storage_ = path.u8string();
    entry_ = faf_filesystem_entry{entry_path_storage_.c_str()};
  }

  void update(const std::error_code& error_code) noexcept
  {
    entry_ = std::nullopt;
    entry_path_storage_.clear();
  }

private:
  std::optional<faf_filesystem_entry> entry_;
  std::string entry_path_storage_;
};

template <typename Callback>
int enumerate_audiofiles(const fs::path& directory, Callback&& callback) noexcept
{
  std::error_code error;
  auto iterator = audiofile_iterator(directory, error);

  if (error)
  {
    return error.value();
  }

  int callback_return_value = 0;
  for (; !iterator.at_end() && callback_return_value == 0; iterator.move_next())
  {
    callback_return_value = callback(iterator.current().path());
  }

  return callback_return_value;
}

using message = std::variant<std::error_code, fs::path>;

} // namespace

class faf_context
{
public:
  faf_context(const fs::path& directory, std::error_code& error) noexcept
  {
    enumerator_thread_ = std::thread(
      [this, directory = directory] { enumerator_thread_function(directory); });

    error = process_next_message();
    if (error)
    {
      try
      {
        enumerator_thread_.join();
      }
      catch (const std::exception&)
      {
      }
    }
  }

  ~faf_context()
  {
    try
    {
      is_active_.store(false);
      // Make sure that enumerator_thread_ isn't blocking on a full queue.
      message msg;
      queue_.try_dequeue(msg);
      enumerator_thread_.join();
    }
    catch (const std::exception&)
    {
    }
  }

  faf_context(const faf_context&) = delete;
  faf_context& operator=(const faf_context&) = delete;

  faf_filesystem_entry* entry() noexcept { return entry_wrapper_.entry(); }

  std::error_code process_next_message()
  {
    message msg;
    queue_.wait_dequeue(msg);
    std::visit([&](const auto& value) { entry_wrapper_.update(value); }, msg);
    return std::holds_alternative<std::error_code>(msg) ? std::get<std::error_code>(msg)
                                                        : std::error_code{};
  }

private:
  void enumerator_thread_function(const fs::path& directory) noexcept
  {
    const auto result = enumerate_audiofiles(
      directory, [this](const fs::path& path) { return post(path) ? 0 : -1; });
    post(std::error_code{result, std::system_category()});
  }

  bool post(message&& msg) noexcept
  {
    if (is_active_.load())
    {
      queue_.wait_enqueue(std::move(msg));
      return true;
    }
    return false;
  }

  moodycamel::BlockingReaderWriterCircularBuffer<message> queue_{queue_capacity};
  std::thread enumerator_thread_;
  std::atomic<bool> is_active_{true};
  filesystem_entry_wrapper entry_wrapper_;
};

int faf_first(const char* directory, faf_context** context, faf_filesystem_entry** entry)
{
  if (context)
  {
    *context = nullptr;
  }

  if (entry)
  {
    *entry = nullptr;
  }

  if (directory == nullptr || context == nullptr || entry == nullptr)
  {
    return std::make_error_code(std::errc::invalid_argument).value();
  }

  std::error_code error;
  auto new_context = std::make_unique<faf_context>(fs::u8path(directory), error);
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

  const auto error = context->process_next_message();
  *entry = context->entry();
  return error.value();
}

void faf_close(faf_context* context)
{
  delete context;
}

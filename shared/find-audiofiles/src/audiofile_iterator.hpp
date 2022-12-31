#include <array>
#include <filesystem>
#include <system_error>

namespace fs = std::filesystem;

inline bool is_audio_file_path(const fs::path& path) noexcept
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
  using directory_iterator = fs::recursive_directory_iterator;

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

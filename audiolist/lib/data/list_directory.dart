import 'package:find_audiofiles/find_audiofiles.dart';

Stream<FilesystemEntry> listDirectory(String path) {
  return findAudioFiles(path).map((entry) => FilesystemEntry(entry.path));
}

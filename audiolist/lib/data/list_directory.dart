import 'package:find_audiofiles/find_audiofiles.dart';

Stream<FilesystemEntry> listDirectory(String path) {
  final stopwatch = Stopwatch();
  stopwatch.start();
  var oldTime = 0;
  return findAudioFilesUsingMessages(path).map((entry) {
    final newTime = stopwatch.elapsedMicroseconds;
    final duration = newTime - oldTime;
    oldTime = newTime;
    return FilesystemEntry('$newTime (+$duration): ${entry.path}');
  });
}

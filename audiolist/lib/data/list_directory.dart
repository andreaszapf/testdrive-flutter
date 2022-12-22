import 'dart:io';
import 'dart:isolate';

import 'package:audiolist/data/filesystem_entry.dart';

/// Lists directory contents with disk I/O performed on a background thread
///
/// For now to test drive retrieving data in the background. Later, listing
/// will be deferred to a C library.
Stream<FilesystemEntry> listDirectory(String path) async* {
  var receivePort = ReceivePort();

  Isolate.spawn<_ListerIsolateModel>(
      _listInIsolate, _ListerIsolateModel(path, receivePort.sendPort));

  // WIP stop the isolate when the stream is no longer being listened to.
  await for (var message in receivePort) {
    if (message is FilesystemEntry) {
      yield message;
    }
  }
}

class _ListerIsolateModel {
  final String path;
  final SendPort sendPort;
  _ListerIsolateModel(this.path, this.sendPort);
}

void _listInIsolate(_ListerIsolateModel model) {
  var listStream = Directory(model.path)
      .listSync()
      .map((entry) => FilesystemEntry(entry.path));
  for (var filesystemEntry in listStream) {
    // Uncomment to see the list build up while the UI is still responsive
    // sleep(const Duration(milliseconds: 500));
    model.sendPort.send(filesystemEntry);
  }
}

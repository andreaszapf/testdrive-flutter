import 'dart:async';
import 'dart:developer';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:async/async.dart';

import 'bindings.dart';
import 'find_audiofiles_bindings_generated.dart';

class FilesystemEntry {
  final String path;
  FilesystemEntry(this.path);
}

Stream<FilesystemEntry> findAudioFiles(String path) {
  SendPort? sendPort;
  late StreamController<FilesystemEntry> streamController;

  Future run() async {
    final receivePort = ReceivePort();
    final queue = StreamQueue(receivePort);

    await Isolate.spawn(_isolate, _IsolateArgs(path, receivePort.sendPort));
    sendPort = (await queue.next) as SendPort;

    await for (final msg in queue.rest) {
      if (msg is FilesystemEntry) {
        streamController.add(msg);
      } else if (msg is _IterationEnd) {
        receivePort.close(); // Allow the isolate object to be collected
        break;
      }
    }

    streamController.close();
  }

  streamController = StreamController<FilesystemEntry>(
    onListen: () {
      run();
    },
    onCancel: () async {
      sendPort?.send(_Cancellation());
    },
  );

  return streamController.stream;
}

class _Cancellation {}

class _IterationEnd {}

class _IsolateArgs {
  final String path;
  final SendPort sendPort;

  _IsolateArgs(this.path, this.sendPort);
}

Future _isolate(_IsolateArgs args) async {
  final finder = _BackgoundFinder(args.path, args.sendPort);
  try {
    await finder.run();
  } finally {
    finder.dispose();
  }
}

class _BackgoundFinder {
  final _messagePort = ReceivePort();
  late Pointer<Char> _nativePath;
  late SendPort _sendPort;
  late Arena _arena;
  late Pointer<Pointer<faf_context>> _context;
  late Pointer<Pointer<faf_filesystem_entry>> _entry;

  _BackgoundFinder(String path, SendPort sendPort) {
    _nativePath = path.toNativeUtf8().cast<Char>();
    _sendPort = sendPort;
    _arena = Arena();
    _context = _arena<Pointer>().cast<Pointer<faf_context>>();
    _entry = _arena<Pointer>().cast<Pointer<faf_filesystem_entry>>();
  }

  void dispose() {
    _arena.releaseAll();
    _messagePort.close();
  }

  Future run() async {
    _sendPort.send(_messagePort.sendPort);

    try {
      // Set a message handler for cancellation
      bool isActive = true;
      final messageSubscription = _messagePort.listen(
        (message) {
          if (message is _Cancellation) {
            isActive = false;
          }
        },
      );

      // Iterate asynchronously over the returned files so that the handler
      // above can run between iteration steps and modify isActive.
      try {
        await for (final fsEntry in _listAudiofiles()) {
          if (!isActive) {
            break;
          }
          _sendPort.send(fsEntry);
        }
      } finally {
        messageSubscription.cancel();
      }
    } catch (e, s) {
      // In production errors should be sent to a dedicated error port, and be
      // handled or rethrown by the main isolate.
      log('Error in findAudiofiles', error: e, stackTrace: s);
    } finally {
      _sendPort.send(_IterationEnd());
    }
  }

  // This needs to be an asynchronous generator, so that the `finally` clause
  // is excecuted when the iteration is canceled, and so that run() can iterate
  // over the returned events asynchronously.
  Stream<FilesystemEntry> _listAudiofiles() async* {
    _throwOnError(
        () => bindings.faf_first_wrapper(_nativePath, _context, _entry));
    try {
      while (_entry.value.address != 0) {
        final fsEntry =
            FilesystemEntry(_entry.value.ref.path.cast<Utf8>().toDartString());
        yield fsEntry;
        _throwOnError(() => bindings.faf_next_wrapper(_context.value, _entry));
      }
    } finally {
      bindings.faf_close_wrapper(_context.value);
    }
  }
}

void _throwOnError(int Function() f) {
  final errorCode = f();
  if (errorCode != 0) {
    throw OSError('', errorCode);
  }
}

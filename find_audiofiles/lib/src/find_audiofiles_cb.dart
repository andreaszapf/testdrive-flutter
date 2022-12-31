// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'bindings.dart';
import 'find_audiofiles.dart';
import 'find_audiofiles_bindings_generated.dart';

Stream<FilesystemEntry> findAudioFilesUsingCallbacks(String path) {
  final finder = _AudioFilesScanner(path);
  return finder._streamController.stream;
}

class _AudioFilesScanner {
  late Pointer<audiofile_scanner> _nativeScanner;
  late StreamController<FilesystemEntry> _streamController;
  final _receivePort = ReceivePort();

  _AudioFilesScanner(String path) {
    final errorPtr = malloc.allocate<Int>(sizeOf<Int>());
    _nativeScanner = bindings.make_audiofile_scanner(
        path.toNativeUtf8().cast<Char>(), errorPtr);
    final error = errorPtr.value;
    malloc.free(errorPtr);

    if (error != 0) {
      throw OSError('', error);
    }

    _streamController = StreamController<FilesystemEntry>(
      onListen: () {
        _scan();
      },
      onCancel: () {
        // WIP throw on failure
        bindings.audiofile_scanner_cancel_scan(_nativeScanner);
      },
    );
  }

  void _scan() {
    (() async {
      try {
        await Isolate.spawn(_isolateFunc,
            _FafIsolateContext(_nativeScanner.address, _receivePort.sendPort));
        await for (final message in _receivePort) {
          if (message is FilesystemEntry) {
            _streamController.add(message);
          } else if (message is int) {
            // Iteration stopped, we got the result of audiofile_scanner_scan().
            if (message != 0) {
              _streamController.addError(OSError('', message));
            }
            break;
          }
        }
      } finally {
        _streamController.close();
        _receivePort.close(); // Allow the isolate object to be collected
        bindings.audiofile_scanner_close(_nativeScanner);
        _nativeScanner = Pointer.fromAddress(0);
      }
    })();
  }
}

class _FafIsolateContext {
  int nativeScannerAddress;
  SendPort sendPort;
  _FafIsolateContext(this.nativeScannerAddress, this.sendPort);
}

_FafIsolateContext? _currentIsolateContext;

void _onFafEntry(Pointer<faf_filesystem_entry> nativeEntry) {
  final entry =
      FilesystemEntry(nativeEntry.ref.path.cast<Utf8>().toDartString());
  _currentIsolateContext!.sendPort.send(entry);
}

void _isolateFunc(_FafIsolateContext context) {
  // Make context accessible to _onFafEnty by storing it in a global variable.
  // This is safe because each findAudiofiles() call spawns a new isolate -
  // global variables aren't shared between isolates.
  if (_currentIsolateContext != null) {
    throw StateError('Unsupported reentrant call to _runFafFind.');
  }
  _currentIsolateContext = context;

  final audiofile_scanner_callback nativeOnFafEntry =
      Pointer.fromFunction<Void Function(Pointer<faf_filesystem_entry>)>(
          _onFafEntry);

  final nativeScanner = Pointer.fromAddress(context.nativeScannerAddress)
      .cast<audiofile_scanner>();

  try {
    final result =
        bindings.audiofile_scanner_scan(nativeScanner, nativeOnFafEntry);
    context.sendPort.send(result);
  } finally {
    // release resources so that the isolate can be collected
    _currentIsolateContext = null;
  }
}

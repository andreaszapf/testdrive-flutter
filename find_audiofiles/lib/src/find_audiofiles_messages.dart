// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:ffi/ffi.dart';

import 'bindings.dart';
import 'find_audiofiles.dart';
import 'find_audiofiles_bindings_generated.dart';

Stream<FilesystemEntry> findAudioFilesUsingMessages(String path) async* {
  final sendPort = await _ensureIsolate();
  final receivePort = ReceivePort();
  final remoteSendPort = receivePort.sendPort;
  final queue = StreamQueue(receivePort);

  var context = _Context(path);
  try {
    sendPort.send(_ContextMessage(context, remoteSendPort));
    FilesystemEntry? entry = await queue.next as FilesystemEntry?;
    while (entry != null) {
      yield entry;
      ++context.numCalls;
      sendPort.send(_ContextMessage(context, remoteSendPort));
      entry = await queue.next as FilesystemEntry?;
    }
  } finally {
    bindings.faf_close_wrapper(context.nativeContextPtr.value);
    receivePort.close();
    context.dispose();
    queue.cancel();
  }
}

class _ContextMessage {
  final String path;
  final int nativeContextPtrAddress;
  final int nativeEntryPtrAddress;
  final int numCalls;
  final SendPort sendPort;

  _ContextMessage(_Context ctx, SendPort sendPort_)
      : path = ctx.path,
        nativeContextPtrAddress = ctx.nativeContextPtr.address,
        nativeEntryPtrAddress = ctx.nativeEntryPtr.address,
        numCalls = ctx.numCalls,
        sendPort = sendPort_;
}

class _Context {
  String path;
  Pointer<Pointer<faf_context>> nativeContextPtr =
      malloc<Pointer>().cast<Pointer<faf_context>>();
  Pointer<Pointer<faf_filesystem_entry>> nativeEntryPtr =
      malloc<Pointer>().cast<Pointer<faf_filesystem_entry>>();
  int numCalls = 0;

  _Context(this.path);

  _Context.fromMessage(_ContextMessage msg)
      : path = msg.path,
        nativeContextPtr = Pointer.fromAddress(msg.nativeContextPtrAddress),
        nativeEntryPtr = Pointer.fromAddress(msg.nativeEntryPtrAddress),
        numCalls = msg.numCalls;

  void dispose() {
    malloc.free(nativeContextPtr);
    malloc.free(nativeEntryPtr);
  }
}

SendPort? _sendPort;

Future<SendPort> _ensureIsolate() async {
  if (_sendPort != null) return Future.value(_sendPort);

  final initialReceivePort = ReceivePort();
  try {
    final sendPort = initialReceivePort.sendPort;
    await Isolate.spawn(_isolateFunc, sendPort);
    _sendPort = await initialReceivePort.first;
    return Future.value(_sendPort);
  } finally {
    initialReceivePort.close();
  }
}

void _isolateFunc(SendPort initialSendPort) async {
  final receivePort = ReceivePort();
  initialSendPort.send(receivePort.sendPort);

  await for (final msg in receivePort) {
    if (msg is _ContextMessage) {
      final ctx = _Context.fromMessage(msg);
      msg.sendPort.send(_nextFilesystemEntrySync(ctx));
    } else {
      return;
    }
  }
}

FilesystemEntry? _nextFilesystemEntrySync(_Context ctx) {
  if (ctx.numCalls == 0) {
    final nativePath = ctx.path.toNativeUtf8().cast<Char>();
    _throwOnError(() => bindings.faf_first_wrapper(
        nativePath, ctx.nativeContextPtr, ctx.nativeEntryPtr));
  } else {
    _throwOnError(() => bindings.faf_next_wrapper(
        ctx.nativeContextPtr.value, ctx.nativeEntryPtr));
  }

  return ctx.nativeEntryPtr.value.address != 0
      ? FilesystemEntry(
          ctx.nativeEntryPtr.value.ref.path.cast<Utf8>().toDartString())
      : null;
}

void _throwOnError(int Function() f) {
  final errorCode = f();
  if (errorCode != 0) {
    throw OSError('', errorCode);
  }
}

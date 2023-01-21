// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import 'bindings.dart';
import 'find_audiofiles.dart';
import 'find_audiofiles_bindings_generated.dart';

Stream<FilesystemEntry> findAudioFilesUsingCompute(String path) async* {
  var context = _Context(path);
  try {
    FilesystemEntry? entry =
        await compute(_nextFilesystemEntry, _ContextMessage(context));
    while (entry != null) {
      yield entry;
      ++context.numCalls;
      FilesystemEntry? entry2 =
          await compute(_nextFilesystemEntry, _ContextMessage(context));
      entry = entry2;
    }
  } finally {
    bindings.faf_close_wrapper(context.nativeContextPtr.value);
    context.dispose();
  }
}

class _ContextMessage {
  final String path;
  final int nativeContextPtrAddress;
  final int nativeEntryPtrAddress;
  final int numCalls;

  _ContextMessage(_Context ctx)
      : path = ctx.path,
        nativeContextPtrAddress = ctx.nativeContextPtr.address,
        nativeEntryPtrAddress = ctx.nativeEntryPtr.address,
        numCalls = ctx.numCalls;
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

FilesystemEntry? _nextFilesystemEntry(_ContextMessage msg) {
  final ctx = _Context.fromMessage(msg);

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

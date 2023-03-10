import 'dart:ffi';
import 'dart:io';

import 'find_audiofiles_bindings_generated.dart';

const String _libName = 'find_audiofiles';

/// The dynamic library in which the symbols for [FindAudiofilesBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

final bindings = FindAudiofilesBindings(_dylib);

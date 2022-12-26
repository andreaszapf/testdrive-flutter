library test_data;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:file/file.dart' as file;
import 'package:file/local.dart' as file;

final _prefixPattern = RegExp('.*data/');
const _dataDirName = 'test_data';

Future<List<String>> fetchFileList() async {
  final manifest = await rootBundle.loadString('AssetManifest.json');
  final Map<String, dynamic> map = jsonDecode(manifest);
  final srcPaths = map.keys
      .where((srcPath) => _prefixPattern.matchAsPrefix(srcPath) != null);
  return List.from(srcPaths);
}

/// Copies test data into a `test_data` folder under to the given destination
/// directory. An existing folder at the destination is cleared before copying.
/// Returns the created directory.
Future<Directory> copyData(String destinationDirectory,
    {file.FileSystem fileSystem = const file.LocalFileSystem()}) async {
  final destDataDir = fileSystem
      .directory(path.normalize('$destinationDirectory/$_dataDirName'));
  if (await destDataDir.exists()) {
    await destDataDir.delete(recursive: true);
  }

  final files = await fetchFileList();
  for (final srcPath in files) {
    final destPath = srcPath.replaceFirst(_prefixPattern, '$_dataDirName/');
    final destFilename = path.normalize('$destinationDirectory/$destPath');
    var data = await rootBundle.load(srcPath);
    var f = fileSystem.file(destFilename);
    await f.create(recursive: true);
    await f.writeAsBytes(data.buffer.asInt8List());
  }

  return destDataDir;
}

import 'dart:io';

import 'package:file/memory.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import 'package:test_data/test_data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  test('finds file list', () async {
    final files = await fetchFileList();
    expect(files, isNotEmpty);
    expect(files, everyElement(contains('data/')));
  });

  test('copies files to destination', () async {
    final fs = MemoryFileSystem(
        style: Platform.isWindows
            ? FileSystemStyle.windows
            : FileSystemStyle.posix);
    final rootPath = fs.currentDirectory.path;
    final destDir = fs.directory(path.join(rootPath, 'test_dir'))
      ..createSync(recursive: true);
    final destDataDir = await copyData(destDir.path, fileSystem: fs);
    expect(destDataDir.existsSync(), true);
    expect(destDataDir.path, path.join(destDir.path, 'test_data'));

    final destFiles = destDataDir.listSync(recursive: true);
    expect(destFiles, isNotEmpty);

    // Check that the data path component is stripped
    expect(
        destFiles,
        isNot(everyElement(
            contains('${fs.path.separator}data${fs.path.separator}'))));

    // Check that all files were copied
    final srcFilenames = List<String>.from(await fetchFileList())
        .map((e) => RegExp(r'[^/]+$').allMatches(e).last.group(0));
    final destFilenames = List<String>.from(destDataDir
        .listSync(recursive: true)
        .where((entry) => entry.statSync().type == FileSystemEntityType.file)
        .map((e) => path.basename(e.path)));
    expect(destFilenames, unorderedEquals(srcFilenames));
  });

  test('clears destination directory before copying', () async {
    final fs = MemoryFileSystem(
        style: Platform.isWindows
            ? FileSystemStyle.windows
            : FileSystemStyle.posix);
    final rootPath = fs.currentDirectory.path;
    final destDir = fs.directory(path.join(rootPath, 'test_dir'))
      ..createSync(recursive: true);
    final destDataDir = fs.directory(path.join(destDir.path, 'test_data'))
      ..createSync();
    final fileToDelete = fs
        .file(path.join(destDataDir.path, 'should_be_deleted.txt'))
      ..createSync();
    expect(fileToDelete.existsSync(), true);
    await copyData(destDir.path, fileSystem: fs);
    expect(fileToDelete.existsSync(), false);
  });
}

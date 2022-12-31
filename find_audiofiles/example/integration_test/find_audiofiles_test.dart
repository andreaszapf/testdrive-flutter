import 'dart:io';

import 'package:find_audiofiles/find_audiofiles.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:test_data/test_data.dart' as test_data;

import 'package:find_audiofiles_example/main.dart' as app;

bool _isAudioFile(FileSystemEntity entity) {
  return entity.statSync().type == FileSystemEntityType.file &&
      RegExp(r'.*\.(mp3|MP3|m4a|M4A|m4b|M4B)$').hasMatch(entity.path);
}

// ignore: prefer_generic_function_type_aliases
typedef Stream<FilesystemEntry> FindAudiofilesFunc(String path);

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final testDataDir =
      await test_data.copyData((await getApplicationSupportDirectory()).path);

  final audioFileNames = List<String>.from(testDataDir
      .listSync(recursive: true)
      .where(_isAudioFile)
      .map((e) => RegExp(r'[^\\/]+$').firstMatch(e.path)!.group(0)!));

  final variants = ValueVariant<FindAudiofilesFunc>(
      <FindAudiofilesFunc>{findAudioFiles, findAudioFilesUsingCallbacks});

  testWidgets('Test data files are listed', (tester) async {
    final func = variants.currentValue!;
    app.main();
    await tester.pumpAndSettle();
    final audiofiles = await func(testDataDir.path).toList();
    expect(audiofiles, isNotEmpty);
    expect(audiofiles.map((e) => path.basename(e.path)), audioFileNames);
  }, variant: variants);
}

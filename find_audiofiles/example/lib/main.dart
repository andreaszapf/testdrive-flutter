import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:find_audiofiles/find_audiofiles.dart' as find_audiofiles;
import 'package:test_data/test_data.dart' as test_data;

enum RunMode {
  regular,
  integrationTests,
}

void main({RunMode runMode = RunMode.regular}) {
  runApp(MyApp(runMode: runMode));
}

class MyApp extends StatefulWidget {
  final RunMode runMode;
  const MyApp({super.key, required this.runMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String firstFile = '';

  @override
  void initState() {
    super.initState();

    // Avoid spawning an async task in test mode
    if (widget.runMode == RunMode.integrationTests) {
      return;
    }

    (() async {
      final destDir = await getApplicationSupportDirectory();
      final testDataDir = await test_data.copyData(destDir.path);
      final firstFile = (await find_audiofiles
              .findAudioFilesUsingCompute(testDataDir.path)
              .first)
          .path;
      // Might be about to close
      if (mounted) {
        setState(() {
          this.firstFile = firstFile;
        });
      }
    })();
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Listing audio files natively'),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const Text(
                  'This calls native functions through FFI that are linked '
                  'from a C library outside the package. The native code is '
                  'built as part of the Flutter Runner build.',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                Text(
                  'First file found: $firstFile',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

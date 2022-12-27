import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:find_audiofiles/find_audiofiles.dart' as find_audiofiles;
import 'package:test_data/test_data.dart' as test_data;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String firstFile = '';

  @override
  void initState() {
    super.initState();

    (() async {
      final destDir = await getApplicationSupportDirectory();
      await test_data.copyData(destDir.path);
      final firstFile = (await find_audiofiles
              .findAudioFiles('${destDir.path}/test_data')
              .first)
          .path;
      setState(() {
        this.firstFile = firstFile;
      });
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

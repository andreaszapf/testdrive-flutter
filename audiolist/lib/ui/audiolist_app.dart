import 'package:flutter/material.dart';

import 'main_page.dart';
import 'styles.dart';

class AudiolistApp extends StatelessWidget {
  const AudiolistApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audiolist',
      theme: ThemeData(
        primarySwatch: kPrimarySwatchColor,
      ),
      home: const MainPage(title: 'Audiolist'),
    );
  }
}

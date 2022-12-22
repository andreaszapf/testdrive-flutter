import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/list_directory.dart';
import 'filesystem_listing.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.title});

  final String title;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String _directory = '';

  void _selectDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    setState(() => _directory = selectedDirectory ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          Row(
            children: [
              IconButton(
                onPressed: _selectDirectory,
                icon: const Icon(Icons.folder),
              ),
              Expanded(
                child: Text(_directory),
              ),
            ],
          ),
          Expanded(
            child: _directory.isNotEmpty
                ? FilesystemListing(
                    listingStream: listDirectory(_directory),
                  )
                : const Center(),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';

import '../data/filesystem_entry.dart';

class FilesystemListing extends StatefulWidget {
  const FilesystemListing({super.key, required this.listingStream});

  final Stream<FilesystemEntry> listingStream;

  @override
  State<StatefulWidget> createState() {
    return _FilesystemListingState();
  }
}

class _FilesystemListingState extends State<FilesystemListing> {
  final List<FilesystemEntry> _entries = [];
  StreamSubscription<FilesystemEntry>? _listingSubscription;

  @override
  void initState() {
    _subscribeToListing();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant FilesystemListing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listingStream != widget.listingStream) {
      _unsubscribeFromListing();
      _entries.clear();
      _subscribeToListing();
    }
  }

  @override
  void dispose() {
    _unsubscribeFromListing();
    super.dispose();
  }

  void _subscribeToListing() {
    _listingSubscription = widget.listingStream.listen(
        (entry) => setState(() => _entries.add(entry)),
        onError: (err) => {});
  }

  void _unsubscribeFromListing() {
    _listingSubscription?.cancel();
    _listingSubscription = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) {
      return const Center(); // WIP
    }
    return ListView.builder(
      itemCount: _entries.length,
      itemBuilder: (context, index) => _makeElement(index),
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
    );
  }

  Widget _makeElement(int index) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(_entries[index].path),
      );
}

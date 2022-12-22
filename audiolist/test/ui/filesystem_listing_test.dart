import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:audiolist/data/filesystem_entry.dart';
import 'package:audiolist/ui/filesystem_listing.dart';

void main() {
  testWidgets('FilesystemListing', (WidgetTester tester) async {
    const kDelay = Duration(milliseconds: 100);

    Stream<FilesystemEntry> makeEntries(String dir) async* {
      await Future.delayed(kDelay);
      yield FilesystemEntry('$dir/file1');
      await Future.delayed(kDelay);
      yield FilesystemEntry('$dir/file2');
      await Future.delayed(kDelay);
      yield FilesystemEntry('$dir/file3');
    }

    const listingKey = Key('Listing');

    const app = MaterialApp(
      home: Scaffold(
        body: FilesystemListingWrapper(key: listingKey),
      ),
    );

    await tester.pumpWidget(app);
    var findListing = find.byKey(listingKey);
    expect(findListing, findsOneWidget);
    FilesystemListingWrapperState state = tester.state(findListing);

    state.setListingStream(makeEntries('dir1'));
    await tester.pump(kDelay * 5);
    await tester.pumpAndSettle();
    expect(find.text('dir1/file1'), findsOneWidget);
    expect(find.text('dir1/file2'), findsOneWidget);
    expect(find.text('dir1/file3'), findsOneWidget);

    state.setListingStream(makeEntries('dir2'));
    await tester.pump(kDelay * 5);
    await tester.pumpAndSettle();
    expect(find.text('dir2/file1'), findsOneWidget);
    expect(find.text('dir2/file2'), findsOneWidget);
    expect(find.text('dir2/file3'), findsOneWidget);
  });
}

class FilesystemListingWrapper extends StatefulWidget {
  const FilesystemListingWrapper({super.key});

  @override
  State<StatefulWidget> createState() {
    return FilesystemListingWrapperState();
  }
}

class FilesystemListingWrapperState extends State<FilesystemListingWrapper> {
  Stream<FilesystemEntry>? listingStream;

  void setListingStream(Stream<FilesystemEntry>? stream) {
    setState(() => listingStream = stream);
  }

  @override
  Widget build(BuildContext context) {
    return listingStream != null
        ? FilesystemListing(listingStream: listingStream!)
        : const Center();
  }
}

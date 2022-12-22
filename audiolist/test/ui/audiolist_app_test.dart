import 'package:flutter_test/flutter_test.dart';

import 'package:audiolist/ui/audiolist_app.dart';

void main() {
  testWidgets('Open', (WidgetTester tester) async {
    await tester.pumpWidget(const AudiolistApp());
    // Check for the initial directory display
    expect(find.text(''), findsOneWidget);
  });
}

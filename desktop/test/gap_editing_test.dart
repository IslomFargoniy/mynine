import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynine_desktop/features/passage/html_document.dart';
import 'package:mynine_desktop/features/passage/html_view.dart';

void main() {
  testWidgets('a gap inside selectable text: typing and Backspace both work', (tester) async {
    final controller = TextEditingController();
    final doc = HtmlDocument.parse('<p>Current address: 118 {} Park</p>', blankPattern: RegExp(r'\{\}'));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HtmlView(
          document: doc,
          selectable: true,
          onSelectionChanged: (_) {},
          blankBuilder: (context, blank) => SizedBox(width: 120, child: TextField(key: const Key('gap'), controller: controller)),
        ),
      ),
    ));
    await tester.tap(find.byKey(const Key('gap')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('gap')), 'abc');
    await tester.pump();
    expect(controller.text, 'abc');
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(controller.text, 'ab', reason: 'Backspace must delete in the gap');

    // Arrow left, then Delete removes the character after the caret.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();
    expect(controller.text, 'a');

    // Select all + Backspace empties the gap.
    await tester.enterText(find.byKey(const Key('gap')), 'hello');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(controller.text, '');
  });
}

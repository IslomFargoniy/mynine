import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynine_desktop/features/passage/html_document.dart';
import 'package:mynine_desktop/features/passage/html_view.dart';

void main() {
  testWidgets('a paragraph with a gap can be selected; offsets skip the gap', (tester) async {
    HtmlSelection? got;
    final doc = HtmlDocument.parse('<p>Hello {} world</p>', blankPattern: RegExp(r'\{\}'));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HtmlView(
          document: doc,
          selectable: true,
          onSelectionChanged: (s) => got = s,
          blankBuilder: (context, blank) => const SizedBox(width: 40, height: 10, child: TextField()),
        ),
      ),
    ));
    expect(find.byType(SelectableText), findsOneWidget, reason: 'the block with a gap is selectable now');
    expect(find.byType(TextField), findsOneWidget, reason: 'the gap is still there');

    // "Hello ￼ world": select "world" (8..13 with the gap as one placeholder character).
    final editable = tester.state<EditableTextState>(find.descendant(of: find.byType(SelectableText), matching: find.byType(EditableText)).first);
    editable.userUpdateTextEditingValue(
      editable.textEditingValue.copyWith(selection: const TextSelection(baseOffset: 8, extentOffset: 13)),
      SelectionChangedCause.drag,
    );
    await tester.pump();
    expect(got, isNotNull);
    expect(doc.textInRange(got!.start, got!.end), 'world');
    expect(got!.text, 'world');

    // "Hello" before the gap.
    editable.userUpdateTextEditingValue(
      editable.textEditingValue.copyWith(selection: const TextSelection(baseOffset: 0, extentOffset: 5)),
      SelectionChangedCause.drag,
    );
    await tester.pump();
    expect(got!.text, 'Hello');
  });
}

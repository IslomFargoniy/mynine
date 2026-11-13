import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynine_desktop/features/passage/html_document.dart';
import 'package:mynine_desktop/features/passage/html_view.dart';

void main() {
  test('text tokenised word by word is rejoined (PDF / AI import)', () {
    expect(cleanTinyMce("<p>Club of America . California ' s laws , its {24} , ok</p>"),
        "<p>Club of America. California's laws, its {24}, ok</p>");
    expect(cleanTinyMce('<p>It is 5 % of 1,000. e.g. fine</p>'), '<p>It is 5% of 1,000. e.g. fine</p>');
    // Non-breaking spaces from PDFs would keep a whole line from wrapping.
    expect(cleanTinyMce('<p>Wood\u00A0is\u00A0a\u202Ftraditional</p>'), '<p>Wood is a traditional</p>');
  });

  group('HtmlDocument', () {
    test('flattens blocks, collapses whitespace and assigns offsets', () {
      final doc = HtmlDocument.parse(
        '<h2>Title</h2><p>Hello   <strong>big</strong>\n world&nbsp;!</p>'
        '<ul><li>one</li><li>two<br>lines</li></ul><ol><li>first</li></ol>',
      );
      final blocks = doc.textBlocks.toList();
      expect(blocks.map((b) => b.text), ['Title', 'Hello big world!', 'one', 'two\nlines', 'first']);
      expect(blocks[0].kind, BlockKind.h2);
      expect(blocks[2].listMarker, '•');
      expect(blocks[4].listMarker, '1.');
      expect(doc.plainText, 'TitleHello big world!onetwo\nlinesfirst');
      expect(blocks[1].start, 5);
      expect(blocks[1].end, 5 + 'Hello big world!'.length);
      final bold = blocks[1].inlines.whereType<TextRun>().firstWhere((r) => r.style.bold);
      expect(bold.text, 'big');
      expect(doc.textInRange(bold.start, bold.end), 'big');
    });

    test('inline styles, sup/sub, span styles, zero-width chars', () {
      final doc = HtmlDocument.parse(
        '<p><em>i</em><u>u</u><b>b</b>H<sub>2</sub>O x<sup>2</sup>'
        '<span style="font-weight: bold">S</span>​</p>',
      );
      final runs = doc.textBlocks.single.inlines.whereType<TextRun>().toList();
      expect(runs.firstWhere((r) => r.text == 'i').style.italic, isTrue);
      expect(runs.firstWhere((r) => r.text == 'u').style.underline, isTrue);
      expect(runs.firstWhere((r) => r.text == '2' && r.style.subscript).style.subscript, isTrue);
      expect(runs.any((r) => r.style.superscript), isTrue);
      expect(runs.firstWhere((r) => r.text == 'S').style.bold, isTrue);
      expect(doc.plainText.contains('​'), isFalse);
    });

    test('tables and images', () {
      final doc = HtmlDocument.parse(
        '<table><thead><tr><th>A</th><th>B</th></tr></thead>'
        '<tbody><tr><td>1</td><td><p>2</p><p>3</p></td></tr></tbody></table>'
        '<p><img src="https://x/a.png" width="200"></p>',
      );
      final table = doc.blocks.whereType<TableBlock>().single;
      expect(table.rows.length, 2);
      expect(table.rows.first.first.header, isTrue);
      expect(table.columnCount, 2);
      expect(table.rows[1][1].blocks.length, 2);
      final img = doc.blocks.whereType<ImageBlock>().single;
      expect(img.src, 'https://x/a.png');
      expect(img.width, 200);
      expect(doc.plainText, 'AB123');
    });

    test('complete_section blanks map to questions in order and take no offsets', () {
      final doc = HtmlDocument.parse(
        '<p>Name: Sarah {1}</p><table><tr><td>Address</td><td>{2} Street</td></tr></table><p>Fee £{x}.</p>',
        blankPattern: HtmlDocument.sectionBlankPattern,
      );
      expect(doc.blankCount, 3);
      expect(doc.blanks.map((b) => b.index), [0, 1, 2]);
      expect(doc.blanks.map((b) => b.marker), ['{1}', '{2}', '{x}']);
      // Spaces next to a blank are kept so the input sits between words.
      expect(doc.plainText, 'Name: Sarah Address StreetFee £.');
    });

    test('fill_blank only matches {}', () {
      final doc = HtmlDocument.parse('<p>Built of {} iron, not {this}.</p>',
          blankPattern: HtmlDocument.emptyBlankPattern);
      expect(doc.blankCount, 1);
      expect(doc.plainText, 'Built of  iron, not {this}.');
    });

    test('htmlToPlainText', () {
      expect(htmlToPlainText('<p>i&nbsp; Early <b>criticism</b></p>'), 'i Early criticism');
    });
  });

  group('HtmlView', () {
    testWidgets('paints highlights over exact offsets', (tester) async {
      final doc = HtmlDocument.parse('<p>The quick brown fox</p><p>jumps over</p>');
      // "quick" = [4, 9); "jumps" starts at 19.
      final view = HtmlView(
        document: doc,
        highlights: const [HighlightRange(4, 9), HighlightRange(19, 24, isNote: true)],
        highlightColor: const Color(0xFFFFFF00),
        noteColor: const Color(0xFF00FFFF),
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: view)));
      final state = tester.state<HtmlViewState>(find.byType(HtmlView));
      final ctx = tester.element(find.byType(HtmlView));
      final span = state.buildSpan(ctx, doc.textBlocks.first, const TextStyle()) as TextSpan;
      final parts = span.children!.cast<TextSpan>();
      expect(parts.map((s) => s.text), ['The ', 'quick', ' brown fox']);
      expect(parts[1].style!.backgroundColor, const Color(0xFFFFFF00));
      expect(parts[0].style!.backgroundColor, isNull);
      final span2 = state.buildSpan(ctx, doc.textBlocks.last, const TextStyle()) as TextSpan;
      final p2 = span2.children!.cast<TextSpan>();
      expect(p2.first.text, 'jumps');
      expect(p2.first.style!.backgroundColor, const Color(0xFF00FFFF));
    });

    testWidgets('renders complete_section blanks with the blank builder', (tester) async {
      final doc = HtmlDocument.parse('<p>A {1} and {2}</p>', blankPattern: HtmlDocument.sectionBlankPattern);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HtmlView(
            document: doc,
            blankBuilder: (_, b) => SizedBox(width: 60, child: TextField(key: Key('blank-${b.index}'))),
          ),
        ),
      ));
      expect(find.byKey(const Key('blank-0')), findsOneWidget);
      expect(find.byKey(const Key('blank-1')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('blank-1')), 'carbon');
      expect(find.text('carbon'), findsOneWidget);
    });

    testWidgets('selectable blocks report selections as document offsets', (tester) async {
      final doc = HtmlDocument.parse('<p>First para</p><p>Second para</p>');
      HtmlSelection? got;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HtmlView(document: doc, selectable: true, onSelectionChanged: (s) => got = s),
        ),
      ));
      final second = find.byType(SelectableText).last;
      final editable = tester.state<EditableTextState>(
        find.descendant(of: second, matching: find.byType(EditableText)),
      );
      editable.userUpdateTextEditingValue(
        editable.textEditingValue.copyWith(selection: const TextSelection(baseOffset: 0, extentOffset: 6)),
        SelectionChangedCause.drag,
      );
      await tester.pump();
      expect(got, isNotNull);
      expect(got!.start, 'First para'.length);
      expect(got!.end, 'First para'.length + 6);
      expect(got!.text, 'Second');
    });
  });

  testWidgets('an inline data: image (imported Writing chart) is drawn, never printed as text', (tester) async {
    final doc = HtmlDocument.parse('<p>Chart:</p><p><strong>Task</strong> <img alt="chart" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="></p>');
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: HtmlView(document: doc))));
    expect(find.byType(Image), findsOneWidget);
    expect(find.textContaining('base64'), findsNothing);
  });
}

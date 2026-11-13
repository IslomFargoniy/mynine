import 'package:flutter/painting.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// A parsed TinyMCE HTML fragment, flattened into blocks of inline runs.
///
/// Every [TextRun] has a global character offset ([TextRun.start]); offsets are
/// assigned in document order over the *rendered* text (whitespace collapsed,
/// `<br>` = `\n`). Highlights are stored as `[start, end)` ranges over these
/// offsets, so they survive re-rendering. Blanks (`{…}` in complete_section /
/// drag_and_drop, `{}` in fill_blank) are [BlankRun]s that occupy no offsets.
class HtmlDocument {
  HtmlDocument._(this.blocks, this.length, this.blankCount, this._text);

  final List<HtmlBlock> blocks;

  /// Total number of characters (sum of all text runs).
  final int length;

  /// Number of blanks found (in document order).
  final int blankCount;

  final String _text;

  /// The concatenated text of all runs (offset space of highlights).
  String get plainText => _text;

  String textInRange(int start, int end) {
    final s = start.clamp(0, _text.length);
    final e = end.clamp(s, _text.length);
    return _text.substring(s, e);
  }

  bool get isEmpty => blocks.isEmpty;

  /// Iterates all text blocks, including those inside table cells.
  Iterable<TextBlock> get textBlocks sync* {
    Iterable<TextBlock> walk(List<HtmlBlock> list) sync* {
      for (final b in list) {
        switch (b) {
          case TextBlock():
            yield b;
          case TableBlock():
            for (final row in b.rows) {
              for (final cell in row) {
                yield* walk(cell.blocks);
              }
            }
          case ImageBlock():
            break;
        }
      }
    }

    yield* walk(blocks);
  }

  Iterable<BlankRun> get blanks =>
      textBlocks.expand((b) => b.inlines).whereType<BlankRun>();

  /// Matches `{anything}` (complete_section / drag_and_drop markers).
  static final RegExp sectionBlankPattern = RegExp(r'\{[^{}\n]*\}');

  /// Matches `{}` only (fill_blank inside a question).
  static final RegExp emptyBlankPattern = RegExp(r'\{\}');

  /// Parses [html]. When [blankPattern] is given, matching text becomes
  /// [BlankRun]s numbered from 0 in document order.
  static HtmlDocument parse(String? html, {RegExp? blankPattern}) {
    final builder = _Builder(blankPattern);
    final fragment = html_parser.parseFragment(cleanTinyMce(html ?? ''));
    builder.walkChildren(fragment.nodes, const InlineStyle());
    builder.flush();
    final out = builder.root;
    return HtmlDocument._(out, builder.offset, builder.blankIndex, builder.text.toString());
  }
}

/// Mirrors `cleanTinyMce` from the web app (zero-width chars, &nbsp;).
String cleanTinyMce(String html) {
  final cleaned = html
      .replaceAll(RegExp('[​-‍﻿]'), '')
      .replaceAll(RegExp('&nbsp;', caseSensitive: false), ' ');
  return _normalizeText(cleaned);
}

final _tagSplit = RegExp(r'(<[^>]+>)');
final _spaceBeforePunct = RegExp(r'''([\p{L}\p{N}"'”’)\]}]) +([.,;:!?%)])(?=\s|$)''', unicode: true);
final _apostrophe = RegExp(r"(\p{L}) ?['’] ?(s|t|d|m|ll|re|ve)\b", unicode: true);

/// Text tokenised word by word (PDF / AI import) is rejoined, as on the web (`normalizeContentHtml`):
/// "America ." → "America.", "California ' s" → "California's". Tags and `{…}` blanks are left alone.
String _normalizeText(String html) {
  final out = StringBuffer();
  var last = 0;
  String fix(String t) => t
      .replaceAllMapped(_spaceBeforePunct, (m) => '${m[1]}${m[2]}')
      .replaceAllMapped(_apostrophe, (m) => "${m[1]}'${m[2]}");
  for (final m in _tagSplit.allMatches(html)) {
    out
      ..write(fix(html.substring(last, m.start)))
      ..write(m[0]);
    last = m.end;
  }
  out.write(fix(html.substring(last)));
  return out.toString();
}

/// Plain text of an HTML fragment (for option labels, matching headings).
String htmlToPlainText(String? html) {
  final doc = HtmlDocument.parse(html);
  return doc.plainText.replaceAll(RegExp(r'\s+'), ' ').trim();
}

enum BlockKind { paragraph, h1, h2, h3, h4, listItem, preformatted }

sealed class HtmlBlock {
  const HtmlBlock();
}

class TextBlock extends HtmlBlock {
  TextBlock({
    required this.kind,
    required this.inlines,
    required this.start,
    required this.end,
    this.listMarker,
    this.depth = 0,
    this.align = TextAlign.start,
    this.quote = false,
  });

  final BlockKind kind;
  final List<InlineNode> inlines;

  /// Global offset of the first character / one past the last.
  final int start;
  final int end;
  final String? listMarker;
  final int depth;
  final TextAlign align;
  final bool quote;

  bool get hasBlanks => inlines.any((i) => i is BlankRun);

  String get text =>
      inlines.whereType<TextRun>().map((r) => r.text).join();
}

class TableBlock extends HtmlBlock {
  TableBlock(this.rows);
  final List<List<TableCellData>> rows;

  int get columnCount =>
      rows.fold(0, (m, r) => r.length > m ? r.length : m);
}

class TableCellData {
  TableCellData({required this.header, required this.blocks});
  final bool header;
  final List<HtmlBlock> blocks;
}

class ImageBlock extends HtmlBlock {
  ImageBlock(this.src, {this.width, this.height, this.alt});
  final String src;
  final double? width;
  final double? height;
  final String? alt;
}

sealed class InlineNode {
  const InlineNode();
}

class TextRun extends InlineNode {
  TextRun(this.text, this.style, this.start);
  final String text;
  final InlineStyle style;
  final int start;
  int get end => start + text.length;
}

class BlankRun extends InlineNode {
  BlankRun(this.index, this.marker, this.style);

  /// 0-based blank index within the document (maps to the n-th question).
  final int index;

  /// Original marker text, e.g. `{}` or `{1}`.
  final String marker;
  final InlineStyle style;
}

class InlineStyle {
  const InlineStyle({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.superscript = false,
    this.subscript = false,
  });

  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final bool superscript;
  final bool subscript;

  InlineStyle copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strike,
    bool? superscript,
    bool? subscript,
  }) =>
      InlineStyle(
        bold: bold ?? this.bold,
        italic: italic ?? this.italic,
        underline: underline ?? this.underline,
        strike: strike ?? this.strike,
        superscript: superscript ?? this.superscript,
        subscript: subscript ?? this.subscript,
      );

  @override
  bool operator ==(Object other) =>
      other is InlineStyle &&
      other.bold == bold &&
      other.italic == italic &&
      other.underline == underline &&
      other.strike == strike &&
      other.superscript == superscript &&
      other.subscript == subscript;

  @override
  int get hashCode =>
      Object.hash(bold, italic, underline, strike, superscript, subscript);
}

// ---------------------------------------------------------------------------

const _blockTags = {
  'p', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li', 'blockquote', 'pre',
  'section', 'article', 'header', 'footer', 'figure', 'figcaption', 'center',
  'dd', 'dt', 'address', 'main', 'aside', 'nav',
};

const _ignoredTags = {'script', 'style', 'head', 'title', 'meta', 'link', 'noscript', 'iframe', 'object', 'video', 'audio'};

/// Pending inline item before offsets are assigned.
class _Pending {
  _Pending.text(this.text, this.style)
      : blankMarker = null,
        blankIndex = null;
  _Pending.blank(this.blankIndex, this.blankMarker, this.style) : text = '';
  String text;
  final InlineStyle style;
  final String? blankMarker;
  final int? blankIndex;
  bool get isBlank => blankMarker != null;
}

class _BlockContext {
  _BlockContext({
    this.kind = BlockKind.paragraph,
    this.marker,
    this.depth = 0,
    this.align = TextAlign.start,
    this.quote = false,
  });
  BlockKind kind;
  String? marker;
  int depth;
  TextAlign align;
  bool quote;
}

class _Builder {
  _Builder(this.blankPattern);

  final RegExp? blankPattern;
  final StringBuffer text = StringBuffer();
  int offset = 0;
  int blankIndex = 0;
  int listDepth = 0;

  /// Stack of block lists (root, or the current table cell).
  final List<List<HtmlBlock>> _targets = [[]];
  List<HtmlBlock> get root => _targets.first;

  final List<_Pending> _pending = [];
  _BlockContext _ctx = _BlockContext();

  void walkChildren(List<dom.Node> nodes, InlineStyle style) {
    for (final n in nodes) {
      walk(n, style);
    }
  }

  void walk(dom.Node node, InlineStyle style) {
    if (node is dom.Text) {
      _addText(node.data, style);
      return;
    }
    if (node is! dom.Element) return;
    final tag = node.localName?.toLowerCase() ?? '';
    if (_ignoredTags.contains(tag)) return;

    switch (tag) {
      case 'br':
        _pending.add(_Pending.text('\n', style));
        return;
      case 'img':
        flush();
        final src = node.attributes['src'];
        if (src != null && src.isNotEmpty) {
          _targets.last.add(ImageBlock(
            src,
            width: _dimension(node, 'width'),
            height: _dimension(node, 'height'),
            alt: node.attributes['alt'],
          ));
        }
        return;
      case 'hr':
        flush();
        return;
      case 'table':
        flush();
        _table(node, style);
        return;
      case 'ul':
      case 'ol':
        flush();
        listDepth++;
        var index = int.tryParse(node.attributes['start'] ?? '') ?? 1;
        for (final child in node.nodes) {
          if (child is dom.Element && child.localName == 'li') {
            final marker = tag == 'ol' ? '$index.' : (listDepth.isOdd ? '•' : '◦');
            index++;
            _block(child, style, _BlockContext(
              kind: BlockKind.listItem,
              marker: marker,
              depth: listDepth,
              align: _align(child),
            ));
          } else {
            walk(child, style);
          }
        }
        flush();
        listDepth--;
        return;
    }

    final inlineStyle = _styleFor(tag, node, style);
    if (_blockTags.contains(tag)) {
      final kind = switch (tag) {
        'h1' => BlockKind.h1,
        'h2' => BlockKind.h2,
        'h3' => BlockKind.h3,
        'h4' || 'h5' || 'h6' => BlockKind.h4,
        'pre' => BlockKind.preformatted,
        'li' => BlockKind.listItem,
        _ => BlockKind.paragraph,
      };
      _block(node, inlineStyle, _BlockContext(
        kind: kind,
        depth: listDepth,
        align: _align(node),
        quote: tag == 'blockquote' || _ctx.quote,
      ));
      return;
    }
    walkChildren(node.nodes, inlineStyle);
  }

  void _block(dom.Element node, InlineStyle style, _BlockContext ctx) {
    flush();
    final saved = _ctx;
    _ctx = ctx;
    walkChildren(node.nodes, style);
    flush();
    _ctx = saved;
  }

  void _table(dom.Element table, InlineStyle style) {
    final rows = <List<TableCellData>>[];
    void collectRows(dom.Element e) {
      for (final child in e.children) {
        final t = child.localName;
        if (t == 'tr') {
          final cells = <TableCellData>[];
          for (final c in child.children) {
            if (c.localName == 'td' || c.localName == 'th') {
              final savedCtx = _ctx;
              final savedDepth = listDepth;
              _ctx = _BlockContext(align: _align(c));
              listDepth = 0;
              _targets.add([]);
              walkChildren(c.nodes, c.localName == 'th' ? style.copyWith(bold: true) : style);
              flush();
              final blocks = _targets.removeLast();
              _ctx = savedCtx;
              listDepth = savedDepth;
              cells.add(TableCellData(header: c.localName == 'th', blocks: blocks));
            }
          }
          if (cells.isNotEmpty) rows.add(cells);
        } else if (t == 'thead' || t == 'tbody' || t == 'tfoot') {
          collectRows(child);
        }
      }
    }

    collectRows(table);
    if (rows.isNotEmpty) _targets.last.add(TableBlock(rows));
  }

  void _addText(String raw, InlineStyle style) {
    if (raw.isEmpty) return;
    final pre = _ctx.kind == BlockKind.preformatted;
    final normalized = pre
        ? raw.replaceAll('\r\n', '\n')
        : raw.replaceAll(RegExp(r'[\s ]+'), ' ');
    final pattern = blankPattern;
    if (pattern == null) {
      _pending.add(_Pending.text(normalized, style));
      return;
    }
    var last = 0;
    for (final m in pattern.allMatches(normalized)) {
      if (m.start > last) {
        _pending.add(_Pending.text(normalized.substring(last, m.start), style));
      }
      _pending.add(_Pending.blank(blankIndex++, m.group(0)!, style));
      last = m.end;
    }
    if (last < normalized.length) {
      _pending.add(_Pending.text(normalized.substring(last), style));
    }
  }

  /// Turns the pending inline items into a [TextBlock] with offsets.
  void flush() {
    if (_pending.isEmpty) return;
    final pre = _ctx.kind == BlockKind.preformatted;
    if (!pre) {
      // Collapse whitespace across runs: no leading space, no double spaces,
      // no space right after a line break, no trailing whitespace.
      var prevSpace = true;
      for (final p in _pending) {
        if (p.isBlank) {
          prevSpace = false;
          continue;
        }
        var t = p.text;
        if (t == '\n') {
          prevSpace = true;
          continue;
        }
        if (prevSpace && t.startsWith(' ')) t = t.substring(1);
        if (t.isNotEmpty) prevSpace = t.endsWith(' ');
        p.text = t;
      }
      for (var i = _pending.length - 1; i >= 0; i--) {
        final p = _pending[i];
        if (p.isBlank) break;
        final trimmed = p.text.replaceAll(RegExp(r'[ \n]+$'), '');
        p.text = trimmed;
        if (trimmed.isNotEmpty) break;
      }
    }
    final items = _pending.where((p) => p.isBlank || p.text.isNotEmpty).toList();
    _pending.clear();
    if (items.isEmpty) return;

    final start = offset;
    final inlines = <InlineNode>[];
    for (final p in items) {
      if (p.isBlank) {
        inlines.add(BlankRun(p.blankIndex!, p.blankMarker!, p.style));
        continue;
      }
      // Merge with the previous run when the style is identical.
      final prev = inlines.isEmpty ? null : inlines.last;
      if (prev is TextRun && prev.style == p.style) {
        inlines[inlines.length - 1] = TextRun(prev.text + p.text, prev.style, prev.start);
      } else {
        inlines.add(TextRun(p.text, p.style, offset));
      }
      offset += p.text.length;
      text.write(p.text);
    }
    _targets.last.add(TextBlock(
      kind: _ctx.kind,
      inlines: inlines,
      start: start,
      end: offset,
      listMarker: _ctx.marker,
      depth: _ctx.depth,
      align: _ctx.align,
      quote: _ctx.quote,
    ));
    // Only the first block of a list item gets the marker.
    _ctx.marker = null;
  }

  static InlineStyle _styleFor(String tag, dom.Element node, InlineStyle s) {
    var out = switch (tag) {
      'strong' || 'b' => s.copyWith(bold: true),
      'em' || 'i' || 'cite' => s.copyWith(italic: true),
      'u' || 'ins' => s.copyWith(underline: true),
      's' || 'strike' || 'del' => s.copyWith(strike: true),
      'sup' => s.copyWith(superscript: true),
      'sub' => s.copyWith(subscript: true),
      'th' => s.copyWith(bold: true),
      'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6' => s.copyWith(bold: true),
      _ => s,
    };
    final style = node.attributes['style']?.toLowerCase();
    if (style != null && style.isNotEmpty) {
      if (RegExp(r'font-weight\s*:\s*(bold|[6-9]00)').hasMatch(style)) {
        out = out.copyWith(bold: true);
      }
      if (RegExp(r'font-style\s*:\s*italic').hasMatch(style)) {
        out = out.copyWith(italic: true);
      }
      if (RegExp(r'text-decoration[^;]*underline').hasMatch(style)) {
        out = out.copyWith(underline: true);
      }
      if (RegExp(r'text-decoration[^;]*line-through').hasMatch(style)) {
        out = out.copyWith(strike: true);
      }
    }
    return out;
  }

  static TextAlign _align(dom.Element node) {
    final style = node.attributes['style']?.toLowerCase() ?? '';
    final m = RegExp(r'text-align\s*:\s*(left|right|center|justify)').firstMatch(style);
    final v = m?.group(1) ?? node.attributes['align']?.toLowerCase();
    return switch (v) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      'justify' => TextAlign.justify,
      _ => TextAlign.start,
    };
  }

  static double? _dimension(dom.Element node, String name) {
    final attr = node.attributes[name];
    final fromAttr = attr == null ? null : double.tryParse(attr.replaceAll('px', ''));
    if (fromAttr != null) return fromAttr;
    final style = node.attributes['style'] ?? '';
    final m = RegExp('$name\\s*:\\s*([0-9.]+)px').firstMatch(style);
    return m == null ? null : double.tryParse(m.group(1)!);
  }
}

final Map<String, HtmlDocument> _parseCache = {};

/// Parses with a small memo cache (question widgets rebuild often).
HtmlDocument parseHtmlCached(String? html, {RegExp? blankPattern}) {
  final key = '${blankPattern?.pattern ?? ''}\u0000${html ?? ''}';
  final hit = _parseCache[key];
  if (hit != null) return hit;
  if (_parseCache.length > 400) _parseCache.clear();
  return _parseCache[key] = HtmlDocument.parse(html, blankPattern: blankPattern);
}

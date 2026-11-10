import 'dart:io';

import 'package:flutter/material.dart';

import 'html_document.dart';

/// A highlighted range over [HtmlDocument] offsets.
class HighlightRange {
  const HighlightRange(this.start, this.end, {this.isNote = false, this.id});
  final int start;
  final int end;
  final bool isNote;
  final Object? id;

  bool overlaps(int s, int e) => start < e && s < end;
}

/// A selection reported by [HtmlView] in document offsets.
class HtmlSelection {
  const HtmlSelection(this.start, this.end, this.text);
  final int start;
  final int end;
  final String text;
  bool get isCollapsed => start >= end;
}

typedef BlankBuilder = Widget Function(BuildContext context, BlankRun blank);

/// Resolves an `<img src>` to a provider (local cached file or network).
typedef ImageResolver = ImageProvider? Function(String src);

/// Renders an [HtmlDocument] with Flutter widgets (no webview).
///
/// * Text blocks are `SelectableText.rich` when [selectable] (and the block has
///   no inline widgets); selections are reported as document offsets.
/// * [highlights] paint background colours over offset ranges.
/// * Blanks are rendered inline with [blankBuilder].
class HtmlView extends StatefulWidget {
  const HtmlView({
    super.key,
    required this.document,
    this.style,
    this.highlights = const [],
    this.selectable = false,
    this.onSelectionChanged,
    this.blankBuilder,
    this.imageResolver,
    this.highlightColor = const Color(0x80FDE047),
    this.noteColor = const Color(0x8093C5FD),
    this.blockSpacing = 8,
  });

  final HtmlDocument document;
  final TextStyle? style;
  final List<HighlightRange> highlights;
  final bool selectable;
  final ValueChanged<HtmlSelection?>? onSelectionChanged;
  final BlankBuilder? blankBuilder;
  final ImageResolver? imageResolver;
  final Color highlightColor;
  final Color noteColor;
  final double blockSpacing;

  @override
  State<HtmlView> createState() => HtmlViewState();
}

class HtmlViewState extends State<HtmlView> {
  /// Block (by start offset) that currently holds the selection.
  int? _activeBlock;

  /// Bumped to rebuild (and thereby clear) selectable blocks.
  int _generation = 0;

  /// Clears any visible selection.
  void clearSelection() {
    setState(() {
      _generation++;
      _activeBlock = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(widget.style);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: _blocks(context, widget.document.blocks, base),
    );
  }

  List<Widget> _blocks(BuildContext context, List<HtmlBlock> blocks, TextStyle base) {
    final out = <Widget>[];
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final w = switch (b) {
        TextBlock() => _textBlock(context, b, base),
        TableBlock() => _table(context, b, base),
        ImageBlock() => _image(b),
      };
      out.add(Padding(
        padding: EdgeInsets.only(bottom: i == blocks.length - 1 ? 0 : widget.blockSpacing),
        child: w,
      ));
    }
    return out;
  }

  TextStyle _blockStyle(TextBlock b, TextStyle base) {
    final size = base.fontSize ?? 14;
    return switch (b.kind) {
      BlockKind.h1 => base.copyWith(fontSize: size * 1.6, fontWeight: FontWeight.bold),
      BlockKind.h2 => base.copyWith(fontSize: size * 1.4, fontWeight: FontWeight.bold),
      BlockKind.h3 => base.copyWith(fontSize: size * 1.2, fontWeight: FontWeight.bold),
      BlockKind.h4 => base.copyWith(fontSize: size * 1.1, fontWeight: FontWeight.bold),
      BlockKind.preformatted => base.copyWith(fontFamily: 'monospace'),
      _ => base,
    };
  }

  /// Builds the span tree of a text block, splitting runs at highlight edges.
  InlineSpan buildSpan(BuildContext context, TextBlock block, TextStyle style) {
    final children = <InlineSpan>[];
    final relevant = widget.highlights
        .where((h) => h.overlaps(block.start, block.end))
        .toList();
    for (final node in block.inlines) {
      switch (node) {
        case TextRun():
          final runStyle = applyInlineStyle(style, node.style);
          if (relevant.isEmpty) {
            children.add(TextSpan(text: node.text, style: runStyle));
            continue;
          }
          final cuts = <int>{node.start, node.end};
          for (final h in relevant) {
            if (h.start > node.start && h.start < node.end) cuts.add(h.start);
            if (h.end > node.start && h.end < node.end) cuts.add(h.end);
          }
          final sorted = cuts.toList()..sort();
          for (var i = 0; i < sorted.length - 1; i++) {
            final s = sorted[i];
            final e = sorted[i + 1];
            final text = node.text.substring(s - node.start, e - node.start);
            HighlightRange? hit;
            for (final h in relevant) {
              if (h.start <= s && h.end >= e) {
                if (hit == null || h.isNote) hit = h;
              }
            }
            children.add(TextSpan(
              text: text,
              style: hit == null
                  ? runStyle
                  : runStyle.copyWith(
                      backgroundColor: hit.isNote ? widget.noteColor : widget.highlightColor,
                      decoration: hit.isNote ? TextDecoration.underline : runStyle.decoration,
                      decorationColor: hit.isNote ? const Color(0xFF2563EB) : null,
                    ),
            ));
          }
        case BlankRun():
          final builder = widget.blankBuilder;
          children.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: builder == null
                ? Text(node.marker, style: style)
                : builder(context, node),
          ));
      }
    }
    return TextSpan(style: style, children: children);
  }

  Widget _textBlock(BuildContext context, TextBlock b, TextStyle base) {
    final style = _blockStyle(b, base);
    final span = buildSpan(context, b, style);
    final Widget text;
    if (widget.selectable && !b.hasBlanks) {
      text = SelectableText.rich(
        span as TextSpan,
        key: ValueKey('blk-${b.start}-$_generation'),
        textAlign: b.align,
        onSelectionChanged: (sel, cause) => _onBlockSelection(b, sel),
      );
    } else {
      text = Text.rich(span, textAlign: b.align);
    }
    Widget out = text;
    if (b.listMarker != null || b.kind == BlockKind.listItem) {
      out = Padding(
        padding: EdgeInsets.only(left: 18.0 * (b.depth - 1).clamp(0, 6)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 24, child: Text(b.listMarker ?? '', style: style)),
            Expanded(child: text),
          ],
        ),
      );
    }
    if (b.quote) {
      out = Container(
        padding: const EdgeInsets.only(left: 12),
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Color(0xFFD1D5DB), width: 3)),
        ),
        child: out,
      );
    }
    return out;
  }

  void _onBlockSelection(TextBlock b, TextSelection sel) {
    final cb = widget.onSelectionChanged;
    if (_activeBlock != null && _activeBlock != b.start) {
      // Selection moved to another block: clear the old one on next frame.
      final old = _activeBlock;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && old != null && _activeBlock != old) setState(() => _generation++);
      });
    }
    _activeBlock = b.start;
    if (cb == null) return;
    if (!sel.isValid || sel.isCollapsed) {
      cb(null);
      return;
    }
    final s = b.start + sel.start;
    final e = b.start + sel.end;
    cb(HtmlSelection(s, e, widget.document.textInRange(s, e)));
  }

  Widget _table(BuildContext context, TableBlock t, TextStyle base) {
    final cols = t.columnCount;
    const border = BorderSide(color: Color(0xFF9CA3AF));
    return Table(
      border: const TableBorder(
        top: border, bottom: border, left: border, right: border,
        horizontalInside: border, verticalInside: border,
      ),
      defaultColumnWidth: const FlexColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: [
        for (final row in t.rows)
          TableRow(
            decoration: row.every((c) => c.header)
                ? const BoxDecoration(color: Color(0x0F000000))
                : null,
            children: [
              for (var c = 0; c < cols; c++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: c < row.length
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: _blocks(context, row[c].blocks, base),
                        )
                      : const SizedBox.shrink(),
                ),
            ],
          ),
      ],
    );
  }

  Widget _image(ImageBlock b) {
    final provider = widget.imageResolver?.call(b.src) ?? _defaultProvider(b.src);
    if (provider == null) {
      return Text('[image: ${b.alt ?? b.src}]');
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: b.width ?? double.infinity),
        child: Image(
          image: provider,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFFF3F4F6),
            child: Text('[image unavailable${b.alt == null ? '' : ': ${b.alt}'}]'),
          ),
        ),
      ),
    );
  }

  static ImageProvider? _defaultProvider(String src) {
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return NetworkImage(src);
    }
    if (src.startsWith('file://')) return FileImage(File(Uri.parse(src).toFilePath()));
    return null;
  }
}

/// Applies an [InlineStyle] on top of a base [TextStyle].
TextStyle applyInlineStyle(TextStyle base, InlineStyle s) {
  var out = base;
  if (s.bold) out = out.copyWith(fontWeight: FontWeight.bold);
  if (s.italic) out = out.copyWith(fontStyle: FontStyle.italic);
  final decorations = <TextDecoration>[
    if (s.underline) TextDecoration.underline,
    if (s.strike) TextDecoration.lineThrough,
  ];
  if (decorations.isNotEmpty) {
    out = out.copyWith(decoration: TextDecoration.combine(decorations));
  }
  if (s.superscript || s.subscript) {
    out = out.copyWith(
      fontSize: (base.fontSize ?? 14) * 0.7,
      fontFeatures: [s.superscript ? const FontFeature.superscripts() : const FontFeature.subscripts()],
    );
  }
  return out;
}

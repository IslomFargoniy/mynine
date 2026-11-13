import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme.dart';
import '../../core/theme/web_tokens.dart';
import '../../data/db/app_database.dart';
import 'html_document.dart';
import 'html_view.dart';
import 'passage_slots.dart';

/// Highlights + notes of one part, persisted in SQLite.
class HighlightStore extends ChangeNotifier {
  HighlightStore(this.db, this.attemptId);

  final AppDatabase db;
  final int attemptId;
  final Map<int, List<HighlightRow>> _highlights = {};
  final Map<int, List<NoteRow>> _notes = {};

  List<HighlightRow> highlights(int partId) => _highlights[partId] ?? const [];
  List<NoteRow> notes(int partId) => _notes[partId] ?? const [];

  Future<void> load(int partId) async {
    _highlights[partId] = await (db.select(db.highlights)
          ..where((t) => t.attemptId.equals(attemptId) & t.partId.equals(partId)))
        .get();
    _notes[partId] = await (db.select(db.candidateNotes)
          ..where((t) => t.attemptId.equals(attemptId) & t.partId.equals(partId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    notifyListeners();
  }

  Future<void> addHighlight(int partId, int start, int end, {String? noteId}) async {
    await db.into(db.highlights).insert(HighlightsCompanion.insert(
          attemptId: attemptId,
          partId: partId,
          startOffset: start,
          endOffset: end,
          kind: Value(noteId == null ? 'highlight' : 'note'),
          noteId: Value(noteId),
        ));
    await load(partId);
  }

  /// Removes every mark overlapping [start, end) (web: Clear unwraps all
  /// `mark.highlight`, note marks included; the note itself stays).
  Future<void> clearRange(int partId, int start, int end) async {
    await (db.delete(db.highlights)
          ..where((t) =>
              t.attemptId.equals(attemptId) &
              t.partId.equals(partId) &
              t.startOffset.isSmallerThanValue(end) &
              t.endOffset.isBiggerThanValue(start)))
        .go();
    await load(partId);
  }

  /// [docId]: the highlighted document when it is not the passage itself (a question / section text in the
  /// questions pane, see [questionDocId]); the note is listed under [partId] either way.
  Future<void> addNote(int partId, int start, int end, String quote, String note, {int? docId}) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await db.into(db.candidateNotes).insert(CandidateNotesCompanion.insert(
          id: id,
          attemptId: attemptId,
          partId: partId,
          quote: quote,
          note: note,
        ));
    await addHighlight(docId ?? partId, start, end, noteId: id);
    if (docId != null) await load(partId);
  }

  Future<void> deleteNote(int partId, String noteId) async {
    await (db.delete(db.candidateNotes)..where((t) => t.id.equals(noteId))).go();
    await (db.delete(db.highlights)..where((t) => t.noteId.equals(noteId))).go();
    // The note's mark may sit in a question text (another doc id): reload every loaded document.
    for (final id in {partId, ..._highlights.keys}) {
      await load(id);
    }
  }
}

/// Highlight document id of a question / section text in the questions pane. Negative, so it never meets a
/// real part id in the same `highlights` table (no schema change).
int questionDocId({int? sectionId, int? questionId}) =>
    sectionId != null ? -(sectionId * 2 + 1) : -(questionId! * 2 + 2);

/// practice-part.tsx: part title, "Candidate Notes (n)" button, passage with
/// the Inspera floating toolbar (Note|Clear / Highlight) and the note dialog.
/// Highlights are stored as character offsets.
class PassagePane extends StatefulWidget {
  const PassagePane({
    super.key,
    required this.partId,
    required this.title,
    required this.html,
    required this.store,
    required this.palette,
    this.onToggleNotes,
    this.imageResolver,
    this.slotNumbers = const {},
    this.slotBuilder,
  });

  final int partId;
  final String title;
  final String html;
  final HighlightStore store;
  final ExamPalette palette;
  final VoidCallback? onToggleNotes;
  final ImageResolver? imageResolver;

  /// Question numbers with a heading box (`{14}`) in the passage ([passageSlots]), built by [slotBuilder].
  final Set<int> slotNumbers;
  final Widget Function(BuildContext context, int number)? slotBuilder;

  @override
  State<PassagePane> createState() => _PassagePaneState();
}

class _PassagePaneState extends State<PassagePane> {
  final _viewKey = GlobalKey<HtmlViewState>();
  HtmlSelection? _selection;
  Offset? _toolbarAt;
  Offset? _lastPointerUp;

  @override
  void initState() {
    super.initState();
    unawaited(widget.store.load(widget.partId));
  }

  @override
  void didUpdateWidget(covariant PassagePane old) {
    super.didUpdateWidget(old);
    if (old.partId != widget.partId) {
      _selection = null;
      _toolbarAt = null;
      unawaited(widget.store.load(widget.partId));
    }
  }

  List<HighlightRange> get _ranges => [
        for (final h in widget.store.highlights(widget.partId))
          HighlightRange(h.startOffset, h.endOffset, isNote: h.kind == 'note', id: h.id),
      ];

  bool get _selectionHighlighted {
    final s = _selection;
    if (s == null) return false;
    return _ranges.any((r) => r.overlaps(s.start, s.end));
  }

  void _onSelection(HtmlSelection? s) {
    _selection = (s == null || s.isCollapsed) ? null : s;
    if (_selection == null && _toolbarAt != null) setState(() => _toolbarAt = null);
  }

  void _onPointerUp(PointerUpEvent e) {
    _lastPointerUp = e.localPosition;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _toolbarAt = _selection == null ? null : _lastPointerUp);
    });
  }

  void _dismiss() {
    _viewKey.currentState?.clearSelection();
    setState(() {
      _selection = null;
      _toolbarAt = null;
    });
  }

  Future<void> _highlight() async {
    final s = _selection;
    if (s == null) return;
    await widget.store.addHighlight(widget.partId, s.start, s.end);
    _dismiss();
  }

  Future<void> _clear() async {
    final s = _selection;
    if (s == null) return;
    await widget.store.clearRange(widget.partId, s.start, s.end);
    _dismiss();
  }

  Future<void> _note() async {
    final s = _selection;
    if (s == null) return;
    setState(() => _toolbarAt = null);
    final text = await showDialog<String>(
      context: context,
      barrierColor: const Color(0x66000000), // bg-black/40
      builder: (_) => _NoteDialog(quote: s.text.trim()),
    );
    if (text != null) {
      await widget.store.addNote(widget.partId, s.start, s.end, s.text.trim(), text.trim());
    }
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final slotBuilder = widget.slotBuilder;
    final hasSlots = widget.slotNumbers.isNotEmpty && slotBuilder != null;
    final doc = hasSlots
        ? parseHtmlCached(hoistPassageMarkers(widget.html), blankPattern: passageSlotPattern)
        : parseHtmlCached(widget.html);
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final notes = widget.store.notes(widget.partId);
        return Stack(children: [
          Listener(
            onPointerUp: _onPointerUp,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(WebTokens.panePadding),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Expanded(
                    child: Text(widget.title,
                        style: inter(WebTokens.partTitleSize,
                            weight: FontWeight.w700, color: p.standard ? WebTokens.partTitleColor : p.text)),
                  ),
                  if (notes.isNotEmpty && widget.onToggleNotes != null)
                    _NotesButton(count: notes.length, onTap: widget.onToggleNotes!),
                ]),
                const SizedBox(height: 12), // mb-3
                HtmlView(
                  key: _viewKey,
                  document: doc,
                  selectable: true,
                  highlights: _ranges,
                  highlightColor: p.highlight,
                  noteColor: p.note,
                  imageResolver: widget.imageResolver,
                  onSelectionChanged: _onSelection,
                  blankBuilder: hasSlots
                      ? (context, blank) {
                          final n = passageSlotNumber(blank.marker);
                          return n != null && widget.slotNumbers.contains(n)
                              ? slotBuilder(context, n)
                              : Text(blank.marker);
                        }
                      : null,
                  blockSpacing: WebTokens.passageFontSize * 1.25, // prose p margin 1.25em
                  tableHeaderColor: p.standard ? WebTokens.tableHeaderBg : null,
                  tableBorderColor: p.standard ? WebTokens.tableBorder : p.text,
                  style: inter(WebTokens.passageFontSize,
                      height: WebTokens.proseLineHeight, color: p.standard ? WebTokens.passageText : p.text),
                ),
              ]),
            ),
          ),
          if (_toolbarAt != null)
            Positioned(
              left: (_toolbarAt!.dx - 45).clamp(10.0, double.infinity),
              top: (_toolbarAt!.dy - 52).clamp(10.0, double.infinity),
              child: HighlightToolbar(
                highlighted: _selectionHighlighted,
                onHighlight: _highlight,
                onNote: _note,
                onClear: _clear,
              ),
            ),
        ]);
      },
    );
  }
}

/// `Candidate Notes (n)` button (`bg-amber-50 border-amber-300 text-amber-900 text-xs font-semibold`).
class _NotesButton extends StatelessWidget {
  const _NotesButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: WebTokens.notesBtnBg,
            border: Border.all(color: WebTokens.notesBtnBorder),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.stickyNote, size: 14, color: WebTokens.notesBtnIcon),
            const SizedBox(width: 6),
            Text('Candidate Notes ($count)',
                style: inter(12, weight: FontWeight.w600, color: WebTokens.notesBtnText)),
          ]),
        ),
      );
}

/// Inspera floating toolbar (white card: Note|Clear, divider, Highlight).
class HighlightToolbar extends StatelessWidget {
  const HighlightToolbar({
    super.key,
    required this.highlighted,
    required this.onHighlight,
    required this.onNote,
    required this.onClear,
  });

  final bool highlighted;
  final VoidCallback onHighlight;
  final VoidCallback onNote;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    Widget btn(Key key, IconData icon, String label, VoidCallback onTap, Color color, double minWidth) => InkWell(
          key: key,
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            constraints: BoxConstraints(minWidth: minWidth),
            padding: const EdgeInsets.all(4),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(height: 2),
              Text(label, style: inter(9, weight: FontWeight.w600, color: color, letterSpacing: -0.4)),
            ]),
          ),
        );
    return Material(
      color: Colors.white,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: WebTokens.toolbarBorder),
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(color: Color(0x1A000000), blurRadius: 25, offset: Offset(0, 20), spreadRadius: -5),
            BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 8), spreadRadius: -6),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          highlighted
              ? btn(const Key('tb-clear'), LucideIcons.trash2, 'CLEAR', onClear, WebTokens.toolbarClear, 34)
              : btn(const Key('tb-note'), LucideIcons.fileText, 'NOTE', onNote, WebTokens.toolbarText, 34),
          const SizedBox(width: 6),
          Container(width: 1, height: 24, color: WebTokens.toolbarDivider),
          const SizedBox(width: 6),
          btn(const Key('tb-highlight'), LucideIcons.highlighter, 'HIGHLIGHT', onHighlight, WebTokens.toolbarText, 42),
        ]),
      ),
    );
  }
}

/// "Add Candidate Note" dialog (practice-part.tsx).
class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.quote});
  final String quote;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: TW.gray300),
        ),
        child: SizedBox(
          width: WebTokens.modalMaxWidth,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                padding: const EdgeInsets.only(bottom: 8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: TW.gray200))),
                child: Row(children: [
                  const Icon(LucideIcons.fileText, size: 16, color: TW.blue600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Add Candidate Note', style: inter(14, weight: FontWeight.w700, color: TW.gray900)),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(LucideIcons.x, size: 16, color: TW.gray400),
                  ),
                ]),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                constraints: const BoxConstraints(maxHeight: 96),
                decoration: BoxDecoration(
                  color: TW.gray50,
                  border: Border.all(color: TW.gray200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  child: Text('"${widget.quote}"',
                      style: inter(12, color: TW.gray700, style: FontStyle.italic)),
                ),
              ),
              TextField(
                controller: _c,
                autofocus: true,
                minLines: 3,
                maxLines: 3,
                autocorrect: false,
                style: inter(12, color: TW.gray900),
                decoration: InputDecoration(
                  hintText: 'Type your notes here...',
                  hintStyle: inter(12, color: TW.gray400),
                  contentPadding: const EdgeInsets.all(8),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: TW.gray300)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: TW.blue600)),
                ),
              ),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                _SmallButton(label: 'Cancel', onTap: () => Navigator.pop(context)),
                const SizedBox(width: 8),
                _SmallButton(
                  label: 'Save Note',
                  primary: true,
                  onTap: () => Navigator.pop(context, _c.text),
                ),
              ]),
            ]),
          ),
        ),
      );
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.label, required this.onTap, this.primary = false});
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: primary ? TW.blue600 : Colors.white,
            border: primary ? null : Border.all(color: TW.gray300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label,
              style: inter(12, weight: primary ? FontWeight.w600 : FontWeight.w400, color: primary ? Colors.white : TW.gray900)),
        ),
      );
}

/// Right-side "Candidate Notes" drawer (practice-part.tsx).
class NotesDrawer extends StatelessWidget {
  const NotesDrawer({super.key, required this.store, required this.partId, required this.onClose});

  final HighlightStore store;
  final int partId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: WebTokens.drawerWidth,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: TW.gray300)),
        boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 50, offset: Offset(0, 25), spreadRadius: -12)],
      ),
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final notes = store.notes(partId);
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              color: WebTokens.drawerHeader,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                const Icon(LucideIcons.stickyNote, color: TW.amber400, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Candidate Notes (${notes.length})',
                      style: inter(14, weight: FontWeight.w700, color: Colors.white)),
                ),
                InkWell(onTap: onClose, child: const Icon(LucideIcons.x, color: TW.gray400, size: 16)),
              ]),
            ),
            Expanded(
              child: Container(
                color: WebTokens.drawerListBg,
                child: notes.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                        child: Column(children: [
                          const Icon(LucideIcons.fileText, size: 32, color: Color(0x8099A1AF)),
                          const SizedBox(height: 8),
                          Text('No candidate notes yet',
                              style: inter(12, weight: FontWeight.w600, color: TW.gray600)),
                          const SizedBox(height: 4),
                          Text.rich(
                            TextSpan(style: inter(12, color: TW.gray400), children: [
                              const TextSpan(text: 'Select any text and click '),
                              TextSpan(text: '"Note"', style: inter(12, weight: FontWeight.w700, color: TW.gray700)),
                              const TextSpan(text: ' to save your notes.'),
                            ]),
                            textAlign: TextAlign.center,
                          ),
                        ]),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: notes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final n = notes[i];
                          final t = n.createdAt.toLocal();
                          final time = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: TW.gray200),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: TW.amber50,
                                  border: Border(left: BorderSide(color: TW.amber400, width: 3)),
                                ),
                                child: Text('"${n.quote}"',
                                    style: inter(12, color: TW.gray800, style: FontStyle.italic)),
                              ),
                              const SizedBox(height: 8),
                              n.note.isEmpty
                                  ? Text('No notes written',
                                      style: inter(12, color: TW.gray400, style: FontStyle.italic))
                                  : Text(n.note, style: inter(12, weight: FontWeight.w500, color: TW.gray700)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.only(top: 8),
                                decoration: const BoxDecoration(border: Border(top: BorderSide(color: TW.gray100))),
                                child: Row(children: [
                                  Expanded(child: Text(time, style: inter(10, color: TW.gray400))),
                                  InkWell(
                                    onTap: () => store.deleteNote(partId, n.id),
                                    child: Row(children: [
                                      const Icon(LucideIcons.trash2, size: 12, color: TW.red500),
                                      const SizedBox(width: 4),
                                      Text('Delete', style: inter(10, weight: FontWeight.w600, color: TW.red500)),
                                    ]),
                                  ),
                                ]),
                              ),
                            ]),
                          );
                        },
                      ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}


/// An [HtmlView] in the questions pane with the passage's Highlight / Note / Clear toolbar (Listening and
/// Writing questions too). Marks are stored under [docId]; notes under [notePartId] (the drawer lists them).
/// Text blocks that contain answer boxes stay plain (not selectable).
class SelectableHtml extends StatefulWidget {
  const SelectableHtml({
    super.key,
    required this.store,
    required this.docId,
    required this.notePartId,
    required this.document,
    required this.style,
    required this.highlightColor,
    required this.noteColor,
    this.blankBuilder,
    this.imageResolver,
    this.inlineParagraphs = false,
    this.blockSpacing = 6,
    this.tableHeaderColor,
    this.tableBorderColor = WebTokens.tableBorder,
  });

  final HighlightStore store;
  final int docId;
  final int notePartId;
  final HtmlDocument document;
  final TextStyle style;
  final Color highlightColor;
  final Color noteColor;
  final BlankBuilder? blankBuilder;
  final ImageResolver? imageResolver;
  final bool inlineParagraphs;
  final double blockSpacing;
  final Color? tableHeaderColor;
  final Color tableBorderColor;

  @override
  State<SelectableHtml> createState() => _SelectableHtmlState();
}

class _SelectableHtmlState extends State<SelectableHtml> {
  final _viewKey = GlobalKey<HtmlViewState>();
  final _toolbar = OverlayPortalController();
  HtmlSelection? _selection;
  Offset _at = Offset.zero;

  @override
  void initState() {
    super.initState();
    unawaited(widget.store.load(widget.docId));
    if (widget.store.notes(widget.notePartId).isEmpty) unawaited(widget.store.load(widget.notePartId));
  }

  @override
  void didUpdateWidget(covariant SelectableHtml old) {
    super.didUpdateWidget(old);
    if (old.docId != widget.docId) unawaited(widget.store.load(widget.docId));
  }

  List<HighlightRange> get _ranges => [
        for (final h in widget.store.highlights(widget.docId))
          HighlightRange(h.startOffset, h.endOffset, isNote: h.kind == 'note', id: h.id),
      ];

  void _onSelection(HtmlSelection? s) {
    _selection = (s == null || s.isCollapsed) ? null : s;
    if (_selection == null && _toolbar.isShowing) _toolbar.hide();
  }

  void _onPointerUp(PointerUpEvent e) {
    final at = e.position;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_selection == null) {
        _toolbar.hide();
      } else {
        setState(() => _at = at);
        _toolbar.show();
      }
    });
  }

  void _dismiss() {
    _viewKey.currentState?.clearSelection();
    _selection = null;
    _toolbar.hide();
  }

  Future<void> _highlight() async {
    final s = _selection;
    if (s == null) return;
    await widget.store.addHighlight(widget.docId, s.start, s.end);
    _dismiss();
  }

  Future<void> _clear() async {
    final s = _selection;
    if (s == null) return;
    await widget.store.clearRange(widget.docId, s.start, s.end);
    _dismiss();
  }

  Future<void> _note() async {
    final s = _selection;
    if (s == null) return;
    _toolbar.hide();
    final text = await showDialog<String>(
      context: context,
      barrierColor: const Color(0x66000000),
      builder: (_) => _NoteDialog(quote: s.text.trim()),
    );
    if (text != null) {
      await widget.store.addNote(widget.notePartId, s.start, s.end, s.text.trim(), text.trim(), docId: widget.docId);
    }
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _toolbar,
      overlayChildBuilder: (context) {
        final s = _selection;
        return Positioned(
          left: (_at.dx - 45).clamp(10.0, double.infinity),
          top: (_at.dy - 52).clamp(10.0, double.infinity),
          child: TapRegion(
            onTapOutside: (_) => _toolbar.hide(),
            child: HighlightToolbar(
              highlighted: s != null && _ranges.any((r) => r.overlaps(s.start, s.end)),
              onHighlight: _highlight,
              onNote: _note,
              onClear: _clear,
            ),
          ),
        );
      },
      child: Listener(
        onPointerUp: _onPointerUp,
        child: ListenableBuilder(
          listenable: widget.store,
          builder: (context, _) => HtmlView(
            key: _viewKey,
            document: widget.document,
            style: widget.style,
            selectable: true,
            highlights: _ranges,
            highlightColor: widget.highlightColor,
            noteColor: widget.noteColor,
            onSelectionChanged: _onSelection,
            blankBuilder: widget.blankBuilder,
            imageResolver: widget.imageResolver,
            inlineParagraphs: widget.inlineParagraphs,
            blockSpacing: widget.blockSpacing,
            tableHeaderColor: widget.tableHeaderColor,
            tableBorderColor: widget.tableBorderColor,
          ),
        ),
      ),
    );
  }
}

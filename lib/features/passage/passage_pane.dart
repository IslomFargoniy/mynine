import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/db/app_database.dart';
import 'html_document.dart';
import 'html_view.dart';

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

  /// Removes every plain highlight overlapping [start, end).
  Future<void> clearRange(int partId, int start, int end) async {
    await (db.delete(db.highlights)
          ..where((t) =>
              t.attemptId.equals(attemptId) &
              t.partId.equals(partId) &
              t.kind.equals('highlight') &
              t.startOffset.isSmallerThanValue(end) &
              t.endOffset.isBiggerThanValue(start)))
        .go();
    await load(partId);
  }

  Future<void> addNote(int partId, int start, int end, String quote, String note) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await db.into(db.candidateNotes).insert(CandidateNotesCompanion.insert(
          id: id,
          attemptId: attemptId,
          partId: partId,
          quote: quote,
          note: note,
        ));
    await addHighlight(partId, start, end, noteId: id);
  }

  Future<void> deleteNote(int partId, String noteId) async {
    await (db.delete(db.candidateNotes)..where((t) => t.id.equals(noteId))).go();
    await (db.delete(db.highlights)..where((t) => t.noteId.equals(noteId))).go();
    await load(partId);
  }
}

/// Passage with Inspera-style highlighter: select text → floating toolbar
/// (Highlight / Note / Clear). Highlights are stored as character offsets.
class PassagePane extends StatefulWidget {
  const PassagePane({
    super.key,
    required this.partId,
    required this.title,
    required this.html,
    required this.store,
    required this.palette,
    required this.fontSize,
    this.imageResolver,
  });

  final int partId;
  final String title;
  final String html;
  final HighlightStore store;
  final ExamPalette palette;
  final double fontSize;
  final ImageResolver? imageResolver;

  @override
  State<PassagePane> createState() => _PassagePaneState();
}

class _PassagePaneState extends State<PassagePane> {
  final _viewKey = GlobalKey<HtmlViewState>();
  final _stackKey = GlobalKey();
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
    return _ranges.any((r) => !r.isNote && r.overlaps(s.start, s.end));
  }

  void _onSelection(HtmlSelection? s) {
    _selection = (s == null || s.isCollapsed) ? null : s;
    if (_selection == null && _toolbarAt != null) setState(() => _toolbarAt = null);
  }

  void _onPointerUp(PointerUpEvent e) {
    _lastPointerUp = e.localPosition;
    // Selection callbacks arrive during the gesture; decide after this frame.
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
      builder: (_) => _NoteDialog(quote: s.text),
    );
    if (text != null) {
      await widget.store.addNote(widget.partId, s.start, s.end, s.text.trim(), text.trim());
    }
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final doc = parseHtmlCached(widget.html);
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) => Stack(
        key: _stackKey,
        children: [
          Listener(
            onPointerUp: _onPointerUp,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(widget.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: widget.fontSize + 3, color: p.text)),
                const SizedBox(height: 12),
                HtmlView(
                  key: _viewKey,
                  document: doc,
                  selectable: true,
                  highlights: _ranges,
                  highlightColor: p.highlight,
                  noteColor: p.note,
                  imageResolver: widget.imageResolver,
                  onSelectionChanged: _onSelection,
                  style: TextStyle(fontSize: widget.fontSize, height: 1.7, color: p.text),
                ),
              ]),
            ),
          ),
          if (_toolbarAt != null)
            Positioned(
              left: (_toolbarAt!.dx - 60).clamp(8.0, double.infinity),
              top: (_toolbarAt!.dy - 64).clamp(8.0, double.infinity),
              child: _Toolbar(
                highlighted: _selectionHighlighted,
                onHighlight: _highlight,
                onNote: _note,
                onClear: _clear,
              ),
            ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.highlighted, required this.onHighlight, required this.onNote, required this.onClear});

  final bool highlighted;
  final VoidCallback onHighlight;
  final VoidCallback onNote;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    Widget btn(Key key, IconData icon, String label, VoidCallback onTap, {Color? color}) => InkWell(
          key: key,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 16, color: color ?? AppColors.ink),
              Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color ?? AppColors.ink)),
            ]),
          ),
        );
    return Material(
      elevation: 6,
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        highlighted
            ? btn(const Key('tb-clear'), Icons.delete_outline, 'CLEAR', onClear, color: Colors.red)
            : btn(const Key('tb-note'), Icons.sticky_note_2_outlined, 'NOTE', onNote),
        Container(width: 1, height: 26, color: AppColors.border),
        btn(const Key('tb-highlight'), Icons.border_color, 'HIGHLIGHT', onHighlight),
      ]),
    );
  }
}

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
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Add note'),
        content: SizedBox(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.all(8),
              color: AppColors.panel,
              constraints: const BoxConstraints(maxHeight: 100),
              child: SingleChildScrollView(
                child: Text('"${widget.quote}"', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _c,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              autocorrect: false,
              decoration: const InputDecoration(hintText: 'Type your note…'),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, _c.text), child: const Text('Save note')),
        ],
      );
}

/// Right-side drawer listing the candidate's notes for the current part.
class NotesDrawer extends StatelessWidget {
  const NotesDrawer({super.key, required this.store, required this.partId, required this.onClose});

  final HighlightStore store;
  final int partId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      color: Colors.white,
      child: SizedBox(
        width: 340,
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final notes = store.notes(partId);
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                color: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(children: [
                  const Icon(Icons.sticky_note_2, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Candidate notes (${notes.length})',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(onPressed: onClose, icon: const Icon(Icons.close, color: Colors.white, size: 18)),
                ]),
              ),
              Expanded(
                child: notes.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No notes yet. Select text in the passage and click "Note".',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.grey),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          for (final n in notes)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    color: const Color(0xFFFFFBEB),
                                    child: Text('"${n.quote}"',
                                        style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(n.note.isEmpty ? 'No note written' : n.note, style: const TextStyle(fontSize: 13)),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => store.deleteNote(partId, n.id),
                                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                        ],
                      ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

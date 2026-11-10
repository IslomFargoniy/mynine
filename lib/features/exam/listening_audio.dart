import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import '../../core/time/server_clock.dart';
import '../../data/models/exam_models.dart';
import '../sound_check/sound_check_screen.dart' show listeningVolume;

/// Where the recording should be now, from the server timer:
/// elapsed = duration_seconds − remaining (mirrors the web AudioEqualizer,
/// so a restarted PC or a resumed pause continues at the right place).
Duration listeningPosition(ExamModule module, ServerClock clock) {
  final finished = module.finishedAt;
  if (finished == null) return Duration.zero;
  if (module.durationSeconds > 0) {
    final elapsed = Duration(seconds: module.durationSeconds) - clock.remaining(finished);
    return elapsed.isNegative ? Duration.zero : elapsed;
  }
  final started = module.startedAt;
  if (started == null) return Duration.zero;
  final e = clock.now().difference(started.toUtc());
  return e.isNegative ? Duration.zero : e;
}

/// Plays the cached Listening recording once, without pause/seek controls.
/// Shows a small level indicator and a volume slider.
class ListeningAudio extends StatefulWidget {
  const ListeningAudio({
    super.key,
    required this.file,
    required this.module,
    required this.clock,
    required this.paused,
  });

  final String file;
  final ExamModule module;
  final ServerClock clock;
  final bool paused;

  @override
  State<ListeningAudio> createState() => _ListeningAudioState();
}

class _ListeningAudioState extends State<ListeningAudio> {
  Player? _p;
  StreamSubscription<bool>? _playingSub;
  bool _playing = false;
  bool _ended = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    listeningVolume.addListener(_applyVolume);
    unawaited(_start());
  }

  void _applyVolume() => _p?.setVolume(listeningVolume.value);

  Future<void> _start() async {
    try {
      if (!await File(widget.file).exists()) {
        setState(() => _error = 'Audio file missing');
        return;
      }
      // Created lazily: throws if libmpv is not bundled (e.g. macOS dev
      // build without media_kit_libs_macos_audio).
      final player = _p = Player();
      _playingSub = player.stream.playing.listen((v) {
        if (mounted) setState(() => _playing = v);
      });
      player.stream.completed.listen((done) {
        if (done && mounted) setState(() => _ended = true);
      });
      await player.setVolume(listeningVolume.value);
      await player.open(Media(File(widget.file).uri.toString()), play: false);
      final duration = await player.stream.duration
          .firstWhere((d) => d > Duration.zero)
          .timeout(const Duration(seconds: 10), onTimeout: () => Duration.zero);
      await _sync(duration);
    } catch (e) {
      if (mounted) setState(() => _error = 'Audio error');
    }
  }

  Future<void> _sync([Duration? knownDuration]) async {
    final player = _p;
    if (player == null) return;
    if (widget.paused) {
      await player.pause();
      return;
    }
    final duration = knownDuration ?? player.state.duration;
    final pos = listeningPosition(widget.module, widget.clock);
    if (duration > Duration.zero && pos >= duration) {
      await player.stop();
      if (mounted) setState(() => _ended = true);
      return;
    }
    if (pos > const Duration(seconds: 1)) await player.seek(pos);
    await player.play();
  }

  @override
  void didUpdateWidget(covariant ListeningAudio old) {
    super.didUpdateWidget(old);
    if (old.paused != widget.paused) unawaited(_sync());
  }

  @override
  void dispose() {
    listeningVolume.removeListener(_applyVolume);
    _playingSub?.cancel();
    _p?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(
        _error != null
            ? Icons.error_outline
            : _ended
                ? Icons.volume_off
                : Icons.graphic_eq,
        size: 20,
        color: _error != null ? Colors.red : (_playing ? const Color(0xFF16A34A) : Colors.grey),
      ),
      const SizedBox(width: 4),
      Text(
        _error ?? (_ended ? 'Recording ended' : (_playing ? 'Playing' : 'Audio')),
        style: const TextStyle(fontSize: 12),
      ),
      const SizedBox(width: 4),
      SizedBox(
        width: 110,
        child: ValueListenableBuilder<double>(
          valueListenable: listeningVolume,
          builder: (context, v, _) => SliderTheme(
            data: SliderTheme.of(context).copyWith(trackHeight: 2, overlayShape: SliderComponentShape.noOverlay),
            child: Slider(
              value: v,
              max: 100,
              onChanged: (x) => listeningVolume.value = x,
            ),
          ),
        ),
      ),
    ]);
  }
}

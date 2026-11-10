import 'dart:async';
import 'dart:io';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import '../../core/theme/web_tokens.dart';
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
    if (_error != null) {
      return Tooltip(
        message: _error!,
        child: const Padding(
          padding: EdgeInsets.only(right: 8),
          child: Icon(Icons.error_outline, size: 16, color: TW.red500),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: 8), // mr-2
      child: AudioEqualizer(active: _playing && !_ended),
    );
  }
}

/// audio-equalizer.tsx: 20 bars `w-[3px] bg-green-500 rounded-t`, `gap-[1px] h-3`.
/// The web drives the bars from a WebAudio analyser; media_kit has no FFT
/// tap, so the bars are animated pseudo-levels while the recording plays.
class AudioEqualizer extends StatefulWidget {
  const AudioEqualizer({super.key, required this.active});
  final bool active;

  @override
  State<AudioEqualizer> createState() => _AudioEqualizerState();
}

class _AudioEqualizerState extends State<AudioEqualizer> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  final _rnd = math.Random(7);
  late List<double> _levels = List.filled(WebTokens.eqBars, 0.15);
  int _frame = -1;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final f = (_c.value * 12).floor();
          if (f != _frame) {
            _frame = f;
            _levels = [
              for (var i = 0; i < WebTokens.eqBars; i++)
                widget.active ? (0.2 + 0.8 * _rnd.nextDouble() * (1 - i / (WebTokens.eqBars * 1.4))) : 0.15,
            ];
          }
          return SizedBox(
            height: 12,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
              for (var i = 0; i < WebTokens.eqBars; i++) ...[
                if (i > 0) const SizedBox(width: 1),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  width: 3,
                  height: math.max(2, 12 * _levels[i]),
                  decoration: const BoxDecoration(
                    color: WebTokens.eqColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
                  ),
                ),
              ],
            ]),
          );
        },
      );
}

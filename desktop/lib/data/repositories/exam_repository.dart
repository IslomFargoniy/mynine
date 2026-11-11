import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path/path.dart' as p;

import '../../core/api/api_exception.dart';
import '../../core/api/mynine_api.dart';
import '../../core/storage/app_paths.dart';
import '../db/app_database.dart';
import '../models/exam_models.dart';

/// Prefetched exam: payload + local file paths of audio and images.
class CachedExam {
  CachedExam({required this.payload, required this.audioFiles, required this.imageFiles});

  final PrefetchPayload payload;

  /// audio key → local file path.
  final Map<String, String> audioFiles;

  /// image URL → local file path.
  final Map<String, String> imageFiles;

  Map<String, Object?> toJson() => {
        'payload': payload.toJson(),
        'audio_files': audioFiles,
        'image_files': imageFiles,
      };

  factory CachedExam.fromJson(Map<String, Object?> json) => CachedExam(
        payload: PrefetchPayload.fromJson((json['payload'] as Map).cast<String, Object?>()),
        audioFiles: (json['audio_files'] as Map? ?? {}).cast<String, String>(),
        imageFiles: (json['image_files'] as Map? ?? {}).cast<String, String>(),
      );

  /// Local file for an `audio.url` / asset URL, matched by URL or key.
  String? audioFileForUrl(String url) {
    for (final a in payload.audio) {
      if (a.url == url) return audioFiles[a.key];
    }
    return null;
  }
}

/// Progress of the prefetch step (0..1) with a label.
typedef PrefetchProgress = void Function(double progress, String label);

class ExamRepository {
  ExamRepository({required this.api, required this.db, required this.paths});

  final MynineApi api;
  final AppDatabase db;
  final AppPaths paths;

  static String cacheKey(int attemptId) => 'prefetch:$attemptId';

  /// Downloads the whole exam (payload, audio, images) for offline use.
  Future<CachedExam> prefetch(
    String token,
    int attemptId, {
    PrefetchProgress? onProgress,
  }) async {
    onProgress?.call(0, 'Downloading exam…');
    final payload = await api.prefetch(token);
    final dir = paths.examDir(attemptId);
    final audioDir = Directory(p.join(dir.path, 'audio'));
    final imageDir = Directory(p.join(dir.path, 'images'));

    final totalBytes = payload.audio.fold<int>(0, (s, a) => s + (a.size > 0 ? a.size : 1));
    var doneBytes = 0;
    final audioFiles = <String, String>{};
    for (final asset in payload.audio) {
      final file = audioTarget(asset, audioDir);
      final weight = asset.size > 0 ? asset.size : 1;
      await _downloadVerified(
        asset.url,
        file,
        token: token,
        sha256Hex: asset.sha256,
        onProgress: (received, total) {
          final t = total > 0 ? total : weight;
          final frac = (received / t).clamp(0.0, 1.0);
          onProgress?.call(
            0.1 + 0.8 * ((doneBytes + frac * weight) / (totalBytes == 0 ? 1 : totalBytes)),
            'Downloading audio…',
          );
        },
      );
      doneBytes += weight;
      audioFiles[asset.key] = file.path;
    }

    final imageFiles = <String, String>{};
    for (var i = 0; i < payload.images.length; i++) {
      final url = payload.images[i];
      onProgress?.call(0.9 + 0.1 * (i / payload.images.length), 'Downloading images…');
      final name = '${sha1.convert(utf8.encode(url))}${_ext(url, '.img')}';
      final file = File(p.join(imageDir.path, name));
      try {
        // Anonymous: images may live on another host; no credentials.
        if (!await file.exists()) await api.download(url, file, anonymous: true);
        imageFiles[url] = file.path;
      } catch (e) {
        // Images are not critical (and may live on other hosts): the renderer
        // falls back to the network / an empty box.
        debugPrint('Image not cached ($url): $e');
      }
    }

    final cached = CachedExam(payload: payload, audioFiles: audioFiles, imageFiles: imageFiles);
    await db.putCache(cacheKey(attemptId), jsonEncode(cached.toJson()));
    onProgress?.call(1, 'Ready');
    return cached;
  }

  Future<CachedExam?> loadCached(int attemptId) async {
    final raw = await db.getCache(cacheKey(attemptId));
    if (raw == null) return null;
    try {
      return CachedExam.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCached(int attemptId, CachedExam exam) =>
      db.putCache(cacheKey(attemptId), jsonEncode(exam.toJson()));

  Future<void> _downloadVerified(
    String url,
    File file, {
    required String token,
    String? sha256Hex,
    ProgressCallback? onProgress,
  }) async {
    if (await file.exists() && await verifySha256(file, sha256Hex)) return;
    for (var attempt = 0; attempt < 2; attempt++) {
      await api.download(url, file, examToken: token, onProgress: onProgress);
      if (await verifySha256(file, sha256Hex)) return;
      await file.delete();
    }
    throw ApiException(
      code: ApiErrorCode.unknown,
      message: 'Checksum mismatch for $url',
    );
  }

  /// Where an audio asset is stored: `audio_cache/<sha256><ext>` (shared by
  /// every candidate of the same test) when the checksum is known, else the
  /// attempt's own folder.
  File audioTarget(AudioAsset asset, Directory attemptAudioDir) {
    final ext = _ext(asset.url, '.mp3');
    final sha = asset.sha256?.trim().toLowerCase();
    if (sha != null && RegExp(r'^[0-9a-f]{64}$').hasMatch(sha)) {
      return File(p.join(paths.audioCache.path, '$sha$ext'));
    }
    return File(p.join(attemptAudioDir.path, '${_safe(asset.key)}$ext'));
  }

  /// Startup housekeeping: removes the downloaded files (exam folder) and the
  /// cached payloads of sessions that are over — closed, completed or with a
  /// refused token — since more than [maxAge], and of all but the [keep]
  /// newest such sessions. The session rows and the answer / violation
  /// queues are kept. Audio in the shared cache that no remaining session
  /// references is deleted too. Never touches the unfinished session.
  Future<int> cleanup({
    Duration maxAge = const Duration(days: 3),
    int keep = 20,
    DateTime? now,
  }) async {
    final at = (now ?? DateTime.now()).toUtc();
    final sessions = await db.allSessions(); // newest first
    var over = 0;
    var purged = 0;
    for (final s in sessions) {
      final done = s.closed || s.completed || s.authLost;
      if (!done) continue;
      over++;
      final since = (s.closedAt ?? s.createdAt).toUtc();
      if (at.difference(since) > maxAge || over > keep) {
        final dir = paths.examDir(s.attemptId);
        try {
          if (await dir.exists()) await dir.delete(recursive: true);
        } on FileSystemException catch (e) {
          debugPrint('cleanup: cannot delete ${dir.path}: $e');
          continue;
        }
        await db.deleteExamCache(s.attemptId);
        purged++;
      }
    }
    // Shared audio no longer referenced by any cached exam.
    final cacheDir = paths.audioCache;
    if (await cacheDir.exists()) {
      final referenced = <String>{};
      for (final s in await db.allSessions()) {
        final c = await loadCached(s.attemptId);
        if (c != null) referenced.addAll(c.audioFiles.values.map(p.normalize));
      }
      await for (final f in cacheDir.list()) {
        if (f is! File) continue;
        final path = p.normalize(f.path);
        final base = path.endsWith('.part') ? path.substring(0, path.length - 5) : path;
        if (referenced.contains(base)) continue;
        try {
          await f.delete();
        } on FileSystemException catch (e) {
          debugPrint('cleanup: cannot delete $path: $e');
        }
      }
    }
    return purged;
  }

  static String _safe(String s) => s.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  static String _ext(String url, String fallback) {
    final path = Uri.tryParse(url)?.path ?? url;
    final ext = p.extension(path);
    return ext.isEmpty || ext.length > 5 ? fallback : ext;
  }
}

/// Streams [file] through SHA-256 and compares with [expectedHex]
/// (case-insensitive). A null/empty expectation passes.
Future<bool> verifySha256(File file, String? expectedHex) async {
  if (expectedHex == null || expectedHex.isEmpty) return true;
  final digest = await sha256.bind(file.openRead()).first;
  return digest.toString().toLowerCase() == expectedHex.trim().toLowerCase();
}

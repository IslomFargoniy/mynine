import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Local directories. On Windows everything lives in `%LOCALAPPDATA%\Mynine`
/// (per-user, survives reinstall, writable without elevation).
class AppPaths {
  AppPaths(this.root);

  final Directory root;

  static Future<AppPaths> resolve() async {
    Directory base;
    final local = Platform.isWindows ? Platform.environment['LOCALAPPDATA'] : null;
    if (local != null && local.isNotEmpty) {
      base = Directory(p.join(local, 'Mynine'));
    } else {
      base = Directory(p.join((await getApplicationSupportDirectory()).path, 'Mynine'));
    }
    await base.create(recursive: true);
    return AppPaths(base);
  }

  Directory get data => Directory(p.join(root.path, 'data'));
  Directory get updates => Directory(p.join(root.path, 'updates'));
  Directory get previous => Directory(p.join(root.path, 'previous'));
  Directory examDir(int attemptId) => Directory(p.join(root.path, 'exam', '$attemptId'));
  File get updateStateFile => File(p.join(root.path, 'update_state.json'));
  File get logFile => File(p.join(root.path, 'mynine.log'));
}

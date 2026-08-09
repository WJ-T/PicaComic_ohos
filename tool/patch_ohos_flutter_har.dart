import 'dart:convert';
import 'dart:io';

const String _flutterAbilityPath =
    'package/src/main/ets/embedding/ohos/FlutterAbility.ets';

const String _patchedMarker = 'Failed to create or load Flutter content';

const String _oldWindowStageBlock = r'''    try {
      windowStage.on('windowStageEvent', this.windowStageEventCallback);
      this.flutterView = this.delegate!!.createView(this.context)
      Log.i(TAG, 'onWindowStageCreate:' + this.flutterView!!.getId());
      let storage: LocalStorage = new LocalStorage();
      storage.setOrCreate("viewId", this.flutterView!!.getId())
      windowStage.loadContent(this.pagePath(), storage, (err, data) => {
        if (err.code) {
          Log.e(TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
          return;
        }
        this.flutterView?.onWindowCreated();

        Log.i(TAG, 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
      });
      if (this.isDefaultFullScreen()) {
        FlutterManager.getInstance().setUseFullScreen(true, this.context);
      }
    } catch (exception) {
      Log.e(TAG, 'Failed to enable the listener for window stage event changes. Cause:' + JSON.stringify(exception));
    }''';

const String _newWindowStageBlock = r'''    try {
      windowStage.on('windowStageEvent', this.windowStageEventCallback);
    } catch (exception) {
      Log.e(TAG, 'Failed to enable the listener for window stage event changes. Cause:' + JSON.stringify(exception));
    }
    try {
      this.flutterView = this.delegate!!.createView(this.context)
      Log.i(TAG, 'onWindowStageCreate:' + this.flutterView!!.getId());
      let storage: LocalStorage = new LocalStorage();
      storage.setOrCreate("viewId", this.flutterView!!.getId())
      windowStage.loadContent(this.pagePath(), storage, (err, data) => {
        if (err.code) {
          Log.e(TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
          return;
        }
        this.flutterView?.onWindowCreated();

        Log.i(TAG, 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
      });
      if (this.isDefaultFullScreen()) {
        FlutterManager.getInstance().setUseFullScreen(true, this.context);
      }
    } catch (exception) {
      Log.e(TAG, 'Failed to create or load Flutter content. Cause:' + JSON.stringify(exception));
    }''';

void main(List<String> args) {
  final repoRoot = File.fromUri(Platform.script).parent.parent.absolute;
  final projectOnly = args.contains('--project-only');
  final candidates = <String>{};

  final projectHar = File('${repoRoot.path}/ohos/har/flutter.har');
  if (projectHar.existsSync()) {
    candidates.add(projectHar.path);
  }

  if (!projectOnly) {
    final flutterRoot = _flutterRoot();
    if (flutterRoot == null) {
      stderr.writeln(
        'Unable to locate Flutter root. Make sure flutter is in PATH, '
        'or set FLUTTER_ROOT.',
      );
      exitCode = 1;
      return;
    }
    final engineDir = Directory('$flutterRoot/bin/cache/artifacts/engine');
    if (engineDir.existsSync()) {
      for (final entry in engineDir.listSync()) {
        if (entry is! Directory) {
          continue;
        }
        final name =
            entry.uri.pathSegments.where((segment) => segment.isNotEmpty).last;
        if (!name.startsWith('ohos-')) {
          continue;
        }
        final har = File('${entry.path}/flutter.har');
        if (har.existsSync()) {
          candidates.add(har.path);
        }
      }
    }
  }

  if (candidates.isEmpty) {
    stderr.writeln('No OHOS flutter.har files found to patch.');
    exitCode = 1;
    return;
  }

  var failed = false;
  for (final path in candidates) {
    try {
      _patchHar(File(path));
    } catch (error) {
      failed = true;
      stderr.writeln('Failed to patch $path: $error');
    }
  }

  if (failed) {
    exitCode = 1;
  }
}

String? _flutterRoot() {
  final envRoot = Platform.environment['FLUTTER_ROOT'];
  if (envRoot != null && envRoot.isNotEmpty) {
    return envRoot;
  }

  try {
    final version = Process.runSync(
      'flutter',
      <String>['--version', '--machine'],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (version.exitCode == 0) {
      final data = jsonDecode(version.stdout as String) as Map<String, dynamic>;
      final root = data['flutterRoot'] as String?;
      if (root != null && root.isNotEmpty) {
        return root;
      }
    }
  } catch (_) {}

  final whichCommand = Platform.isWindows ? 'where' : 'which';
  late final ProcessResult which;
  try {
    which = Process.runSync(
      whichCommand,
      <String>['flutter'],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
  } catch (_) {
    return null;
  }
  if (which.exitCode != 0) {
    return null;
  }
  final executables = (which.stdout as String)
      .split(RegExp(r'\r?\n'))
      .where((line) => line.trim().isNotEmpty)
      .toList();
  if (executables.isEmpty) {
    return null;
  }
  return File(executables.first).parent.parent.path;
}

void _patchHar(File har) {
  final tempDir = Directory.systemTemp.createTempSync('pica_ohos_har_patch_');
  try {
    _runTar(<String>['-xzf', har.path, '-C', tempDir.path]);
    final flutterAbility = File('${tempDir.path}/$_flutterAbilityPath');
    if (!flutterAbility.existsSync()) {
      throw StateError('$_flutterAbilityPath not found in HAR');
    }

    final content = flutterAbility.readAsStringSync();
    if (content.contains(_patchedMarker)) {
      stdout.writeln('Already patched: ${har.path}');
      return;
    }
    if (!content.contains(_oldWindowStageBlock)) {
      throw StateError('target FlutterAbility block not found');
    }

    flutterAbility.writeAsStringSync(
      content.replaceFirst(_oldWindowStageBlock, _newWindowStageBlock),
    );
    _runTar(<String>['-czf', har.path, '-C', tempDir.path, 'package']);
    stdout.writeln('Patched: ${har.path}');
  } finally {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  }
}

void _runTar(List<String> args) {
  final result = Process.runSync(
    'tar',
    args,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  if (result.exitCode != 0) {
    throw ProcessException(
      'tar',
      args,
      result.stderr as String,
      result.exitCode,
    );
  }
}

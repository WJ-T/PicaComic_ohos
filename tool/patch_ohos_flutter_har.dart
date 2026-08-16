import 'dart:convert';
import 'dart:io';

const String _flutterAbilityPath =
    'package/src/main/ets/embedding/ohos/FlutterAbility.ets';
const String _flutterViewPath = 'package/src/main/ets/view/FlutterView.ets';
const String _displayMetricsChannelPath =
    'package/src/main/ets/embedding/engine/systemchannels/DisplayMetricsChannel.ets';

const String _patchedMarker = 'Failed to create or load Flutter content';
const String _flutterViewPatchedMarker =
    'Ignoring dynamic DPI scale factor to keep the Flutter viewport stable';
const String _displayMetricsPatchedMarker =
    'Ignoring updateDpiScale to keep the Flutter viewport stable';

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

const String _oldDynamicDpiCallback =
    r'''  onDevicePixelRatioChange = (dpiScaleFactor: number) => {
    try {
      // Get display information
      this.displayInfo = display.getDefaultDisplaySync();

      // Set DPI for text input channel
      this.flutterEngine?.getTextInputChannel()?.setDevicePixelRatio(this.displayInfo.densityPixels);

      // Calculate device pixel ratio
      // When dpiScaleFactor is DPI_SCALE_RESET, reset DPI to system default
      let newDevicePixelRatio: number;
      if (dpiScaleFactor === DPI_SCALE_RESET) {
        newDevicePixelRatio = this.displayInfo.densityPixels;
        Log.d(TAG, "Resetting device pixel ratio to system default: " + newDevicePixelRatio);
        // When resetting DPI, set the flag to false
        this.isDevicePixelRatioAdaptive = false;
      } else {
        newDevicePixelRatio = this.displayInfo.densityPixels * dpiScaleFactor;
        Log.d(TAG, "Scaling device pixel ratio by factor " + dpiScaleFactor + ": " + newDevicePixelRatio);
        // When customizing DPI, set the flag to true
        this.isDevicePixelRatioAdaptive = true;
      }

      // Only update when DPI actually changes
      if (newDevicePixelRatio !== this.viewportMetrics.devicePixelRatio) {
        this.viewportMetrics.devicePixelRatio = newDevicePixelRatio;
        Log.i(TAG, "Device pixel ratio updated: " + newDevicePixelRatio +
          " (scale factor: " + dpiScaleFactor + ", system DPI: " + this.displayInfo.densityPixels + ")");
        this.needSetViewport = true;
        this.onAreaChange(null);
      }
    } catch (e) {
      Log.e(TAG, "Error updating device pixel ratio: " + JSON.stringify(e));
    }
  }''';

const String _newDynamicDpiCallback =
    r'''  onDevicePixelRatioChange = (dpiScaleFactor: number) => {
    // Do not apply Flutter's runtime DPI scale to the root viewport. A changing
    // devicePixelRatio resizes the entire Flutter tree, including overlays.
    Log.d(TAG, "Ignoring dynamic DPI scale factor to keep the Flutter viewport stable: " + dpiScaleFactor);
  }''';

const String _oldWindowDpiBlock = r'''    // Only handle when height changes
    if (this.lastHeight !== data.height) {
      try {
        // If DPI has been customized, do not process system DPI changes
          this.displayInfo = display.getDefaultDisplaySync();
          this.flutterEngine?.getTextInputChannel()?.setDevicePixelRatio(this.displayInfo.densityPixels);

          let devicePixelRatio: number = this.displayInfo.densityPixels;
          Log.i(TAG, `windowSizeChangeCallback devicePixelRatio: ${devicePixelRatio}, viewportMetrics.devicePixelRatio: ${this.viewportMetrics.devicePixelRatio}`);

          if (devicePixelRatio !== this.viewportMetrics.devicePixelRatio) {
            this.viewportMetrics.devicePixelRatio = devicePixelRatio;
            Log.i(TAG, `windowSizeChangeCallback: Updated devicePixelRatio to ${devicePixelRatio}`);
            this.needSetViewport = true;
          }
      } catch (e) {
        Log.e(TAG, `windowSizeChangeCallback error: ${JSON.stringify(e)}`);
      }
    }

    // Update lastHeight''';

const String _newWindowDpiBlock =
    r'''    // Window size changes update physical viewport dimensions below. They must
    // not change devicePixelRatio, otherwise the whole Flutter tree is scaled.
    // Update lastHeight''';

const String _oldDisplayMetricsDpiCase = r'''        case "updateDpiScale":
          let dpiScaleFactor: number = call.argument('dpiScale');
          Log.i(TAG, "Received dpiScaleFactor '" + dpiScaleFactor + "' message.");
          this.context.eventHub.emit('changeDevicePixelRatio', dpiScaleFactor)
          result.success(true);
          break;''';

const String _newDisplayMetricsDpiCase = r'''        case "updateDpiScale":
          let dpiScaleFactor: number = call.argument('dpiScale');
          Log.i(TAG, "Ignoring updateDpiScale to keep the Flutter viewport stable: " + dpiScaleFactor);
          result.success(true);
          break;''';

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
    final flutterView = File('${tempDir.path}/$_flutterViewPath');
    final displayMetricsChannel =
        File('${tempDir.path}/$_displayMetricsChannelPath');
    for (final file in <File>[
      flutterAbility,
      flutterView,
      displayMetricsChannel
    ]) {
      if (!file.existsSync()) {
        throw StateError('${file.path} not found in HAR');
      }
    }

    var changed = false;
    var abilityContent = flutterAbility.readAsStringSync();
    if (!abilityContent.contains(_patchedMarker)) {
      if (!abilityContent.contains(_oldWindowStageBlock)) {
        throw StateError('target FlutterAbility block not found');
      }
      abilityContent = abilityContent.replaceFirst(
          _oldWindowStageBlock, _newWindowStageBlock);
      flutterAbility.writeAsStringSync(abilityContent);
      changed = true;
    }

    var viewContent = flutterView.readAsStringSync();
    // Engine HARs can differ only in whitespace on otherwise identical blank
    // lines. Normalize those lines so the source patch remains portable.
    viewContent = viewContent.replaceAll(
      RegExp(r'^[ \t]+$', multiLine: true),
      '',
    );
    if (!viewContent.contains(_flutterViewPatchedMarker)) {
      if (!viewContent.contains(_oldDynamicDpiCallback)) {
        throw StateError('target FlutterView DPI callback not found');
      }
      if (!viewContent.contains(_oldWindowDpiBlock)) {
        throw StateError('target FlutterView window DPI block not found');
      }
      viewContent = viewContent
          .replaceFirst(_oldDynamicDpiCallback, _newDynamicDpiCallback)
          .replaceFirst(_oldWindowDpiBlock, _newWindowDpiBlock);
      flutterView.writeAsStringSync(viewContent);
      changed = true;
    }

    var displayMetricsContent = displayMetricsChannel.readAsStringSync();
    if (!displayMetricsContent.contains(_displayMetricsPatchedMarker)) {
      if (!displayMetricsContent.contains(_oldDisplayMetricsDpiCase)) {
        throw StateError('target DisplayMetricsChannel DPI case not found');
      }
      displayMetricsContent = displayMetricsContent.replaceFirst(
        _oldDisplayMetricsDpiCase,
        _newDisplayMetricsDpiCase,
      );
      displayMetricsChannel.writeAsStringSync(displayMetricsContent);
      changed = true;
    }

    _runTar(<String>['-czf', har.path, '-C', tempDir.path, 'package']);
    stdout.writeln('${changed ? 'Patched' : 'Already patched'}: ${har.path}');
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

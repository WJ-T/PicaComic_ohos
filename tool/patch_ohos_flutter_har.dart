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

const String _oldDisplayChangeDpiBlock =
    r'''    this.displayInfo = display.getDefaultDisplaySync();
    this.flutterEngine?.getTextInputChannel()?.setDevicePixelRatio(this.displayInfo.densityPixels);
    let devicePixelRatio: number = this.displayInfo?.densityPixels;
    Log.i(TAG, "Display on: " + JSON.stringify(this.displayInfo) + ". Display id:" + JSON.stringify(data))
    if (devicePixelRatio != this.viewportMetrics.devicePixelRatio) {
      this.viewportMetrics.devicePixelRatio = devicePixelRatio;
      this.needSetViewport = true;
      this.onAreaChange(null);
    }
    this.flutterEngine?.getFlutterNapi()?.updateRefreshRate(this.displayInfo?.refreshRate);''';

const String _newDisplayChangeDpiBlock =
    r'''    this.displayInfo = display.getDefaultDisplaySync();
    this.flutterEngine?.getTextInputChannel()?.setDevicePixelRatio(this.displayInfo.densityPixels);
    Log.i(TAG, "Display on: " + JSON.stringify(this.displayInfo) + ". Display id:" + JSON.stringify(data));
    // Keep the viewport DPI stable. Only the refresh rate is display-dependent;
    // changing devicePixelRatio here rescales the entire Flutter tree.
    this.flutterEngine?.getFlutterNapi()?.updateRefreshRate(this.displayInfo?.refreshRate);''';

const String _oldWindowDpiBlock341 = r'''    // Only handle when height changes
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

const String _oldDisplayMetricsDpiCase341 = r'''        case "updateDpiScale":
          if (this.customDpiActive && this.currentUri) {
            result.success(true);
            Log.i(TAG, "Custom DPI for this page" + this.currentUri);
            break;
          }
          let dpiScaleFactor: number = call.argument('dpiScale');
          Log.i(TAG, "Received dpiScaleFactor '" + dpiScaleFactor + "' message.");
          this.context.eventHub.emit('changeDevicePixelRatio', dpiScaleFactor)
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

  // Hvigor packages the installed OHOS module from oh_modules, not only the
  // project HAR. Patch that generated dependency as well so the final HAP
  // uses the same stable viewport implementation.
  _patchInstalledFlutterModules(repoRoot);

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

    final changed = _patchFlutterSources(
      flutterAbility: flutterAbility,
      flutterView: flutterView,
      displayMetricsChannel: displayMetricsChannel,
    );

    _runTar(<String>['-czf', har.path, '-C', tempDir.path, 'package']);
    stdout.writeln('${changed ? 'Patched' : 'Already patched'}: ${har.path}');
  } finally {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  }
}

bool _patchFlutterSources({
  required File flutterAbility,
  required File flutterView,
  required File displayMetricsChannel,
}) {
  var changed = false;
  var abilityContent = flutterAbility.readAsStringSync();
  if (!abilityContent.contains(_patchedMarker)) {
    if (!abilityContent.contains(_oldWindowStageBlock)) {
      throw StateError('target FlutterAbility block not found');
    }
    abilityContent = abilityContent.replaceFirst(
      _oldWindowStageBlock,
      _newWindowStageBlock,
    );
    flutterAbility.writeAsStringSync(abilityContent);
    changed = true;
  }

  var viewContent = flutterView.readAsStringSync().replaceAll(
        RegExp(r'^[ \t]+$', multiLine: true),
        '',
      );
  if (!viewContent.contains(_flutterViewPatchedMarker)) {
    if (!viewContent.contains(_oldDynamicDpiCallback)) {
      throw StateError('target FlutterView DPI callback not found');
    }
    final windowDpiBlock = viewContent.contains(_oldWindowDpiBlock)
        ? _oldWindowDpiBlock
        : _oldWindowDpiBlock341;
    if (!viewContent.contains(windowDpiBlock)) {
      throw StateError('target FlutterView window DPI block not found');
    }
    viewContent = viewContent
        .replaceFirst(_oldDynamicDpiCallback, _newDynamicDpiCallback)
        .replaceFirst(windowDpiBlock, _newWindowDpiBlock);
    changed = true;
  }
  if (viewContent.contains(_oldDisplayChangeDpiBlock)) {
    viewContent = viewContent.replaceFirst(
      _oldDisplayChangeDpiBlock,
      _newDisplayChangeDpiBlock,
    );
    changed = true;
  }
  if (changed) {
    flutterView.writeAsStringSync(viewContent);
  }

  var displayMetricsContent = displayMetricsChannel.readAsStringSync();
  if (!displayMetricsContent.contains(_displayMetricsPatchedMarker)) {
    final displayMetricsDpiCase =
        displayMetricsContent.contains(_oldDisplayMetricsDpiCase)
            ? _oldDisplayMetricsDpiCase
            : _oldDisplayMetricsDpiCase341;
    if (!displayMetricsContent.contains(displayMetricsDpiCase)) {
      throw StateError('target DisplayMetricsChannel DPI case not found');
    }
    displayMetricsContent = displayMetricsContent.replaceFirst(
      displayMetricsDpiCase,
      _newDisplayMetricsDpiCase,
    );
    displayMetricsChannel.writeAsStringSync(displayMetricsContent);
    changed = true;
  }
  return changed;
}

void _patchInstalledFlutterModules(Directory repoRoot) {
  final ohpmRoot = Directory('${repoRoot.path}/ohos/oh_modules/.ohpm');
  if (!ohpmRoot.existsSync()) return;
  var found = false;
  for (final entry in ohpmRoot.listSync()) {
    if (entry is! Directory || !entry.path.contains('@ohos+flutter_ohos@')) {
      continue;
    }
    final module = Directory('${entry.path}/oh_modules/@ohos/flutter_ohos');
    final ability =
        File('${module.path}/src/main/ets/embedding/ohos/FlutterAbility.ets');
    final view = File('${module.path}/src/main/ets/view/FlutterView.ets');
    final metrics = File(
        '${module.path}/src/main/ets/embedding/engine/systemchannels/DisplayMetricsChannel.ets');
    if (!ability.existsSync() || !view.existsSync() || !metrics.existsSync()) {
      continue;
    }
    found = true;
    final changed = _patchFlutterSources(
      flutterAbility: ability,
      flutterView: view,
      displayMetricsChannel: metrics,
    );
    stdout
        .writeln('${changed ? 'Patched' : 'Already patched'}: ${module.path}');
  }
  if (!found) {
    stderr.writeln('No installed @ohos/flutter_ohos module found to patch.');
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

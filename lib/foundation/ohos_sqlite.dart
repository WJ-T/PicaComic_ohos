import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/open.dart';

import 'platform_utils.dart';

/// Registers a platform-specific sqlite loader for OHOS so that the `sqlite3`
/// package can locate the system library instead of throwing an unsupported
/// platform error.
void configureOhosSqlite() {
  if (_ohosSqliteConfigured) {
    return;
  }
  _ohosSqliteConfigured = true;
  if (PlatformUtils.isOhos) {
    open.overrideForAll(_openOhosSqlite);
  }
}

bool _ohosSqliteConfigured = false;

DynamicLibrary _openOhosSqlite() {
  final tried = <String>[];
  for (final path in _candidatePaths()) {
    tried.add(path);
    try {
      return DynamicLibrary.open(path);
    } catch (_) {
      // continue trying
    }
  }
  try {
    return DynamicLibrary.process();
  } catch (e) {
    stderr.writeln(
        '[sqlite3] Failed to locate sqlite3 dynamic library on OHOS. Tried: ${tried.join(', ')}. Error: $e');
    rethrow;
  }
}

Iterable<String> _candidatePaths() sync* {
  final seen = <String>{};
  final ordered = <String>[];
  void add(String path) {
    if (seen.add(path)) {
      ordered.add(path);
    }
  }

  const relativeNames = <String>[
    'libsqlite3_flutter.so',
    'libsqlite3.z.so',
    'libsqlite3.so',
    'libsqlite.z.so',
    'libsqlite.so',
  ];
  const searchDirs = <String>[
    '/system/lib64',
    '/system/lib',
    '/system/lib64/module',
    '/system/lib/module',
    '/vendor/lib64',
    '/vendor/lib',
    '/data/local/tmp',
  ];

  for (final dir in searchDirs) {
    for (final name in relativeNames) {
      add('$dir/$name');
    }
    try {
      final directory = Directory(dir);
      if (!directory.existsSync()) continue;
      for (final entity in directory.listSync()) {
        final path = entity.path;
        if (path.contains('sqlite') && path.endsWith('.so')) {
          add(path);
        }
      }
    } catch (_) {
      // ignore
    }
  }

  for (final name in relativeNames) {
    add(name);
  }

  for (final path in ordered) {
    yield path;
  }
}

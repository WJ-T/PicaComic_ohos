import 'dart:io';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'platform_utils.dart';

class OhosPathProvider extends PathProviderPlatform {
  OhosPathProvider._();

  static void registerIfNeeded() {
    if (!PlatformUtils.isOhos) {
      return;
    }
    if (PathProviderPlatform.instance is OhosPathProvider) {
      return;
    }
    PathProviderPlatform.instance = OhosPathProvider._();
  }

  static final String _supportRoot = _initPersistentDir();
  static final String _cacheRoot = _initCacheDir();

  static String get supportRoot => _supportRoot;
  static String get cacheRoot => _cacheRoot;

  static String _initPersistentDir() {
    final candidates = <String>[
      "/data/storage/el2/base/files",
      "/data/storage/el1/base/haps",
    ];
    for (final base in candidates) {
      final dir = Directory(base);
      if (dir.existsSync()) {
        final target = "$base/pica_comic";
        Directory(target).createSync(recursive: true);
        return target;
      }
    }
    final fallback = "${Directory.systemTemp.path}/pica_comic_data";
    Directory(fallback).createSync(recursive: true);
    return fallback;
  }

  static String _initCacheDir() {
    final candidates = <String>[
      "/data/storage/el2/base/cache",
      "/data/storage/el1/base/cache",
    ];
    for (final base in candidates) {
      final dir = Directory(base);
      if (dir.existsSync()) {
        final target = "$base/pica_comic";
        Directory(target).createSync(recursive: true);
        return target;
      }
    }
    final fallback = "${Directory.systemTemp.path}/pica_comic_cache";
    Directory(fallback).createSync(recursive: true);
    return fallback;
  }

  String get _downloadsPath {
    final path = "$_supportRoot/downloads";
    Directory(path).createSync(recursive: true);
    return path;
  }

  static String get fallbackSupportPath => _supportRoot;
  static String get fallbackCachePath => _cacheRoot;

  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;

  @override
  Future<String?> getApplicationSupportPath() async => _supportRoot;

  @override
  Future<String?> getApplicationDocumentsPath() async => _supportRoot;

  @override
  Future<String?> getLibraryPath() async => _supportRoot;

  @override
  Future<String?> getApplicationCachePath() async => _cacheRoot;

  @override
  Future<String?> getExternalStoragePath() async => _supportRoot;

  @override
  Future<List<String>?> getExternalCachePaths() async => <String>[_cacheRoot];

  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async =>
      <String>[_supportRoot];

  @override
  Future<String?> getDownloadsPath() async => _downloadsPath;
}

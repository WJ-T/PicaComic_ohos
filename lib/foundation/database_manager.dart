import 'dart:io';

import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';

class DatabaseManager {
  DatabaseManager._();

  static sqflite.DatabaseFactory? _factory;

  static sqflite.DatabaseFactory get factory {
    if (_factory != null) {
      return _factory!;
    }
    if (App.isWindows || App.isLinux || App.isMacOS) {
      sqfliteFfiInit();
      _factory = databaseFactoryFfi;
    } else {
      _factory = sqflite.databaseFactorySqflitePlugin;
    }
    return _factory!;
  }

  static Future<sqflite.Database> openDatabase(
    String path, {
    int? version,
    sqflite.OnDatabaseConfigureFn? onConfigure,
    sqflite.OnDatabaseCreateFn? onCreate,
    sqflite.OnDatabaseVersionChangeFn? onUpgrade,
  }) {
    return factory.openDatabase(
      path,
      options: sqflite.OpenDatabaseOptions(
        version: version,
        onConfigure: onConfigure,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
      ),
    );
  }

  static String get inMemoryPath => sqflite.inMemoryDatabasePath;

  static Future<void> deleteDatabase(String path) async {
    await factory.deleteDatabase(path);
  }

  static Future<String> ensureDirectory(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory.path;
  }
}

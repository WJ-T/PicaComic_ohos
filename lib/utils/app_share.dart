import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/platform_utils.dart';
import 'package:share_plus/share_plus.dart' as share_plus;

class AppShare {
  static const MethodChannel _ohosChannel =
      MethodChannel('pica_comic/ohos_share');

  static Future<void> shareText(String text, {String? subject}) async {
    if (PlatformUtils.isOhos) {
      await _ohosChannel.invokeMethod('shareText', {
        'text': text,
        'subject': subject,
      });
      return;
    }
    await share_plus.Share.share(text, subject: subject);
  }

  static Future<void> shareFile(String path) async {
    if (PlatformUtils.isOhos) {
      await _ohosChannel.invokeMethod('shareFiles', {
        'paths': [path],
      });
      return;
    }
    await share_plus.Share.shareXFiles([share_plus.XFile(path)]);
  }

  static Future<void> shareFiles(List<String> paths) async {
    if (paths.isEmpty) {
      return;
    }
    if (PlatformUtils.isOhos) {
      await _ohosChannel.invokeMethod('shareFiles', {
        'paths': paths,
      });
      return;
    }
    await share_plus.Share.shareXFiles(
      paths.map((path) => share_plus.XFile(path)).toList(),
    );
  }

  static Future<void> shareData({
    required Uint8List data,
    required String filename,
    required String mime,
  }) async {
    if (PlatformUtils.isOhos || App.isWindows) {
      final file = await _writeShareCacheFile(filename, data);
      await shareFile(file.path);
      return;
    }
    await share_plus.Share.shareXFiles([
      share_plus.XFile.fromData(data, mimeType: mime, name: filename),
    ]);
  }

  static Future<File> _writeShareCacheFile(
      String filename, Uint8List data) async {
    final dir = Directory('${App.cachePath}${Platform.pathSeparator}share');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final safeName = filename.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final file = File('${dir.path}${Platform.pathSeparator}$safeName');
    await file.writeAsBytes(data, flush: true);
    return file;
  }
}

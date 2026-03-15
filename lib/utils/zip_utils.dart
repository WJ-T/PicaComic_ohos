import 'dart:io';

import 'package:archive/archive_io.dart' as archive;
import 'package:zip_flutter/zip_flutter.dart' as zip_flutter;

import '../foundation/platform_utils.dart';

abstract class ZipArchiveWriter {
  void addFile(String archivePath, String sourcePath);
  void close();
}

ZipArchiveWriter createZipWriter(String outputPath) {
  if (PlatformUtils.isOhos) {
    return _ArchiveZipWriter(outputPath);
  }
  return _ZipFlutterWriter(outputPath);
}

Future<void> extractZipFile(String zipFilePath, String destinationDir) async {
  if (PlatformUtils.isOhos) {
    // 在 OHOS 上直接读入内存解压，避免 InputFileStream 可能的兼容问题
    final bytes = File(zipFilePath).readAsBytesSync();
    final archiveData = archive.ZipDecoder().decodeBytes(bytes, verify: true);
    Directory(destinationDir).createSync(recursive: true);
    for (final file in archiveData) {
      final outPath = '$destinationDir/${file.name}';
      if (file.isFile) {
        File(outPath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(file.content as List<int>);
      } else {
        Directory(outPath).createSync(recursive: true);
      }
    }
    return;
  }
  zip_flutter.ZipFile.openAndExtract(zipFilePath, destinationDir);
}

class _ZipFlutterWriter implements ZipArchiveWriter {
  final zip_flutter.ZipFile _zipFile;

  _ZipFlutterWriter(String outputPath)
      : _zipFile = zip_flutter.ZipFile.open(outputPath);

  @override
  void addFile(String archivePath, String sourcePath) {
    _zipFile.addFile(archivePath, sourcePath);
  }

  @override
  void close() {
    _zipFile.close();
  }
}

class _ArchiveZipWriter implements ZipArchiveWriter {
  final archive.ZipFileEncoder _encoder = archive.ZipFileEncoder();

  _ArchiveZipWriter(String outputPath) {
    _encoder.create(outputPath);
  }

  @override
  void addFile(String archivePath, String sourcePath) {
    final file = File(sourcePath);
    if (!file.existsSync()) {
      throw FileSystemException("File not found", sourcePath);
    }
    _encoder.addFile(file, archivePath);
  }

  @override
  void close() {
    _encoder.close();
  }
}

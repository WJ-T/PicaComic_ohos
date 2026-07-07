import 'dart:math';

bool needUpdate(String localVersion, String remoteVersion) {
  final localVersionList = _normalizeVersion(localVersion).split('.');
  final remoteVersionList = _normalizeVersion(remoteVersion).split('.');
  final maxLength = max(localVersionList.length, remoteVersionList.length);
  for (var i = 0; i < maxLength; i++) {
    final localSegment = i < localVersionList.length
        ? _parseVersionSegment(localVersionList[i])
        : 0;
    final remoteSegment = i < remoteVersionList.length
        ? _parseVersionSegment(remoteVersionList[i])
        : 0;
    if (remoteSegment > localSegment) {
      return true;
    } else if (remoteSegment < localSegment) {
      return false;
    }
  }
  return false;
}

String _normalizeVersion(String version) {
  var value = version.trim();
  if (value.startsWith('v') || value.startsWith('V')) {
    value = value.substring(1);
  }
  return value.split('+').first.replaceFirst('-', '.');
}

int _parseVersionSegment(String segment) {
  final match = RegExp(r'^\d+').firstMatch(segment);
  if (match == null) {
    return 0;
  }
  return int.parse(match.group(0)!);
}

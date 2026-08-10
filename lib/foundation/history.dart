import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/comic_source/comic_source.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/image_manager.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/foundation/platform_utils.dart';
import 'package:pica_comic/network/jm_network/jm_image.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/webdav.dart';
import 'package:pica_comic/utils/ohos_widget.dart';
import 'package:sqlite3/sqlite3.dart';

part "image_favorites.dart";

abstract mixin class HistoryMixin {
  String get title;

  String? get subTitle;

  String get cover;

  String get target;

  Object? get maxPage => null;

  HistoryType get historyType;
}

final class HistoryType {
  static HistoryType get picacg => const HistoryType(0);

  static HistoryType get ehentai => const HistoryType(1);

  static HistoryType get jmComic => const HistoryType(2);

  static HistoryType get hitomi => const HistoryType(3);

  static HistoryType get htmanga => const HistoryType(4);

  static HistoryType get nhentai => const HistoryType(5);

  final int value;

  String get name {
    if (value >= 0 && value <= 5) {
      return ["picacg", "ehentai", "jm", "hitomi", "htmanga", "nhentai"][value];
    } else {
      return ComicSource.fromIntKey(value)?.name ?? "Unknown";
    }
  }

  const HistoryType(this.value);

  @override
  bool operator ==(Object other) =>
      other is HistoryType && other.value == value;

  @override
  int get hashCode => value.hashCode;

  ComicSource? get comicSource {
    if (value >= 0 && value <= 5) {
      return ComicSource.find(name);
    } else {
      return ComicSource.fromIntKey(value);
    }
  }
}

base class History extends LinkedListEntry<History> {
  HistoryType type;

  DateTime time;

  String title;

  String subtitle;

  String cover;

  /// 标记为0表示没有阅读位置记录
  int ep;

  int page;

  String target;

  Set<int> readEpisode;

  int? maxPage;

  History(this.type, this.time, this.title, this.subtitle, this.cover, this.ep,
      this.page, this.target, [Set<int>? readEpisode, this.maxPage])
      : readEpisode =
            readEpisode == null ? <int>{} : Set<int>.from(readEpisode);

  History.fromModel(
      {required HistoryMixin model,
      required this.ep,
      required this.page,
      Set<int>? readEpisode,
      DateTime? time})
      : type = model.historyType,
        title = model.title,
        subtitle = model.subTitle ?? '',
        cover = model.cover,
        target = model.target,
        time = time ?? DateTime.now(),
        readEpisode =
            readEpisode == null ? <int>{} : Set<int>.from(readEpisode);

  Map<String, dynamic> toMap() => {
        "type": type.value,
        "time": time.millisecondsSinceEpoch,
        "title": title,
        "subtitle": subtitle,
        "cover": cover,
        "ep": ep,
        "page": page,
        "target": target,
        "readEpisode": readEpisode.toList(),
        "max_page": maxPage
      };

  History.fromMap(Map<String, dynamic> map)
      : type = HistoryType(map["type"]),
        time = DateTime.fromMillisecondsSinceEpoch(map["time"]),
        title = map["title"],
        subtitle = map["subtitle"],
        cover = map["cover"],
        ep = map["ep"],
        page = map["page"],
        target = map["target"],
        readEpisode = Set<int>.from(
            (map["readEpisode"] as List<dynamic>?)?.toSet() ?? const <int>{}),
        maxPage = map["max_page"];

  @override
  String toString() {
    return 'NewHistory{type: $type, time: $time, title: $title, subtitle: $subtitle, cover: $cover, ep: $ep, page: $page, target: $target}';
  }

  History.fromRow(Row row)
      : type = HistoryType(row["type"]),
        time = DateTime.fromMillisecondsSinceEpoch(row["time"]),
        title = row["title"],
        subtitle = row["subtitle"],
        cover = row["cover"],
        ep = row["ep"],
        page = row["page"],
        target = row["target"],
        readEpisode = Set<int>.from((row["readEpisode"] as String)
            .split(',')
            .where((element) => element != "")
            .map((e) => int.parse(e))),
        maxPage = row["max_page"];

  static Future<History> findOrCreate(
    HistoryMixin model, {
    int ep = 0,
    int page = 0,
  }) async {
    var history = await HistoryManager().find(model.target);
    if (history != null) {
      return history;
    }
    history = History.fromModel(model: model, ep: ep, page: page);
    HistoryManager().addHistory(history);
    return history;
  }

  static Future<History> createIfNull(
      History? history, HistoryMixin model) async {
    if (history != null) {
      return history;
    }
    history = History.fromModel(model: model, ep: 0, page: 0);
    HistoryManager().addHistory(history);
    return history;
  }
}

class HistoryManager {
  static HistoryManager? cache;

  HistoryManager.create();

  factory HistoryManager() =>
      cache == null ? (cache = HistoryManager.create()) : cache!;

  Database? _db;
  bool _dbWarningIssued = false;
  Timer? _ohosWidgetSyncDebounce;
  final Map<String, String> _ohosWidgetCoverDataCache = {};

  bool _ensureDbAvailable() {
    if (_db != null) {
      return true;
    }
    if (!_dbWarningIssued) {
      _dbWarningIssued = true;
      LogManager.addLog(LogLevel.warning, "HistoryManager",
          "History database is unavailable on this platform. Functions that rely on it will be no-ops.");
    }
    return false;
  }

  int get length {
    if (!_ensureDbAvailable()) {
      return 0;
    }
    return _db!.select("select count(*) from history;").first[0] as int;
  }

  Map<String, bool>? _cachedHistory;

  Future<void> tryUpdateDb() async {
    var file = File("${App.dataPath}/history_temp.db");
    if (!file.existsSync()) {
      LogManager.addLog(
          LogLevel.info, "HistoryManager.tryUpdateDb", "db file not exist");
      return;
    }
    var db = sqlite3.open(file.path);
    var newHistory0 = db.select("""
      select * from history
      order by time DESC;
    """);
    var newHistory =
        newHistory0.map((element) => History.fromRow(element)).toList();
    if (file.existsSync()) {
      var skips = 0;
      for (var history in newHistory) {
        if (findSync(history.target) == null) {
          addHistory(history);
          LogManager.addLog(LogLevel.info, "HistoryManager",
              "merge history ${history.target}");
        } else {
          skips++;
        }
      }
      LogManager.addLog(LogLevel.info, "HistoryManager",
          "merge history, skipped $skips, added ${newHistory.length - skips}");

      //import favorite images
      skips = 0;
      ImageFavoriteManager.init();
      var newImages0 = db.select("select * from image_favorites;");
      var newImages = newImages0
          .map((e) => ImageFavorite(e["id"], e["cover"], e["title"], e["ep"],
              e["page"], jsonDecode(e["other"])))
          .toList();
      for (var image in newImages) {
        if (ImageFavoriteManager.exist(image.id, image.ep, image.page)) {
          skips++;
        } else {
          ImageFavoriteManager.add(image);
          LogManager.addLog(LogLevel.info, "HistoryManager",
              "merge favorite image ep ${image.ep} page ${image.page} @ ${image.id}");
        }
      }
      LogManager.addLog(LogLevel.info, "HistoryManager",
          "merge favorite images, skipped $skips, added ${newImages.length - skips}");
    }
    db.dispose();
    file.deleteSync();
  }

  Future<void> init() async {
    try {
      _db = sqlite3.open("${App.dataPath}/history.db");
    } catch (e, s) {
      _db = null;
      LogManager.addLog(LogLevel.error, "HistoryManager",
          "Failed to open history database: $e\n$s");
      return;
    }

    _db!.execute("""
        create table if not exists history  (
          target text primary key,
          title text,
          subtitle text,
          cover text,
          time int,
          type int,
          ep int,
          page int,
          readEpisode text,
          max_page int
        );
      """);

    // 检查是否有max_page字段, 如果没有则添加
    var res = _db!.select("""
      PRAGMA table_info(history);
    """);
    if (res.every((row) => row["name"] != "max_page")) {
      _db!.execute("""
        alter table history
        add column max_page int;
      """);
    }

    // 迁移早期版本的数据
    var file = File("${App.dataPath}/history.json");
    if (file.existsSync()) {
      readDataFromJson(jsonDecode(file.readAsStringSync()));
      file.deleteSync();
    }

    ImageFavoriteManager.init();
    unawaited(syncOhosWidgetHistory());
  }

  void readDataFromJson(List<dynamic> json) {
    var history = LinkedList<History>();
    for (var h in json) {
      history.add(History.fromMap((h as Map<String, dynamic>)));
    }
    // do not clear previous history
    for (var element in history) {
      if (findSync(element.target) == null) addHistory(element);
    }
    vacuum();
    unawaited(syncOhosWidgetHistory());
  }

  void saveData() async {
    Webdav.uploadData();
  }

  /// add history. if exists, update time.
  ///
  /// This function would be called when user start reading.
  Future<void> addHistory(History newItem) async {
    if (!_ensureDbAvailable()) {
      return;
    }
    var res = _db!.select("""
      select * from history
      where target == ?;
    """, [newItem.target]);
    if (res.isEmpty) {
      _db!.execute("""
        insert into history (target, title, subtitle, cover, time, type, ep, page, readEpisode, max_page)
        values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
      """, [
        newItem.target,
        newItem.title,
        newItem.subtitle,
        newItem.cover,
        newItem.time.millisecondsSinceEpoch,
        newItem.type.value,
        newItem.ep,
        newItem.page,
        newItem.readEpisode.join(','),
        newItem.maxPage
      ]);
    } else {
      _db!.execute("""
        update history
        set time = ${DateTime.now().millisecondsSinceEpoch}
        where target == ?;
      """, [newItem.target]);
    }
    saveData();
    updateCache();
    _scheduleOhosWidgetHistorySync();
  }

  ///退出阅读器时调用此函数, 修改阅读位置
  Future<void> saveReadHistory(History history,
      [bool updateMePage = true]) async {
    if (!_ensureDbAvailable()) {
      return;
    }
    _db!.execute("""
        update history
        set time = ${DateTime.now().millisecondsSinceEpoch}, ep = ?, page = ?, readEpisode = ?, max_page = ?
        where target == ?;
    """, [
      history.ep,
      history.page,
      history.readEpisode.join(','),
      history.maxPage,
      history.target
    ]);
    if (updateMePage) {
      scheduleMicrotask(() {
        StateController.findOrNull(tag: "me_page_history")?.update();
      });
    }
    updateCache();
    _scheduleOhosWidgetHistorySync();
  }

  void clearHistory() {
    if (!_ensureDbAvailable()) {
      return;
    }
    _db!.execute("delete from history;");
    updateCache();
    _scheduleOhosWidgetHistorySync();
  }

  void remove(String id) async {
    if (!_ensureDbAvailable()) {
      return;
    }
    _db!.execute("""
      delete from history
      where target == '$id';
    """);
    updateCache();
    _scheduleOhosWidgetHistorySync();
  }

  void _scheduleOhosWidgetHistorySync() {
    unawaited(syncOhosWidgetHistory());
    if (!PlatformUtils.isOhos) {
      return;
    }
    _ohosWidgetSyncDebounce?.cancel();
    _ohosWidgetSyncDebounce = Timer(const Duration(milliseconds: 800), () {
      unawaited(syncOhosWidgetHistory());
    });
  }

  Future<void> syncOhosWidgetHistory() async {
    if (!_ensureDbAvailable()) {
      await OhosWidgetService.instance.updateHistorySnapshot([]);
      return;
    }
    final histories = getRecent().take(6).toList();
    final existingCovers = _readOhosWidgetCoverSnapshotCache();
    final covers = await Future.wait(
      histories.map(
        (history) => _buildOhosWidgetCoverData(history).timeout(
          const Duration(seconds: 6),
          onTimeout: () => '',
        ),
      ),
    );
    final items =
        List<Map<String, Object?>>.generate(histories.length, (index) {
      final history = histories[index];
      final fallbackCover = existingCovers[_ohosWidgetCoverCacheKey(history)];
      return <String, Object?>{
        "title": history.title,
        "subtitle": history.subtitle,
        "cover": covers[index].isNotEmpty ? covers[index] : fallbackCover ?? '',
        "source": history.type.name,
        "progress": _formatOhosWidgetProgress(history),
        "time": _formatOhosWidgetTime(history.time),
        "target": history.target,
        "type": history.type.value,
        "ep": history.ep,
        "page": history.page,
      };
    });
    if (PlatformUtils.isOhos) {
      try {
        final snapshotFile =
            File("${App.dataPath}/widget_history_snapshot.json");
        snapshotFile.writeAsStringSync(_asciiJsonEncode(items));
      } catch (error, stack) {
        LogManager.addLog(
          LogLevel.error,
          "HistoryManager",
          "Failed to write OHOS widget history snapshot: $error\n$stack",
        );
      }
    }
    await OhosWidgetService.instance.updateHistorySnapshot(items);
  }

  String _resolveOhosWidgetCoverUrl(History history) {
    if (history.cover.isNotEmpty) {
      return history.cover;
    }
    if (history.type == HistoryType.jmComic) {
      return getJmCoverUrl(history.target);
    }
    return '';
  }

  Future<String> _buildOhosWidgetCoverData(History history) async {
    if (!PlatformUtils.isOhos) {
      return '';
    }
    final coverUrl = _resolveOhosWidgetCoverUrl(history);
    final sourceKey = history.type.comicSource?.key;
    if (coverUrl.isEmpty) {
      return '';
    }
    final cacheKey = _ohosWidgetCoverCacheKey(history);
    final cached = _ohosWidgetCoverDataCache[cacheKey];
    if (cached != null) {
      return cached;
    }
    try {
      DownloadProgress? finishedProgress;
      final stream = sourceKey == null
          ? ImageManager().getImage(coverUrl)
          : sourceKey == 'ehentai'
              ? await _getEhentaiWidgetCoverStream(coverUrl)
              : ImageManager().getCustomThumbnail(coverUrl, sourceKey);
      await for (final progress in stream) {
        if (progress.finished) {
          finishedProgress = progress;
        }
      }
      final imageBytes = finishedProgress?.data ??
          await finishedProgress?.getFile().readAsBytes();
      if (imageBytes == null || imageBytes.isEmpty) {
        return '';
      }
      final dataUri = await compute(_encodeOhosWidgetCoverDataUri, imageBytes);
      if (dataUri.isNotEmpty) {
        _ohosWidgetCoverDataCache[cacheKey] = dataUri;
      }
      return dataUri;
    } catch (error, stack) {
      LogManager.addLog(
        LogLevel.warning,
        "HistoryManager",
        "Failed to prepare OHOS widget cover: $coverUrl\n$error\n$stack",
      );
      return '';
    }
  }

  Future<Stream<DownloadProgress>> _getEhentaiWidgetCoverStream(
      String coverUrl) async {
    await EhNetwork().getCookies(false, coverUrl);
    return ImageManager().getImage(
      '$coverUrl#widget_cover',
      {
        'Cookie': EhNetwork().cookiesStr,
        'User-Agent': webUA,
        'Referer': EhNetwork().ehBaseUrl,
      },
    );
  }

  String _ohosWidgetCoverCacheKey(History history) =>
      '${history.type.value}:${history.target}';

  Map<String, String> _readOhosWidgetCoverSnapshotCache() {
    if (!PlatformUtils.isOhos) {
      return const {};
    }
    try {
      final snapshotFile = File("${App.dataPath}/widget_history_snapshot.json");
      if (!snapshotFile.existsSync()) {
        return const {};
      }
      final parsed = jsonDecode(snapshotFile.readAsStringSync());
      if (parsed is! List) {
        return const {};
      }
      final covers = <String, String>{};
      for (final item in parsed) {
        if (item is! Map) {
          continue;
        }
        final target = item['target'];
        final type = item['type'];
        final cover = item['cover'];
        if (target is String &&
            target.isNotEmpty &&
            type is num &&
            cover is String &&
            cover.isNotEmpty) {
          covers['${type.toInt()}:$target'] = cover;
        }
      }
      _ohosWidgetCoverDataCache.addAll(covers);
      return covers;
    } catch (_) {
      return const {};
    }
  }

  String _asciiJsonEncode(Object? value) {
    final json = jsonEncode(value);
    final buffer = StringBuffer();
    for (final rune in json.runes) {
      if (rune <= 0x7f) {
        buffer.writeCharCode(rune);
      } else if (rune <= 0xffff) {
        buffer.write(r"\u");
        buffer.write(rune.toRadixString(16).padLeft(4, "0"));
      } else {
        final code = rune - 0x10000;
        final high = 0xd800 + (code >> 10);
        final low = 0xdc00 + (code & 0x3ff);
        buffer
          ..write(r"\u")
          ..write(high.toRadixString(16).padLeft(4, "0"))
          ..write(r"\u")
          ..write(low.toRadixString(16).padLeft(4, "0"));
      }
    }
    return buffer.toString();
  }

  String _formatOhosWidgetProgress(History history) {
    final page = history.page <= 0 ? 1 : history.page;
    final ep = history.ep <= 0 ? 1 : history.ep;
    if (history.maxPage != null && history.maxPage! > 0) {
      return "第$ep话 · $page/${history.maxPage}页";
    }
    return "第$ep话 · 第$page页";
  }

  String _formatOhosWidgetTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);
    final days = today.difference(date).inDays;
    if (days <= 0) {
      return "今天";
    }
    if (days == 1) {
      return "昨天";
    }
    if (days < 7) {
      return "$days天前";
    }
    return "${time.month}/${time.day}";
  }

  Future<History?> find(String target) async {
    return findSync(target);
  }

  void updateCache() {
    if (!_ensureDbAvailable()) {
      _cachedHistory = {};
      return;
    }
    _cachedHistory = {};
    var res = _db!.select("""
        select * from history;
      """);
    for (var element in res) {
      _cachedHistory![element["target"] as String] = true;
    }
  }

  History? findSync(String target) {
    if (_cachedHistory == null) {
      updateCache();
    }
    if (!_cachedHistory!.containsKey(target)) {
      return null;
    }

    if (!_ensureDbAvailable()) {
      return null;
    }
    var res = _db!.select("""
      select * from history
      where target == ?;
    """, [target]);
    if (res.isEmpty) {
      return null;
    }
    return History.fromRow(res.first);
  }

  List<History> getAll() {
    if (!_ensureDbAvailable()) {
      return [];
    }
    var res = _db!.select("""
      select * from history
      order by time DESC;
    """);
    return res.map((element) => History.fromRow(element)).toList();
  }

  void vacuum() {
    if (!_ensureDbAvailable()) {
      return;
    }
    _db!.execute("""
      vacuum;
    """);
  }

  /// 获取最近一周的阅读数据, 用于生成图表, List中的元素是当天阅读的漫画数量
  List<int> getWeekData(int days) {
    if (!_ensureDbAvailable()) {
      return List<int>.filled(days, 0);
    }
    var res = _db!.select("""
      select * from history
      where time > ${DateTime.now().add(Duration(days: 1 - days)).millisecondsSinceEpoch}
      order by time ASC;
    """);
    var data = List<int>.filled(days, 0);
    for (var element in res) {
      var time = DateTime.fromMillisecondsSinceEpoch(element["time"] as int);
      data[DateTime.now().difference(time).inDays]++;
    }
    return data.reversed.toList();
  }

  /// 获取最近阅读的漫画
  List<History> getRecent() {
    if (!_ensureDbAvailable()) {
      return [];
    }
    var res = _db!.select("""
      select * from history
      order by time DESC
      limit 20;
    """);
    return res.map((element) => History.fromRow(element)).toList();
  }

  /// 获取历史记录的数量
  int count() {
    if (!_ensureDbAvailable()) {
      return 0;
    }
    var res = _db!.select("""
      select count(*) from history;
    """);
    return res.first[0] as int;
  }

  /// Get plain search keyword from a keyword that may be polluted.
  static String getPlainSearchKeyword(String keyword) {
    // remove language filter
    // final languagePattern = RegExp(r'\s*language:\w+');
    // var result = keyword.replaceAll(languagePattern, '').trim();
    var result = keyword;

    // remove jm blocking keywords
    if (appdata.jmBlockingKeyword.isNotEmpty) {
      var words = result.trim().split(' ').where((s) => s.isNotEmpty);
      var userWords = <String>[];
      var jmBlockingSet = appdata.jmBlockingKeyword.toSet();
      for (var word in words) {
        if (word.startsWith('-') && jmBlockingSet.contains(word.substring(1))) {
          // is a blocking keyword, skip it
        } else {
          userWords.add(word);
        }
      }
      result = userWords.join(' ');
    }

    return result;
  }

  /// Add search history
  static void addSearchHistory(String keyword) {
    if (keyword.trim().isEmpty) return;

    if (appdata.searchHistory.contains(keyword)) {
      appdata.searchHistory.remove(keyword);
    }
    appdata.searchHistory.add(keyword);
    appdata.writeSearchHistory();
    appdata.writeHistory();
  }
}

String _encodeOhosWidgetCoverDataUri(Uint8List bytes) {
  final decoded = image.decodeImage(bytes);
  if (decoded == null) {
    return '';
  }
  final oriented = image.bakeOrientation(decoded);
  const targetWidth = 90;
  const targetHeight = 120;
  final scale = max(
    targetWidth / oriented.width,
    targetHeight / oriented.height,
  );
  final resized = image.copyResize(
    oriented,
    width: (oriented.width * scale).ceil(),
    height: (oriented.height * scale).ceil(),
    interpolation: image.Interpolation.average,
  );
  final cropped = image.copyCrop(
    resized,
    x: max(0, (resized.width - targetWidth) ~/ 2),
    y: max(0, (resized.height - targetHeight) ~/ 2),
    width: targetWidth,
    height: targetHeight,
  );
  final encoded = image.encodeJpg(cropped, quality: 68);
  return 'data:image/jpeg;base64,${base64Encode(encoded)}';
}

import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/comic_source/comic_source.dart';
import 'package:pica_comic/network/download_model.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/jm_network/jm_network.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/network/nhentai_network/download.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/network/picacg_network/models.dart' as pica;
import 'package:pica_comic/network/picacg_network/picacg_download_model.dart';
import 'package:pica_comic/network/jm_network/jm_download.dart';
import 'package:pica_comic/network/eh_network/eh_download_model.dart';
import 'package:pica_comic/network/custom_download_model.dart';

/// 漫画评论获取
///
/// 根据已下载漫画的类型, 调用对应漫画源的网络接口获取评论,
/// 仅返回文字内容 (userName, content, time, 可选 replyTo).
class ComicCommentsHelper {
  /// 判断已下载项是否支持获取漫画普通评论
  static bool supports(DownloadedItem item) {
    if (item is DownloadedComic) return true;
    if (item is DownloadedJmComic) return true;
    if (item is DownloadedGallery) return true;
    if (item is NhentaiDownloadedComic) return true;
    if (item is CustomDownloadedItem) {
      return ComicSource.find(item.sourceKey)?.commentsLoader != null;
    }
    return false;
  }

  /// 获取已下载项对应的漫画源 key
  static String getSourceKey(DownloadedItem item) {
    if (item is CustomDownloadedItem) return item.sourceKey;
    switch (item.type) {
      case DownloadType.picacg:
        return "picacg";
      case DownloadType.ehentai:
        return "ehentai";
      case DownloadType.jm:
        return "jm";
      case DownloadType.hitomi:
        return "hitomi";
      case DownloadType.htmanga:
        return "htmanga";
      case DownloadType.nhentai:
        return "nhentai";
      case DownloadType.other:
        return "other";
      case DownloadType.favorite:
        return "favorite";
    }
  }

  /// 获取用于评论存储的漫画 ID (不含源前缀)
  static String getComicId(DownloadedItem item) {
    if (item is DownloadedComic) return item.id;
    if (item is DownloadedJmComic) return item.comic.id;
    if (item is DownloadedGallery) return item.id;
    if (item is NhentaiDownloadedComic) return item.comicID;
    if (item is CustomDownloadedItem) return item.comicId;
    return item.id;
  }

  /// 获取已下载项的所有漫画普通评论 (仅文字), 失败返回 null
  static Future<List<Map<String, dynamic>>?> fetchForDownloadedItem(
      DownloadedItem item) async {
    try {
      if (item is DownloadedComic) {
        return await _fetchPicacg(item.id);
      } else if (item is DownloadedJmComic) {
        return await _fetchJm(item.comic.id);
      } else if (item is DownloadedGallery) {
        return await _fetchEh(item.gallery.link);
      } else if (item is NhentaiDownloadedComic) {
        return await _fetchNhentai(item.comicID);
      } else if (item is CustomDownloadedItem) {
        var source = ComicSource.find(item.sourceKey);
        if (source?.commentsLoader == null) return null;
        return await _fetchCustom(source!, item.comicId, item.subId);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// picacg: 分页拉取全部评论
  static Future<List<Map<String, dynamic>>> _fetchPicacg(String id) async {
    var comments = pica.Comments([], id, 1, 0);
    var firstRes = await network.loadMoreCommends(comments);
    if (firstRes.error) return [];
    while (comments.loaded != comments.pages) {
      var res = await network.loadMoreCommends(comments);
      if (res.error) break;
    }
    return comments.comments
        .map((c) => <String, dynamic>{
              'userName': c.name,
              'content': c.text,
              'time': c.time,
            })
        .toList();
  }

  /// jm: 分页拉取全部评论 (含回复)
  static Future<List<Map<String, dynamic>>> _fetchJm(String id) async {
    var allComments = <Map<String, dynamic>>[];
    var page = 1;
    var total = -1;
    while (true) {
      var res = await jmNetwork.getComment(id, page);
      if (res.error) break;
      if (total < 0) total = res.subData ?? 0;
      for (var c in res.data) {
        allComments.add({
          'userName': c.name,
          'content': c.content,
          'time': c.time,
        });
        for (var r in c.reply) {
          allComments.add({
            'userName': r.name,
            'content': r.content,
            'time': r.time,
            'replyTo': c.name,
          });
        }
      }
      if (res.data.isEmpty) break;
      if (total > 0 && allComments.length >= total) break;
      page++;
    }
    return allComments;
  }

  /// ehentai: 一次性拉取全部评论
  static Future<List<Map<String, dynamic>>> _fetchEh(String url) async {
    var res = await EhNetwork().getComments(url);
    if (res.error) return [];
    return res.data
        .map((c) => <String, dynamic>{
              'userName': c.name,
              'content': c.content,
              'time': c.time,
            })
        .toList();
  }

  /// nhentai: 一次性拉取全部评论
  static Future<List<Map<String, dynamic>>> _fetchNhentai(String id) async {
    var res = await NhentaiNetwork().getComments(id);
    if (res.error) return [];
    return res.data
        .map((c) => <String, dynamic>{
              'userName': c.userName,
              'content': c.content,
              'time': c.date > 0
                  ? DateTime.fromMillisecondsSinceEpoch(c.date * 1000)
                      .toIso8601String()
                  : null,
            })
        .toList();
  }

  /// 自定义源: 分页拉取全部评论
  static Future<List<Map<String, dynamic>>> _fetchCustom(
      ComicSource source, String comicId, String? subId) async {
    var allComments = <Map<String, dynamic>>[];
    var page = 1;
    int? maxPage;
    while (true) {
      var res = await source.commentsLoader!(comicId, subId, page, null);
      if (res.error) break;
      allComments.addAll(res.data.map((c) => <String, dynamic>{
            'userName': c.userName,
            'content': c.content,
            'time': c.time,
          }));
      if (maxPage == null) maxPage = res.subData;
      if (res.data.isEmpty) break;
      if (maxPage != null && page >= maxPage) break;
      page++;
    }
    return allComments;
  }

  /// 获取并保存评论到本地, 仅在内容变化时写入
  /// 返回 true 表示有更新 (新保存), false 表示无变化或失败
  static Future<bool> fetchAndSave(DownloadedItem item) async {
    var comments = await fetchForDownloadedItem(item);
    // 空结果通常是网络失败, 不保存以免误清空已有评论
    if (comments == null || comments.isEmpty) return false;
    var saved = await ComicCommentsStorage.saveComments(
      sourceKey: getSourceKey(item),
      comicId: getComicId(item),
      comments: comments,
      comicName: item.name,
    );
    return saved;
  }
}

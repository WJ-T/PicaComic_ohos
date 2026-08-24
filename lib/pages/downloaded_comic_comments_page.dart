import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/components/comment.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/comic_comments_helper.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/download_model.dart';
import 'package:pica_comic/utils/translations.dart';

/// 已下载漫画的普通评论查看页
///
/// 优先展示本地保存的文字评论, 打开时自动联网更新;
/// 若联网获取到新评论则更新本地存储.
class DownloadedComicCommentsPage extends StatefulWidget {
  final DownloadedItem item;

  const DownloadedComicCommentsPage(this.item, {super.key});

  @override
  State<DownloadedComicCommentsPage> createState() =>
      _DownloadedComicCommentsPageState();
}

class _DownloadedComicCommentsPageState
    extends State<DownloadedComicCommentsPage> {
  List<Map<String, dynamic>>? savedComments;
  bool loading = true;
  bool refreshing = false;
  String? error;

  String get _sourceKey => ComicCommentsHelper.getSourceKey(widget.item);
  String get _comicId => ComicCommentsHelper.getComicId(widget.item);

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    var comments =
        await ComicCommentsStorage.loadComments(_sourceKey, _comicId);
    if (!mounted) return;
    setState(() {
      savedComments = comments;
      loading = false;
    });
    _refreshOnline();
  }

  Future<void> _refreshOnline() async {
    // Re-read from DB to get the latest version (e.g. subId auto-migrated
    // during episode refresh for old CustomDownloadedItem downloads).
    // This ensures comment APIs that rely on subId (e.g. copy_manga) get
    // the correct id instead of null.
    var latest = await DownloadManager().getComicOrNull(widget.item.id);
    var item = latest ?? widget.item;
    if (!ComicCommentsHelper.supports(item)) return;
    if (mounted) setState(() => refreshing = true);
    try {
      var fetched = await ComicCommentsHelper.fetchForDownloadedItem(item);
      // 空结果通常是网络失败 (自定义源会返回 [] 而非抛异常),
      // 不要用空列表覆盖已保存的评论, 避免断网时清空本地数据.
      if (fetched != null && fetched.isNotEmpty) {
        var saved = await ComicCommentsStorage.saveComments(
          sourceKey: _sourceKey,
          comicId: _comicId,
          comments: fetched,
          comicName: item.name,
        );
        if (saved) {
          var updated =
              await ComicCommentsStorage.loadComments(_sourceKey, _comicId);
          if (!mounted) return;
          setState(() {
            savedComments = updated;
            refreshing = false;
          });
          return;
        }
      }
      if (!mounted) return;
      setState(() => refreshing = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    var comments = savedComments;
    if (comments == null || comments.isEmpty) {
      return Column(
        children: [
          _buildRefreshHeader(),
          Expanded(
            child: Center(
              child: Text("暂无评论".tl),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        _buildRefreshHeader(),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  childCount: comments.length,
                  (context, index) {
                    var c = comments[index];
                    var replyTo = c['replyTo'] as String?;
                    var content = c['content'] as String? ?? '';
                    if (replyTo != null && replyTo.isNotEmpty) {
                      content = "${"回复".tl} @$replyTo：\n$content";
                    }
                    return CommentTile(
                      avatarUrl: null,
                      name: c['userName'] as String? ?? "",
                      content: content,
                      time: c['time'] as String?,
                    );
                  },
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(App.globalContext!).padding.bottom),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRefreshHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          if (refreshing)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          Expanded(
            child: Text(
              refreshing ? "正在更新评论...".tl : "已保存的评论".tl,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          IconButton(
            onPressed: refreshing ? null : () => _refreshOnline(),
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: "刷新".tl,
          ),
        ],
      ),
    );
  }
}

void showDownloadedComicComments(BuildContext context, DownloadedItem item) {
  showSideBar(
    context,
    DownloadedComicCommentsPage(item),
    title: "评论".tl,
  );
}

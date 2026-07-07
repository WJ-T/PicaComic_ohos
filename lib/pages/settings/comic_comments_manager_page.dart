part of pica_settings;

/// 漫画普通评论
class _ComicCommentItem {
  final String sourceKey;
  final String comicId;
  final String? comicName;
  final DateTime? savedAt;
  final int fileSize;
  final List<dynamic> comments;
  final String filePath;

  _ComicCommentItem({
    required this.sourceKey,
    required this.comicId,
    this.comicName,
    this.savedAt,
    required this.fileSize,
    required this.comments,
    required this.filePath,
  });

  String get displayName => comicName ?? comicId;
}

class ComicCommentsManagerPage extends StatefulWidget {
  const ComicCommentsManagerPage({super.key});

  @override
  State<ComicCommentsManagerPage> createState() =>
      _ComicCommentsManagerPageState();
}

class _ComicCommentsManagerPageState extends State<ComicCommentsManagerPage> {
  List<_ComicCommentItem> _comics = [];
  List<_ComicCommentItem> _filteredComics = [];
  bool _loading = true;
  int _totalSize = 0;
  int _currentPage = 1;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    var allComments = await ComicCommentsStorage.getAllSavedComments();

    var comics = <_ComicCommentItem>[];
    for (var data in allComments) {
      var savedAtStr = data['savedAt'] as String?;
      DateTime? savedAt;
      if (savedAtStr != null) {
        try {
          savedAt = DateTime.parse(savedAtStr);
        } catch (_) {}
      }
      comics.add(_ComicCommentItem(
        sourceKey: data['sourceKey'] as String? ?? '',
        comicId: data['comicId'] as String? ?? '',
        comicName: data['comicName'] as String?,
        savedAt: savedAt,
        fileSize: data['fileSize'] as int? ?? 0,
        comments: data['comments'] as List<dynamic>? ?? [],
        filePath: data['filePath'] as String? ?? '',
      ));
    }

    // 按保存时间排序, 最新的在前
    comics.sort((a, b) =>
        (b.savedAt ?? DateTime(0)).compareTo(a.savedAt ?? DateTime(0)));

    var totalSize = comics.fold(0, (sum, c) => sum + c.fileSize);

    setState(() {
      _comics = comics;
      _totalSize = totalSize;
      _loading = false;
      _rebuildComicView();
    });
  }

  int get _maxPage =>
      _calculatePageCount(_filteredComics.length, _comicCommentsPageSize);

  int get _totalComments =>
      _comics.fold(0, (sum, c) => sum + c.comments.length);

  int get _filteredComments =>
      _filteredComics.fold(0, (sum, c) => sum + c.comments.length);

  List<_ComicCommentItem> get _pageComics =>
      _slicePageItems(_filteredComics, _currentPage, _comicCommentsPageSize);

  bool _matchesComic(_ComicCommentItem comic, String keyword) {
    return comic.displayName.toLowerCase().contains(keyword) ||
        comic.comicId.toLowerCase().contains(keyword) ||
        comic.sourceKey.toLowerCase().contains(keyword);
  }

  void _rebuildComicView({bool resetPage = false}) {
    var keyword = _searchController.text.trim().toLowerCase();
    _filteredComics = keyword.isEmpty
        ? List<_ComicCommentItem>.from(_comics)
        : _comics.where((comic) => _matchesComic(comic, keyword)).toList();

    if (_filteredComics.isEmpty) {
      _currentPage = 1;
      return;
    }

    _currentPage = resetPage ? 1 : _normalizePage(_currentPage, _maxPage);
  }

  void _onSearchChanged(String _) {
    setState(() {
      _rebuildComicView(resetPage: true);
    });
  }

  void _nextPage() {
    if (_currentPage >= _maxPage) {
      showToast(message: "已经是最后一页了".tl);
      return;
    }
    setState(() {
      _currentPage++;
    });
  }

  void _prevPage() {
    if (_currentPage <= 1) {
      showToast(message: "已经是第一页了".tl);
      return;
    }
    setState(() {
      _currentPage--;
    });
  }

  Future<void> _selectPage() async {
    await _selectManagerPage(
      context: context,
      maxPage: _maxPage,
      onSelected: (page) {
        setState(() {
          _currentPage = page;
        });
      },
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB";
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "";
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _deleteComic(_ComicCommentItem comic) async {
    var displayName = comic.displayName;
    var confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("确认删除".tl),
        content: Text("确定要删除《$displayName》的 ${comic.comments.length} 条评论吗？".tl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("取消".tl),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("删除".tl,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      var success = await ComicCommentsStorage.deleteComicComments(
          comic.sourceKey, comic.comicId);
      if (success) {
        await _loadData();
        if (mounted) {
          context.showMessage(message: "删除成功".tl);
        }
      } else {
        if (mounted) {
          context.showMessage(message: "删除失败".tl);
        }
      }
    }
  }

  Future<void> _deleteAll() async {
    var confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("确认删除全部".tl),
        content: Text("确定要删除所有已保存的普通评论吗？此操作不可恢复。".tl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("取消".tl),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("全部删除".tl,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        var baseDir = Directory("${App.dataPath}/comic_comments");
        if (await baseDir.exists()) {
          await baseDir.delete(recursive: true);
        }
        await _loadData();
        if (mounted) {
          context.showMessage(message: "已全部删除".tl);
        }
      } catch (e) {
        if (mounted) {
          context.showMessage(message: "删除失败: $e".tl);
        }
      }
    }
  }

  void _viewComic(_ComicCommentItem comic) {
    context.to(() => _ComicCommentsDetailPage(comic: comic));
  }

  @override
  Widget build(BuildContext context) {
    var pageComics = _pageComics;
    var hasKeyword = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: Appbar(
        title: Text("已保存的普通评论".tl),
        actions: [
          if (_comics.isNotEmpty)
            IconButton(
              onPressed: _deleteAll,
              icon: const Icon(Icons.delete_forever),
              tooltip: "全部删除".tl,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _comics.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 16),
                      Text("暂无已保存的评论".tl,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.outline)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.storage,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "共 ${_filteredComics.length} / ${_comics.length} 个漫画, $_filteredComments / $_totalComments 条评论"
                                      .tl,
                                ),
                                Text("占用空间: ${_formatSize(_totalSize)}".tl,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: _buildManagerSearchBox(
                        context: context,
                        controller: _searchController,
                        hintText: "搜索漫画名或 ID",
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    if (_filteredComics.isNotEmpty)
                      _buildManagerPageSelector(
                        context: context,
                        currentPage: _currentPage,
                        totalPages: _maxPage,
                        onPrevPage: _prevPage,
                        onNextPage: _nextPage,
                        onSelectPage: _selectPage,
                      ),
                    Expanded(
                      child: _filteredComics.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off,
                                      size: 64,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline),
                                  const SizedBox(height: 16),
                                  Text(
                                    hasKeyword ? "没有匹配的搜索结果".tl : "暂无已保存的评论".tl,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              itemCount: pageComics.length,
                              itemBuilder: (context, index) {
                                var comic = pageComics[index];
                                var subtitle = comic.comicName != null
                                    ? "${comic.sourceKey} · ${comic.comments.length}条评论"
                                    : "来源: ${comic.sourceKey} · ${comic.comments.length}条评论";

                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      child: Text(
                                        comic.displayName.isNotEmpty
                                            ? comic.displayName
                                                .substring(0, 1)
                                                .toUpperCase()
                                            : "?",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      comic.displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                        "$subtitle · ${_formatDate(comic.savedAt)}"
                                            .tl),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () => _viewComic(comic),
                                          icon: const Icon(Icons.visibility),
                                          tooltip: "查看评论".tl,
                                        ),
                                        IconButton(
                                          onPressed: () => _deleteComic(comic),
                                          icon: Icon(Icons.delete,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error),
                                          tooltip: "删除".tl,
                                        ),
                                      ],
                                    ),
                                    onTap: () => _viewComic(comic),
                                  ),
                                );
                              },
                            ),
                    ),
                    if (_filteredComics.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildManagerPageSelector(
                          context: context,
                          currentPage: _currentPage,
                          totalPages: _maxPage,
                          onPrevPage: _prevPage,
                          onNextPage: _nextPage,
                          onSelectPage: _selectPage,
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _ComicCommentsDetailPage extends StatefulWidget {
  final _ComicCommentItem comic;

  const _ComicCommentsDetailPage({required this.comic});

  @override
  State<_ComicCommentsDetailPage> createState() =>
      _ComicCommentsDetailPageState();
}

class _ComicCommentsDetailPageState extends State<_ComicCommentsDetailPage> {
  late List<Map<String, dynamic>> _comments;

  @override
  void initState() {
    super.initState();
    _comments = widget.comic.comments
        .map((c) => Map<String, dynamic>.from(c as Map))
        .toList();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "";
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Appbar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.comic.displayName,
                style: const TextStyle(fontSize: 18)),
            Text(
              "${widget.comic.sourceKey} · ${_comments.length}条评论 · ${_formatDate(widget.comic.savedAt)}"
                  .tl,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: _comments.isEmpty
          ? Center(
              child: Text("暂无评论".tl,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.outline)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                var comment = _comments[index];
                var replyTo = comment['replyTo'] as String?;
                var content = comment['content'] as String? ?? "";
                if (replyTo != null && replyTo.isNotEmpty) {
                  content = "${"回复".tl} @$replyTo：\n$content";
                }
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Text(
                                (comment['userName'] as String? ?? "?")
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                comment['userName'] as String? ?? "Unknown".tl,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (comment['time'] != null)
                              Flexible(
                                child: Text(
                                  comment['time'].toString(),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(content),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

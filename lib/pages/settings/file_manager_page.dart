import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:pica_comic/components/components.dart';
import 'package:share_plus/share_plus.dart' as s;
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/utils/translations.dart';

class FileManagerPage extends StatefulWidget {
  const FileManagerPage({super.key});

  @override
  State<FileManagerPage> createState() => _FileManagerPageState();
}

class _FileManagerPageState extends State<FileManagerPage> {
  Directory? rootDir;
  Directory? currentDir;
  List<FileSystemEntity> entries = [];
  bool loading = true;
  List<Directory> navigationStack = [];
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initRoot();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initRoot() async {
    final dir = Directory(App.dataPath);
    if (!dir.existsSync()) {
      setState(() => loading = false);
      return;
    }
    rootDir = dir;
    currentDir = dir;
    navigationStack = [dir];
    await _loadDirectory(dir);
  }

  Future<void> _loadDirectory(Directory dir) async {
    setState(() {
      loading = true;
      searchQuery = '';
      _searchController.clear();
    });
    try {
      final list = await dir.list().toList();
      list.sort((a, b) {
        final aIsDir = a is Directory;
        final bIsDir = b is Directory;
        if (aIsDir != bIsDir) return aIsDir ? -1 : 1;
        return a.path.split(Platform.pathSeparator).last
            .compareTo(b.path.split(Platform.pathSeparator).last);
      });
      entries = list;
      currentDir = dir;
    } catch (e) {
      entries = [];
    }
    setState(() => loading = false);
  }

  void _navigateTo(Directory dir) {
    navigationStack.add(dir);
    _loadDirectory(dir);
  }

  bool _navigateBack() {
    if (navigationStack.length <= 1) return false;
    navigationStack.removeLast();
    _loadDirectory(navigationStack.last);
    return true;
  }

  String _entityName(FileSystemEntity e) {
    return e.path.split(Platform.pathSeparator).last;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<int> _dirSize(Directory dir) async {
    int total = 0;
    try {
      await for (final e in dir.list(recursive: true)) {
        if (e is File) {
          try { total += await e.length(); } catch (_) {}
        }
      }
    } catch (_) {}
    return total;
  }

  Future<String> _entityDetail(FileSystemEntity e) async {
    final name = _entityName(e);
    if (e is File) {
      try {
        final stat = await e.stat();
        return '$name\n${_formatSize(stat.size)}\n${_formatDate(stat.modified)}';
      } catch (_) {
        return name;
      }
    } else {
      final size = await _dirSize(e as Directory);
      return '$name\n${_formatSize(size)}\n${'文件夹'.tl}';
    }
  }

  void _showEntityActions(FileSystemEntity e) {
    final isDir = e is Directory;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(isDir ? Icons.folder : Icons.insert_drive_file,
                      color: context.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _entityName(e),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (isDir)
              ListTile(
                leading: const Icon(Icons.arrow_forward),
                title: Text('打开'.tl),
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateTo(e as Directory);
                },
              ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text('详细信息'.tl),
              onTap: () {
                Navigator.pop(ctx);
                _showDetail(e);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text('复制路径'.tl),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: e.path));
                context.showMessage(message: '路径已复制'.tl);
              },
            ),
            if (!isDir && _isTextFile(e as File))
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text('查看/编辑'.tl),
                onTap: () {
                  Navigator.pop(ctx);
                  _viewOrEditFile(e as File);
                },
              ),
            if (!isDir && _isImageFile(e as File))
              ListTile(
                leading: const Icon(Icons.image),
                title: Text('查看图片'.tl),
                onTap: () {
                  Navigator.pop(ctx);
                  _viewImage(e as File);
                },
              ),
            if (!isDir)
              ListTile(
                leading: const Icon(Icons.photo),
                title: Text('强制以图片打开'.tl),
                onTap: () {
                  Navigator.pop(ctx);
                  _viewImage(e as File);
                },
              ),
            if (!isDir)
              ListTile(
                leading: const Icon(Icons.share),
                title: Text('分享'.tl),
                onTap: () {
                  Navigator.pop(ctx);
                  s.Share.shareXFiles([s.XFile((e as File).path)]);
                },
              ),
            ListTile(
              leading: Icon(Icons.delete, color: context.colorScheme.error),
              title: Text('删除'.tl,
                  style: TextStyle(color: context.colorScheme.error)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(e);
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isTextFile(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    return {
      'txt', 'json', 'xml', 'yaml', 'yml', 'csv', 'log', 'md',
      'ini', 'cfg', 'conf', 'properties', 'html', 'css', 'js',
      'ts', 'dart', 'java', 'py', 'sh', 'bat', 'sql',
    }.contains(ext);
  }

  bool _isImageFile(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    return {
      'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg',
    }.contains(ext);
  }

  void _viewImage(File file) {
    context.to(() => _ImageViewerPage(file));
  }

  void _showDetail(FileSystemEntity e) async {
    final detail = await _entityDetail(e);
    showDialog(
      context: context,
      builder: (ctx) => ContentDialog(
        title: '详细信息'.tl,
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SelectableText(detail, style: const TextStyle(fontSize: 14)),
        ),
        actions: [
          Button.filled(
            onPressed: () => Navigator.pop(ctx),
            child: Text('关闭'.tl),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(FileSystemEntity e) {
    final name = _entityName(e);
    showDialog(
      context: context,
      builder: (ctx) => ContentDialog(
        title: '确认删除'.tl,
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('确定要删除 $name 吗？此操作不可恢复。'.tl),
        ),
        actions: [
          Button.text(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消'.tl),
          ),
          Button.filled(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                if (e is Directory) {
                  await e.delete(recursive: true);
                } else {
                  await e.delete();
                }
                if (mounted) {
                  context.showMessage(message: '已删除'.tl);
                  _loadDirectory(currentDir!);
                }
              } catch (err) {
                if (mounted) {
                  context.showMessage(message: '删除失败: $err');
                }
              }
            },
            child: Text('删除'.tl),
          ),
        ],
      ),
    );
  }

  void _viewOrEditFile(File file) async {
    try {
      final content = await file.readAsString();
      if (!mounted) return;
      final controller = TextEditingController(text: content);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          contentPadding: const EdgeInsets.all(16),
          title: Row(
            children: [
              Expanded(child: Text(_entityName(file), style: const TextStyle(fontSize: 14))),
              Text('${content.length} chars',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(ctx).size.width * 0.9,
            height: MediaQuery.of(ctx).size.height * 0.6,
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('关闭'.tl),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await file.writeAsString(controller.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    context.showMessage(message: '已保存'.tl);
                  }
                } catch (err) {
                  if (mounted) {
                    context.showMessage(message: '保存失败: $err');
                  }
                }
              },
              child: Text('保存'.tl),
            ),
          ],
        ),
      );
    } catch (err) {
      if (mounted) {
        context.showMessage(message: '读取失败: $err');
      }
    }
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索当前目录,如搜索2级目录请点进去搜'.tl,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => searchQuery = '');
                  },
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: (value) => setState(() => searchQuery = value),
      ),
    );
  }

  List<FileSystemEntity> get _filteredEntries {
    if (searchQuery.isEmpty) return entries;
    final query = searchQuery.toLowerCase();
    return entries.where((e) => _entityName(e).toLowerCase().contains(query)).toList();
  }

  Widget _buildBreadcrumb() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: navigationStack.length,
        separatorBuilder: (_, __) => const Icon(Icons.chevron_right, size: 16),
        itemBuilder: (context, index) {
          final dir = navigationStack[index];
          final isLast = index == navigationStack.length - 1;
          final name = index == 0
              ? (App.isAndroid ? 'data' : dir.path.split(Platform.pathSeparator).last)
              : _entityName(dir);
          return InkWell(
            onTap: isLast ? null : () {
              navigationStack.removeRange(index + 1, navigationStack.length);
              _loadDirectory(dir);
            },
            child: Center(
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                  color: isLast ? context.colorScheme.primary : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: navigationStack.length <= 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _navigateBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('文件管理器'.tl),
        ),
        body: Column(
          children: [
            _buildBreadcrumb(),
            const Divider(height: 1),
            _buildSearchField(),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredEntries.isEmpty
                      ? Center(child: Text('无结果'.tl))
                      : ListView.builder(
                          itemCount: _filteredEntries.length,
                          itemBuilder: (context, index) {
                            final e = _filteredEntries[index];
                            final isDir = e is Directory;
                            return ListTile(
                              leading: Icon(
                                isDir ? Icons.folder : _fileIcon(e as File),
                                color: isDir ? Colors.amber[700] : Colors.blue[400],
                              ),
                              title: Text(_entityName(e)),
                              subtitle: FutureBuilder<String>(
                                future: _entityDetail(e),
                                builder: (_, snap) {
                                  if (!snap.hasData) return const SizedBox();
                                  final lines = snap.data!.split('\n');
                                  return Text(
                                    lines.length > 1 ? lines[1] : '',
                                    style: const TextStyle(fontSize: 12),
                                  );
                                },
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () => _showEntityActions(e),
                              ),
                              onTap: isDir
                                  ? () => _navigateTo(e as Directory)
                                  : !isDir && _isImageFile(e as File)
                                      ? () => _viewImage(e)
                                      : !isDir && _isTextFile(e as File)
                                          ? () => _viewOrEditFile(e)
                                          : () => _showEntityActions(e),
                              onLongPress: () => _showEntityActions(e),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _fileIcon(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'webm':
        return Icons.movie;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'ogg':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.archive;
      case 'json':
      case 'xml':
      case 'yaml':
      case 'yml':
      case 'txt':
      case 'log':
      case 'md':
        return Icons.description;
      case 'db':
      case 'sqlite':
      case 'sql':
        return Icons.storage;
      default:
        return Icons.insert_drive_file;
    }
  }
}

class _ImageViewerPage extends StatelessWidget {
  const _ImageViewerPage(this.file);

  final File file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(file.path.split(Platform.pathSeparator).last),
      ),
      body: PhotoView(
        minScale: PhotoViewComputedScale.contained * 0.9,
        imageProvider: FileImage(file),
        loadingBuilder: (context, event) {
          return Container(
            color: Colors.black,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stackTrace, retry) {
          return Center(child: Text('无法加载图片'.tl));
        },
      ),
    );
  }
}

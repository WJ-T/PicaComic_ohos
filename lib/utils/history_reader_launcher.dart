import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/app_page_route.dart';
import 'package:pica_comic/foundation/comic_source/comic_source.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_main_network.dart';
import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/network/jm_network/jm_network.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/pages/reader/comic_reading_page.dart';
import 'package:pica_comic/utils/translations.dart';

class HistoryReaderLaunchPage extends StatefulWidget {
  const HistoryReaderLaunchPage({
    super.key,
    required this.type,
    required this.target,
    required this.ep,
    required this.page,
  });

  final int type;
  final String target;
  final int ep;
  final int page;

  @override
  State<HistoryReaderLaunchPage> createState() =>
      _HistoryReaderLaunchPageState();
}

class _HistoryReaderLaunchPageState extends State<HistoryReaderLaunchPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_open());
      }
    });
  }

  Future<void> _open() async {
    final page = await buildHistoryReaderPage(
      type: widget.type,
      target: widget.target,
      ep: widget.ep,
      page: widget.page,
    );
    if (!mounted) {
      return;
    }
    if (page == null) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }
    Navigator.of(context).pushReplacement(
      AppPageRoute(
        builder: (_) => page,
        settings: const RouteSettings(name: '/ComicReadingPage'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('正在打开阅读记录'.tl),
          ],
        ),
      ),
    );
  }
}

Future<Widget?> buildHistoryReaderPage({
  required int type,
  required String target,
  required int ep,
  required int page,
}) async {
  if (target.isEmpty) {
    showToast(message: '历史记录无效'.tl);
    return null;
  }

  final history = HistoryManager().findSync(target);
  final readEp = ep > 0 ? ep : (history?.ep ?? 1);
  final readPage = page > 0 ? page : (history?.page ?? 1);
  final historyType = HistoryType(type);

  try {
    if (historyType == HistoryType.picacg) {
      final res = await PicacgNetwork().getComicInfo(target);
      if (res.error) {
        showToast(message: res.errorMessageWithoutNull);
        return null;
      }
      final comic = res.data;
      return ComicReadingPage.picacg(
        target,
        readEp,
        comic.eps,
        comic.title,
        initialPage: readPage,
        historySubTitle: comic.subTitle,
        historyCover: comic.cover,
      );
    }

    if (historyType == HistoryType.ehentai) {
      final res =
          await EhNetwork().getGalleryInfo(target, appdata.settings[47] == '1');
      if (res.error) {
        showToast(message: res.errorMessageWithoutNull);
        return null;
      }
      return ComicReadingPage.ehentai(res.data, initialPage: readPage);
    }

    if (historyType == HistoryType.jmComic) {
      final res = await JmNetwork().getComicInfo(target);
      if (res.error) {
        showToast(message: res.errorMessageWithoutNull);
        return null;
      }
      return ComicReadingPage.jmComic(
        res.data,
        readEp,
        initialPage: readPage,
      );
    }

    if (historyType == HistoryType.hitomi) {
      final res = await HiNetwork().getComicInfo(target);
      if (res.error) {
        showToast(message: res.errorMessageWithoutNull);
        return null;
      }
      return ComicReadingPage.hitomi(
        res.data,
        target,
        initialPage: readPage,
      );
    }

    if (historyType == HistoryType.htmanga) {
      final res = await HtmangaNetwork().getComicInfo(target);
      if (res.error) {
        showToast(message: res.errorMessageWithoutNull);
        return null;
      }
      final comic = res.data;
      return ComicReadingPage.htmanga(
        comic.target,
        comic.title,
        initialPage: readPage,
        historySubTitle: comic.subTitle,
        historyCover: comic.cover,
      );
    }

    if (historyType == HistoryType.nhentai) {
      final res = await NhentaiNetwork().getComicInfo(target);
      if (res.error) {
        showToast(message: res.errorMessageWithoutNull);
        return null;
      }
      final comic = res.data;
      return ComicReadingPage.nhentai(
        comic.target,
        comic.title,
        initialPage: readPage,
        historySubTitle: comic.subTitle,
        historyCover: comic.cover,
      );
    }

    final source = historyType.comicSource;
    if (source?.loadComicInfo == null) {
      showToast(message: 'Comic Source Not Found');
      return null;
    }
    final res = await source!.loadComicInfo!(target);
    if (res.error) {
      showToast(message: res.errorMessageWithoutNull);
      return null;
    }
    final comic = res.data;
    return ComicReadingPage(
      CustomReadingData(
        comic.target,
        comic.title,
        ComicSource.find(source.key),
        comic.chapters,
        historySubTitle: comic.subTitle ?? '',
        historyCover: comic.cover,
      ),
      readPage,
      readEp,
    );
  } catch (error) {
    showToast(message: '${'打开失败'.tl}: $error');
    return null;
  }
}

Future<bool> openHistoryReader({
  required int type,
  required String target,
  required int ep,
  required int page,
}) async {
  final readerPage = await buildHistoryReaderPage(
    type: type,
    target: target,
    ep: ep,
    page: page,
  );
  if (readerPage == null) {
    return false;
  }
  App.globalTo(() => readerPage);
  return true;
}

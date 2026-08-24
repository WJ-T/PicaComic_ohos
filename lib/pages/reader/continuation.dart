part of 'comic_reading_page.dart';

const String _readerContinuationKind = 'reader';

Map<String, dynamic>? buildReaderContinuationPayload(
  ReadingData readingData,
  ComicReadingPageLogic logic,
) {
  final sourceKey = readingData.sourceKey;
  if (sourceKey.isEmpty) {
    return null;
  }

  final payload = <String, dynamic>{
    'kind': _readerContinuationKind,
    'sourceKey': sourceKey,
    'comicId': readingData.id,
    'title': readingData.title,
    'order': logic.order,
    'page': logic.index,
    'historySubTitle': readingData.historySubTitle,
    'historyCover': readingData.historyCover,
  };

  switch (readingData) {
    case PicacgReadingData():
      payload['eps'] = readingData.eps.values.toList();
      return payload;
    case JmReadingData():
      payload['epIds'] = readingData.eps.keys.toList();
      payload['epNames'] = readingData.eps.values.toList();
      return payload;
    case HitomiReadingData():
      payload['images'] = readingData.images.map((e) => e.toMap()).toList();
      payload['link'] = readingData.link;
      return payload;
    case HtReadingData():
    case NhentaiReadingData():
      return payload;
    case EhReadingData():
      payload['gallery'] = readingData.gallery.toJson();
      return payload;
    case CustomReadingData():
      if (readingData.source == null) {
        return null;
      }
      payload['chapters'] = readingData.comicChapters?.toJson();
      return payload;
    default:
      return null;
  }
}

Widget? buildReaderContinuationPage(Map<String, dynamic> payload) {
  if (payload['kind'] != _readerContinuationKind) {
    return null;
  }

  final sourceKey = payload['sourceKey']?.toString();
  final comicId = payload['comicId']?.toString();
  final title = payload['title']?.toString() ?? '';
  final order = _parsePositiveInt(payload['order']) ?? 1;
  final page = _parsePositiveInt(payload['page']) ?? 1;
  final historySubTitle = payload['historySubTitle']?.toString() ?? '';
  final historyCover = payload['historyCover']?.toString() ?? '';

  if (sourceKey == null || comicId == null || comicId.isEmpty) {
    return null;
  }

  switch (sourceKey) {
    case 'picacg':
      final eps = _readStringList(payload['eps']);
      if (eps.isEmpty) {
        return null;
      }
      return ComicReadingPage.picacg(
        comicId,
        order,
        eps,
        title,
        initialPage: page,
        historySubTitle: historySubTitle,
        historyCover: historyCover,
      );
    case 'jm':
      final epIds = _readStringList(payload['epIds']);
      final epNames = _readStringList(payload['epNames']);
      if (epIds.isEmpty || epNames.isEmpty) {
        return null;
      }
      return ComicReadingPage(
        JmReadingData(
          title,
          comicId,
          epIds,
          epNames,
          historySubTitle: historySubTitle,
        ),
        page,
        order,
      );
    case 'hitomi':
      final images =
          _readMapList(payload['images']).map(HitomiFile.fromMap).toList();
      final link = payload['link']?.toString();
      if (images.isEmpty || link == null || link.isEmpty) {
        return null;
      }
      return ComicReadingPage(
        HitomiReadingData(
          title,
          comicId,
          images,
          link,
          historySubTitle: historySubTitle,
          historyCover: historyCover,
        ),
        page,
        order,
      );
    case 'htManga':
      return ComicReadingPage.htmanga(
        comicId,
        title,
        initialPage: page,
        historySubTitle: historySubTitle,
        historyCover: historyCover,
      );
    case 'nhentai':
      return ComicReadingPage.nhentai(
        comicId,
        title,
        initialPage: page,
        historySubTitle: historySubTitle,
        historyCover: historyCover,
      );
    case 'ehentai':
      final galleryMap = payload['gallery'];
      if (galleryMap is! Map) {
        return null;
      }
      return ComicReadingPage(
        EhReadingData(eh.Gallery.fromJson(
          Map<String, dynamic>.from(galleryMap as Map),
        )),
        page,
        order,
      );
    default:
      final source = ComicSource.find(sourceKey);
      if (source == null) {
        return null;
      }
      final chapters = ComicChapters.fromJsonOrNull(payload['chapters']);
      return ComicReadingPage(
        CustomReadingData(
          comicId,
          title,
          source,
          chapters,
          historySubTitle: historySubTitle,
          historyCover: historyCover,
        ),
        page,
        order,
      );
  }
}

Future<void> syncReaderContinuationState(
  ReadingData readingData,
  ComicReadingPageLogic logic,
) async {
  if (!PlatformUtils.isOhos || !kEnableOhosContinuation) {
    return;
  }
  final payload = buildReaderContinuationPayload(readingData, logic);
  if (payload == null) {
    await OhosContinuationService.instance.clearReaderState();
    return;
  }
  await OhosContinuationService.instance.publishReaderState(payload);
}

Future<void> clearReaderContinuationState() async {
  if (!PlatformUtils.isOhos || !kEnableOhosContinuation) {
    return;
  }
  await OhosContinuationService.instance.clearReaderState();
}

int? _parsePositiveInt(dynamic value) {
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null || parsed <= 0) {
    return null;
  }
  return parsed;
}

List<String> _readStringList(dynamic raw) {
  if (raw is! List) {
    return const [];
  }
  return raw
      .map((e) => e?.toString() ?? '')
      .where((e) => e.isNotEmpty)
      .toList();
}

List<Map<String, dynamic>> _readMapList(dynamic raw) {
  if (raw is! List) {
    return const [];
  }
  return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

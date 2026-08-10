const MAX_LINES = 1;
const STROKE_WIDTH = 0.38;
const LAYOUT_WEIGHT = 1;
const FULL_SIZE = '100%';

class HistoryWidgetStorageDefaults {
  historyItems: string = '[]';
  historyCardMode: string = '0';
  historyMaxItems: string = '2';
  historyCount: string = '0';
  updatedAt: string = '0';
  title0: string = '';
  subtitle0: string = '';
  cover0: string = '';
  source0: string = '';
  progress0: string = '';
  time0: string = '';
  target0: string = '';
  type0: string = '0';
  ep0: string = '1';
  page0: string = '1';
  title1: string = '';
  subtitle1: string = '';
  cover1: string = '';
  source1: string = '';
  progress1: string = '';
  time1: string = '';
  target1: string = '';
  type1: string = '0';
  ep1: string = '1';
  page1: string = '1';
  title2: string = '';
  subtitle2: string = '';
  cover2: string = '';
  source2: string = '';
  progress2: string = '';
  time2: string = '';
  target2: string = '';
  type2: string = '0';
  ep2: string = '1';
  page2: string = '1';
  title3: string = '';
  subtitle3: string = '';
  cover3: string = '';
  source3: string = '';
  progress3: string = '';
  time3: string = '';
  target3: string = '';
  type3: string = '0';
  ep3: string = '1';
  page3: string = '1';
  title4: string = '';
  subtitle4: string = '';
  cover4: string = '';
  source4: string = '';
  progress4: string = '';
  time4: string = '';
  target4: string = '';
  type4: string = '0';
  ep4: string = '1';
  page4: string = '1';
  title5: string = '';
  subtitle5: string = '';
  cover5: string = '';
  source5: string = '';
  progress5: string = '';
  time5: string = '';
  target5: string = '';
  type5: string = '0';
  ep5: string = '1';
  page5: string = '1';
}

const historyWidgetStorage = new LocalStorage(new HistoryWidgetStorageDefaults());

interface HistoryWidgetItem {
  title: string;
  subtitle: string;
  source: string;
  progress: string;
  time: string;
  target: string;
  type: number;
  ep: number;
  page: number;
}

function readStringField(record: Record<string, Object>, key: string): string {
  const value = record[key];
  if (typeof value === 'string') {
    return value;
  }
  if (value instanceof String) {
    return value.toString();
  }
  return '';
}

function readNumberField(record: Record<string, Object>, key: string): number {
  const value = record[key];
  if (typeof value === 'number') {
    return value;
  }
  if (typeof value === 'string') {
    const parsed = Number(value);
    return Number.isNaN(parsed) ? 0 : parsed;
  }
  if (value instanceof Number) {
    return value.valueOf();
  }
  return 0;
}

@Entry(historyWidgetStorage)
@Component
struct HistoryWidgetCard {
  @LocalStorageProp('historyItems') @Watch('reloadRenderItems') historyItems: string = '[]';
  @LocalStorageProp('historyCardMode') @Watch('reloadRenderItems') historyCardMode: string = '0';
  @LocalStorageProp('historyMaxItems') @Watch('reloadRenderItems') historyMaxItems: string = '2';
  @LocalStorageProp('historyCount') @Watch('reloadRenderItems') historyCount: string = '0';
  @LocalStorageProp('updatedAt') @Watch('reloadRenderItems') updatedAt: string = '0';
  @LocalStorageProp('title0') @Watch('reloadRenderItems') title0: string = '';
  @LocalStorageProp('subtitle0') subtitle0: string = '';
  @LocalStorageProp('cover0') @Watch('reloadRenderItems') cover0: string = '';
  @LocalStorageProp('source0') source0: string = '';
  @LocalStorageProp('progress0') progress0: string = '';
  @LocalStorageProp('time0') time0: string = '';
  @LocalStorageProp('target0') target0: string = '';
  @LocalStorageProp('type0') type0: string = '0';
  @LocalStorageProp('ep0') ep0: string = '1';
  @LocalStorageProp('page0') page0: string = '1';
  @LocalStorageProp('title1') @Watch('reloadRenderItems') title1: string = '';
  @LocalStorageProp('subtitle1') subtitle1: string = '';
  @LocalStorageProp('cover1') @Watch('reloadRenderItems') cover1: string = '';
  @LocalStorageProp('source1') source1: string = '';
  @LocalStorageProp('progress1') progress1: string = '';
  @LocalStorageProp('time1') time1: string = '';
  @LocalStorageProp('target1') target1: string = '';
  @LocalStorageProp('type1') type1: string = '0';
  @LocalStorageProp('ep1') ep1: string = '1';
  @LocalStorageProp('page1') page1: string = '1';
  @LocalStorageProp('title2') @Watch('reloadRenderItems') title2: string = '';
  @LocalStorageProp('subtitle2') subtitle2: string = '';
  @LocalStorageProp('cover2') @Watch('reloadRenderItems') cover2: string = '';
  @LocalStorageProp('source2') source2: string = '';
  @LocalStorageProp('progress2') progress2: string = '';
  @LocalStorageProp('time2') time2: string = '';
  @LocalStorageProp('target2') target2: string = '';
  @LocalStorageProp('type2') type2: string = '0';
  @LocalStorageProp('ep2') ep2: string = '1';
  @LocalStorageProp('page2') page2: string = '1';
  @LocalStorageProp('title3') @Watch('reloadRenderItems') title3: string = '';
  @LocalStorageProp('subtitle3') subtitle3: string = '';
  @LocalStorageProp('cover3') @Watch('reloadRenderItems') cover3: string = '';
  @LocalStorageProp('source3') source3: string = '';
  @LocalStorageProp('progress3') progress3: string = '';
  @LocalStorageProp('time3') time3: string = '';
  @LocalStorageProp('target3') target3: string = '';
  @LocalStorageProp('type3') type3: string = '0';
  @LocalStorageProp('ep3') ep3: string = '1';
  @LocalStorageProp('page3') page3: string = '1';
  @LocalStorageProp('title4') @Watch('reloadRenderItems') title4: string = '';
  @LocalStorageProp('subtitle4') subtitle4: string = '';
  @LocalStorageProp('cover4') @Watch('reloadRenderItems') cover4: string = '';
  @LocalStorageProp('source4') source4: string = '';
  @LocalStorageProp('progress4') progress4: string = '';
  @LocalStorageProp('time4') time4: string = '';
  @LocalStorageProp('target4') target4: string = '';
  @LocalStorageProp('type4') type4: string = '0';
  @LocalStorageProp('ep4') ep4: string = '1';
  @LocalStorageProp('page4') page4: string = '1';
  @LocalStorageProp('title5') @Watch('reloadRenderItems') title5: string = '';
  @LocalStorageProp('subtitle5') subtitle5: string = '';
  @LocalStorageProp('cover5') @Watch('reloadRenderItems') cover5: string = '';
  @LocalStorageProp('source5') source5: string = '';
  @LocalStorageProp('progress5') progress5: string = '';
  @LocalStorageProp('time5') time5: string = '';
  @LocalStorageProp('target5') target5: string = '';
  @LocalStorageProp('type5') type5: string = '0';
  @LocalStorageProp('ep5') ep5: string = '1';
  @LocalStorageProp('page5') page5: string = '1';

  @State renderItems: Array<HistoryWidgetItem> = [];
  @State renderMaxItems: number = 2;
  @State renderCardMode: string = '0';

  aboutToAppear(): void {
    this.reloadRenderItems();
    this.requestHistoryRefresh();
  }

  private reloadRenderItems(): void {
    this.renderCardMode = this.historyCardMode;
    this.renderMaxItems = this.resolveMaxItems();
    const jsonItems = this.parseItems();
    const boundItems = this.collectBoundItems();
    const sourceItems = boundItems.length > 0 ? boundItems : jsonItems;
    this.renderItems = sourceItems.slice(0, this.renderMaxItems);
  }

  private resolveMaxItems(): number {
    const parsed = this.numberValue(this.historyMaxItems, this.historyCardMode === '2' ? 6 : 2);
    if (parsed >= 6 || this.historyCardMode === '2') {
      return 6;
    }
    return 2;
  }

  private numberValue(value: string, fallback: number): number {
    const parsed = Number(value);
    return Number.isNaN(parsed) ? fallback : parsed;
  }

  private parseItems(): Array<HistoryWidgetItem> {
    try {
      const parsed = JSON.parse(this.historyItems) as Array<Record<string, Object>>;
      if (!Array.isArray(parsed)) {
        return [];
      }
      return parsed.map((record: Record<string, Object>) => {
        return {
          title: readStringField(record, 'title'),
          subtitle: readStringField(record, 'subtitle'),
          source: readStringField(record, 'source'),
          progress: readStringField(record, 'progress'),
          time: readStringField(record, 'time'),
          target: readStringField(record, 'target'),
          type: readNumberField(record, 'type'),
          ep: readNumberField(record, 'ep'),
          page: readNumberField(record, 'page'),
        } as HistoryWidgetItem;
      }).filter((item: HistoryWidgetItem) => item.title.length > 0);
    } catch (_) {
      return [];
    }
  }

  private collectBoundItems(): Array<HistoryWidgetItem> {
    const items: Array<HistoryWidgetItem> = [];
    for (let index = 0; index < 6; index++) {
      const item = this.boundItemAt(index);
      if (item.title.length > 0) {
        items.push(item);
      }
    }
    return items;
  }

  private boundItemAt(index: number): HistoryWidgetItem {
    switch (index) {
      case 0:
        return this.createItem(this.title0, this.subtitle0, this.source0, this.progress0, this.time0,
          this.target0, this.type0, this.ep0, this.page0);
      case 1:
        return this.createItem(this.title1, this.subtitle1, this.source1, this.progress1, this.time1,
          this.target1, this.type1, this.ep1, this.page1);
      case 2:
        return this.createItem(this.title2, this.subtitle2, this.source2, this.progress2, this.time2,
          this.target2, this.type2, this.ep2, this.page2);
      case 3:
        return this.createItem(this.title3, this.subtitle3, this.source3, this.progress3, this.time3,
          this.target3, this.type3, this.ep3, this.page3);
      case 4:
        return this.createItem(this.title4, this.subtitle4, this.source4, this.progress4, this.time4,
          this.target4, this.type4, this.ep4, this.page4);
      case 5:
        return this.createItem(this.title5, this.subtitle5, this.source5, this.progress5, this.time5,
          this.target5, this.type5, this.ep5, this.page5);
      default:
        return this.emptyItem();
    }
  }

  private createItem(
    title: string,
    subtitle: string,
    source: string,
    progress: string,
    time: string,
    target: string,
    type: string,
    ep: string,
    page: string,
  ): HistoryWidgetItem {
    return {
      title,
      subtitle,
      source,
      progress,
      time,
      target,
      type: this.numberValue(type, 0),
      ep: this.numberValue(ep, 1),
      page: this.numberValue(page, 1),
    };
  }

  private emptyItem(): HistoryWidgetItem {
    return {
      title: '',
      subtitle: '',
      source: '',
      progress: '',
      time: '',
      target: '',
      type: 0,
      ep: 1,
      page: 1,
    };
  }

  private openHistory(): void {
    postCardAction(this, {
      action: 'router',
      abilityName: 'EntryAbility',
      params: {
        pica_widget_action: 'open_history',
      },
    });
  }

  private requestHistoryRefresh(): void {
    postCardAction(this, {
      action: 'message',
      params: {
        pica_widget_message: 'refresh_history',
        pica_widget_card_mode: this.renderCardMode,
      },
    });
  }

  private openReader(item: HistoryWidgetItem): void {
    postCardAction(this, {
      action: 'router',
      abilityName: 'EntryAbility',
      params: {
        pica_widget_action: 'open_reader',
        target: item.target,
        type: item.type.toString(),
        ep: item.ep.toString(),
        page: item.page.toString(),
      },
    });
  }

  @Builder
  private EmptyBuilder() {
    Column() {
      Text('暂无阅读历史')
        .maxLines(MAX_LINES)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontSize($r('app.float.pica_widget_item_font_size'))
        .fontWeight(FontWeight.Medium)
        .fontColor('#59636E')
        .height($r('app.float.pica_widget_item_text_height'))
      Text('打开漫画后会显示在这里')
        .maxLines(MAX_LINES)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontSize($r('app.float.pica_widget_meta_font_size'))
        .fontWeight(FontWeight.Regular)
        .fontColor('#8B949E')
        .height($r('app.float.pica_widget_item_text_height'))
        .margin({ top: $r('app.float.pica_widget_item_text_margin') })
    }
    .alignItems(HorizontalAlign.Start)
    .width(FULL_SIZE)
    .height($r('app.float.pica_widget_item_height'))
  }

  private coverAt(index: number): string {
    switch (index) {
      case 0:
        return this.cover0;
      case 1:
        return this.cover1;
      case 2:
        return this.cover2;
      case 3:
        return this.cover3;
      case 4:
        return this.cover4;
      case 5:
        return this.cover5;
      default:
        return '';
    }
  }

  private compactProgress(item: HistoryWidgetItem): string {
    const progress = item.progress;
    if (progress.length === 0) {
      return `${item.ep}话 ${item.page}页`;
    }
    return progress
      .replace('第', '')
      .replace('话 · ', '话 ')
      .replace('话·', '话');
  }

  @Builder
  private CoverImageBuilder(cover: string) {
    if (cover.length > 0) {
      Image(cover)
        .objectFit(ImageFit.Cover)
        .width($r('app.float.pica_widget_cover_width'))
        .height($r('app.float.pica_widget_cover_height'))
        .borderRadius($r('app.float.pica_widget_cover_radius'))
    }
  }

  @Builder
  private CoverBuilder(index: number) {
    Stack() {
      Column()
        .width($r('app.float.pica_widget_cover_width'))
        .height($r('app.float.pica_widget_cover_height'))
        .borderRadius($r('app.float.pica_widget_cover_radius'))
        .backgroundColor('#E8ECF1')

      this.CoverImageBuilder(this.coverAt(index))
    }
    .width($r('app.float.pica_widget_cover_width'))
    .height($r('app.float.pica_widget_cover_height'))
    .margin({ right: $r('app.float.pica_widget_cover_margin_right') })
  }

  @Builder
  private CompactHistoryItemBuilder(item: HistoryWidgetItem, index: number) {
    Column() {
      Stack() {
        Column()
          .width($r('app.float.pica_widget_compact_cover_width'))
          .height($r('app.float.pica_widget_compact_cover_height'))
          .borderRadius($r('app.float.pica_widget_cover_radius'))
          .backgroundColor('#E8ECF1')

        if (this.coverAt(index).length > 0) {
          Image(this.coverAt(index))
            .objectFit(ImageFit.Cover)
            .width($r('app.float.pica_widget_compact_cover_width'))
            .height($r('app.float.pica_widget_compact_cover_height'))
            .borderRadius($r('app.float.pica_widget_cover_radius'))
        }
      }
      .width($r('app.float.pica_widget_compact_cover_width'))
      .height($r('app.float.pica_widget_compact_cover_height'))

      Text(item.source)
        .maxLines(MAX_LINES)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontSize($r('app.float.pica_widget_compact_meta_font_size'))
        .fontColor('#59636E')
        .height($r('app.float.pica_widget_compact_meta_line_height'))
        .width(FULL_SIZE)
        .textAlign(TextAlign.Center)

      Text(this.compactProgress(item))
        .maxLines(MAX_LINES)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontSize($r('app.float.pica_widget_compact_meta_font_size'))
        .fontColor('#59636E')
        .height($r('app.float.pica_widget_compact_meta_line_height'))
        .width(FULL_SIZE)
        .textAlign(TextAlign.Center)
    }
    .width($r('app.float.pica_widget_compact_cover_width'))
    .height($r('app.float.pica_widget_compact_item_height'))
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.openReader(item);
    })
  }

  @Builder
  private CompactHistoryListBuilder() {
    Row({ space: 12 }) {
      ForEach(this.renderItems.slice(0, 2), (item: HistoryWidgetItem, index?: number) => {
        this.CompactHistoryItemBuilder(item, index ?? 0)
      }, (item: HistoryWidgetItem) => `${this.updatedAt}-${item.target}-${item.ep}-${item.page}`)
    }
    .width(FULL_SIZE)
    .height($r('app.float.pica_widget_compact_item_height'))
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private HistoryItemBuilder(item: HistoryWidgetItem, index: number, total: number) {
    Row() {
      this.CoverBuilder(index)

      Column() {
        Row() {
          Text(item.title)
            .maxLines(MAX_LINES)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize($r('app.float.pica_widget_item_font_size'))
            .fontWeight(FontWeight.Medium)
            .fontColor('#202124')
            .height($r('app.float.pica_widget_item_text_height'))
            .layoutWeight(LAYOUT_WEIGHT)

          Text(item.time)
            .maxLines(MAX_LINES)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize($r('app.float.pica_widget_meta_font_size'))
            .fontWeight(FontWeight.Regular)
            .fontColor('#8B949E')
            .height($r('app.float.pica_widget_item_text_height'))
            .margin({ left: $r('app.float.pica_widget_time_margin') })
        }
        .width(FULL_SIZE)
        .alignItems(VerticalAlign.Center)

        Text(`${item.source}  ${item.progress}`)
          .maxLines(MAX_LINES)
          .fontSize($r('app.float.pica_widget_meta_font_size'))
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .fontWeight(FontWeight.Regular)
          .fontColor('#59636E')
          .height($r('app.float.pica_widget_item_text_height'))
          .margin({ top: $r('app.float.pica_widget_item_text_margin') })

        if (index < total - 1) {
          Divider()
            .strokeWidth(STROKE_WIDTH)
            .lineCap(LineCapStyle.Square)
            .color('#E6EAEE')
            .margin({ top: $r('app.float.pica_widget_divider_margin') })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(LAYOUT_WEIGHT)
    }
    .alignItems(VerticalAlign.Center)
    .width(FULL_SIZE)
    .height($r('app.float.pica_widget_item_height'))
    .onClick(() => {
      this.openReader(item);
    })
  }

  @Builder
  private HistoryListBuilder() {
    if (this.renderItems.length === 0) {
      this.EmptyBuilder()
    } else if (this.renderCardMode === '0') {
      this.CompactHistoryListBuilder()
    } else {
      ForEach(this.renderItems, (item: HistoryWidgetItem, index?: number) => {
        this.HistoryItemBuilder(item, index ?? 0, this.renderItems.length)
      }, (item: HistoryWidgetItem) => `${this.updatedAt}-${item.target}-${item.ep}-${item.page}`)
    }
  }

  build() {
    Column({ space: FlexAlign.Start }) {
      Row() {
        Text('阅读历史')
          .fontSize($r('app.float.pica_widget_title_font_size'))
          .fontWeight(FontWeight.Bold)
          .height($r('app.float.pica_widget_title_height'))
          .fontColor('#202124')
          .maxLines(MAX_LINES)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(LAYOUT_WEIGHT)
      }
      .width(FULL_SIZE)
      .alignItems(VerticalAlign.Top)
    .justifyContent(FlexAlign.Center)
      .padding({ bottom: $r('app.float.pica_widget_header_padding_bottom') })

      Column() {
        this.HistoryListBuilder()
      }
      .width(FULL_SIZE)
      .layoutWeight(LAYOUT_WEIGHT)
      .clip(true)
    }
    .width(FULL_SIZE)
    .height(FULL_SIZE)
    .backgroundColor('#F8FAFC')
    .padding({
      top: $r('app.float.pica_widget_side_padding'),
      bottom: $r('app.float.pica_widget_side_padding'),
      left: $r('app.float.pica_widget_side_padding'),
      right: $r('app.float.pica_widget_side_padding')
    })
    .onClick(() => {
      this.openHistory();
    })
  }
}

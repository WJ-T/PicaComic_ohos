import preferences from '@ohos.data.preferences';
import relationalStore from '@ohos.data.relationalStore';
import formBindingData from '@ohos.app.form.formBindingData';
import formProvider from '@ohos.app.form.formProvider';
import formInfo from '@ohos.app.form.formInfo';
import type common from '@ohos.app.ability.common';
import resourceManager from '@ohos.resourceManager';
import { BusinessError } from '@ohos.base';
import fs from '@ohos.file.fs';
import hilog from '@ohos.hilog';
import util from '@ohos.util';

const TAG: string = 'WidgetBridge';
const DOMAIN: number = 0xD005108;
const PREFS_NAME: string = 'pica_comic_widget';
const HISTORY_KEY: string = 'history_snapshot';
const THEME_COLORS_KEY: string = 'theme_colors';
const FORM_RECORDS_KEY: string = 'form_records';
const PENDING_ACTION_KEY: string = 'pending_widget_action';
const EMPTY_HISTORY: string = '[]';
const HISTORY_DB_NAME: string = 'history.db';
const HISTORY_DB_RELATIVE_DIR: string = 'pica_comic';
const SNAPSHOT_FILE_NAME: string = 'widget_history_snapshot.json';
const HISTORY_FORM_NAME: string = 'history_widget_v10';
const HISTORY_FORM_ABILITY: string = 'EntryHistoryFormAbility';

class HistoryWidgetBinding {
  historyItems: string = EMPTY_HISTORY;
  historyCardMode: string = '0';
  historyMaxItems: string = '2';
  historyCount: string = '0';
  updatedAt: string = '0';
  title0: string;
  subtitle0: string;
  cover0: string;
  source0: string;
  progress0: string;
  time0: string;
  target0: string;
  type0: string;
  ep0: string;
  page0: string;
  title1: string;
  subtitle1: string;
  cover1: string;
  source1: string;
  progress1: string;
  time1: string;
  target1: string;
  type1: string;
  ep1: string;
  page1: string;
  title2: string;
  subtitle2: string;
  cover2: string;
  source2: string;
  progress2: string;
  time2: string;
  target2: string;
  type2: string;
  ep2: string;
  page2: string;
  title3: string;
  subtitle3: string;
  cover3: string;
  source3: string;
  progress3: string;
  time3: string;
  target3: string;
  type3: string;
  ep3: string;
  page3: string;
  title4: string;
  subtitle4: string;
  cover4: string;
  source4: string;
  progress4: string;
  time4: string;
  target4: string;
  type4: string;
  ep4: string;
  page4: string;
  title5: string;
  subtitle5: string;
  cover5: string;
  source5: string;
  progress5: string;
  time5: string;
  target5: string;
  type5: string;
  ep5: string;
  page5: string;
  title6: string;
  subtitle6: string;
  cover6: string;
  source6: string;
  progress6: string;
  time6: string;
  target6: string;
  type6: string;
  ep6: string;
  page6: string;
  title7: string;
  subtitle7: string;
  cover7: string;
  source7: string;
  progress7: string;
  time7: string;
  target7: string;
  type7: string;
  ep7: string;
  page7: string;

  constructor() {
    this.title0 = '';
    this.subtitle0 = '';
    this.cover0 = '';
    this.source0 = '';
    this.progress0 = '';
    this.time0 = '';
    this.target0 = '';
    this.type0 = '0';
    this.ep0 = '1';
    this.page0 = '1';
    this.title1 = '';
    this.subtitle1 = '';
    this.cover1 = '';
    this.source1 = '';
    this.progress1 = '';
    this.time1 = '';
    this.target1 = '';
    this.type1 = '0';
    this.ep1 = '1';
    this.page1 = '1';
    this.title2 = '';
    this.subtitle2 = '';
    this.cover2 = '';
    this.source2 = '';
    this.progress2 = '';
    this.time2 = '';
    this.target2 = '';
    this.type2 = '0';
    this.ep2 = '1';
    this.page2 = '1';
    this.title3 = '';
    this.subtitle3 = '';
    this.cover3 = '';
    this.source3 = '';
    this.progress3 = '';
    this.time3 = '';
    this.target3 = '';
    this.type3 = '0';
    this.ep3 = '1';
    this.page3 = '1';
    this.title4 = '';
    this.subtitle4 = '';
    this.cover4 = '';
    this.source4 = '';
    this.progress4 = '';
    this.time4 = '';
    this.target4 = '';
    this.type4 = '0';
    this.ep4 = '1';
    this.page4 = '1';
    this.title5 = '';
    this.subtitle5 = '';
    this.cover5 = '';
    this.source5 = '';
    this.progress5 = '';
    this.time5 = '';
    this.target5 = '';
    this.type5 = '0';
    this.ep5 = '1';
    this.page5 = '1';
    this.title6 = '';
    this.subtitle6 = '';
    this.cover6 = '';
    this.source6 = '';
    this.progress6 = '';
    this.time6 = '';
    this.target6 = '';
    this.type6 = '0';
    this.ep6 = '1';
    this.page6 = '1';
    this.title7 = '';
    this.subtitle7 = '';
    this.cover7 = '';
    this.source7 = '';
    this.progress7 = '';
    this.time7 = '';
    this.target7 = '';
    this.type7 = '0';
    this.ep7 = '1';
    this.page7 = '1';
  }
}

export interface WidgetFormRecord {
  formId: string;
  dimension: number;
  height: number;
}

interface NativeHistorySnapshotItem {
  title: string;
  subtitle: string;
  cover: string;
  source: string;
  progress: string;
  time: string;
  target: string;
  type: number;
  ep: number;
  page: number;
}

interface HistoryDbCandidate {
  path: string;
  config: relationalStore.StoreConfig;
}

export interface WidgetThemePalette {
  background: string;
  primary: string;
  secondary: string;
  tertiary: string;
  divider: string;
}

export interface WidgetThemeColors {
  light: WidgetThemePalette;
  dark: WidgetThemePalette;
  themeMode: string;
}

const EMPTY_WIDGET_THEME_PALETTE: WidgetThemePalette = {
  background: '',
  primary: '',
  secondary: '',
  tertiary: '',
  divider: '',
};

const DEFAULT_WIDGET_THEME: WidgetThemeColors = {
  light: EMPTY_WIDGET_THEME_PALETTE,
  dark: EMPTY_WIDGET_THEME_PALETTE,
  themeMode: '0',
};

async function getPrefs(context: common.Context): Promise<preferences.Preferences> {
  return preferences.getPreferences(context, { name: PREFS_NAME });
}

function normalizeHistorySnapshot(snapshot: string): string {
  if (snapshot.length === 0) {
    return EMPTY_HISTORY;
  }
  try {
    const parsed = JSON.parse(snapshot) as Object;
    if (Array.isArray(parsed)) {
      return snapshot;
    }
  } catch (_) {
  }
  return EMPTY_HISTORY;
}

function maxItemsForDimension(dimension: number, height: number = 0): number {
  if (height <= 0) {
    // Newly created cards may not report their size until the first update.
    return dimension === formInfo.FormDimension.Dimension_4_4 || dimension === 4 ? 6 : 2;
  }

  // FormParam.HEIGHT_KEY is reported in px while the card layout uses vp.
  // Keep the conversion tied to the actual layout constants: the current
  // form scale is 2.6 px per vp, 52vp is occupied by padding and the header,
  // and each list row needs 44vp. This lets larger cards naturally expose
  // more rows instead of assigning a fixed count to a form dimension.
  const formHeightInVp = height / 2.6;
  const availableListHeight = formHeightInVp - 52;
  return Math.max(2, Math.min(8, Math.floor(availableListHeight / 44)));
}

function cardModeForDimension(dimension: number): number {
  if (dimension === formInfo.FormDimension.Dimension_4_4 || dimension === 4) {
    return 2;
  }
  if (dimension === formInfo.FormDimension.Dimension_2_4 || dimension === 3) {
    return 1;
  }
  return 0;
}

async function readStoredThemeColors(context: common.Context): Promise<WidgetThemeColors> {
  try {
    const prefs = await getPrefs(context);
    const raw = await prefs.get(THEME_COLORS_KEY, '');
    if (typeof raw !== 'string' || raw.length === 0) {
      return DEFAULT_WIDGET_THEME;
    }
    const parsed = JSON.parse(raw) as Record<string, Object>;
    const legacy: WidgetThemePalette = {
      background: typeof parsed.background === 'string' ? parsed.background : '',
      primary: typeof parsed.primary === 'string' ? parsed.primary : '',
      secondary: typeof parsed.secondary === 'string' ? parsed.secondary : '',
      tertiary: typeof parsed.tertiary === 'string' ? parsed.tertiary : '',
      divider: typeof parsed.divider === 'string' ? parsed.divider : '',
    };
    const readPalette = (key: string): WidgetThemePalette => {
      const value = parsed[key];
      if (value == null || typeof value !== 'object') {
        return legacy;
      }
      const palette = value as Record<string, Object>;
      return {
        background: typeof palette.background === 'string' ? palette.background : '',
        primary: typeof palette.primary === 'string' ? palette.primary : '',
        secondary: typeof palette.secondary === 'string' ? palette.secondary : '',
        tertiary: typeof palette.tertiary === 'string' ? palette.tertiary : '',
        divider: typeof palette.divider === 'string' ? palette.divider : '',
      };
    };
    return {
      light: readPalette('light'),
      dark: readPalette('dark'),
      themeMode: typeof parsed.themeMode === 'string' ? parsed.themeMode : '0',
    };
  } catch (_) {
    return DEFAULT_WIDGET_THEME;
  }
}

function currentSystemColorMode(context: common.Context): number {
  return context.resourceManager.getConfigurationSync().colorMode;
}

function selectWidgetTheme(
  context: common.Context,
  colors: WidgetThemeColors,
  systemColorMode?: number,
): WidgetThemePalette {
  if (colors.themeMode === '1') {
    return colors.light;
  }
  if (colors.themeMode === '2') {
    return colors.dark;
  }
  const colorMode = systemColorMode ?? currentSystemColorMode(context);
  return colorMode === resourceManager.ColorMode.DARK
    ? colors.dark
    : colors.light;
}

function limitHistorySnapshot(snapshot: string, maxItems: number): string {
  const normalizedSnapshot = normalizeHistorySnapshot(snapshot);
  try {
    const parsed = JSON.parse(normalizedSnapshot) as Array<Object>;
    if (!Array.isArray(parsed)) {
      return EMPTY_HISTORY;
    }
    return JSON.stringify(parsed.slice(0, maxItems));
  } catch (_) {
    return EMPTY_HISTORY;
  }
}

function readStringObjectField(record: Record<string, Object>, key: string): string {
  const value = record[key];
  if (typeof value === 'string') {
    return value;
  }
  if (value instanceof String) {
    return value.toString();
  }
  return '';
}

function readNumberObjectField(record: Record<string, Object>, key: string): number {
  const value = record[key];
  if (typeof value === 'number') {
    return value;
  }
  if (value instanceof Number) {
    return value.valueOf();
  }
  if (typeof value === 'string') {
    const parsed = Number(value);
    return Number.isNaN(parsed) ? 0 : parsed;
  }
  return 0;
}

function parseHistorySnapshotItems(snapshot: string, maxItems: number): Array<NativeHistorySnapshotItem> {
  try {
    const parsed = JSON.parse(normalizeHistorySnapshot(snapshot)) as Array<Record<string, Object>>;
    if (!Array.isArray(parsed)) {
      return [];
    }
    return parsed.slice(0, maxItems).map((record: Record<string, Object>) => {
      return {
        title: readStringObjectField(record, 'title'),
        subtitle: readStringObjectField(record, 'subtitle'),
        cover: readStringObjectField(record, 'cover'),
        source: readStringObjectField(record, 'source'),
        progress: readStringObjectField(record, 'progress'),
        time: readStringObjectField(record, 'time'),
        target: readStringObjectField(record, 'target'),
        type: readNumberObjectField(record, 'type'),
        ep: readNumberObjectField(record, 'ep'),
        page: readNumberObjectField(record, 'page'),
      } as NativeHistorySnapshotItem;
    }).filter((item: NativeHistorySnapshotItem) => item.title.length > 0);
  } catch (_) {
    return [];
  }
}

function historyCoverBindingValue(
  context: common.Context,
  item: NativeHistorySnapshotItem | undefined,
  index: number,
  revision: string,
  images: Record<string, number>,
): string {
  if (item == null || item.cover.length === 0) {
    return '';
  }
  const marker = 'base64,';
  if (!item.cover.startsWith('data:image/') || item.cover.indexOf(marker) < 0) {
    return '';
  }
  let file: fs.File | undefined;
  try {
    const base64 = item.cover.substring(item.cover.indexOf(marker) + marker.length);
    const bytes = new util.Base64Helper().decodeSync(base64, util.Type.BASIC);
    const buffer = bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength) as ArrayBuffer;
    const imageName = `history_cover_${index}_${revision}`;
    const filePath = `${context.getApplicationContext().tempDir}/${imageName}.jpg`;
    file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
    fs.writeSync(file.fd, buffer);
    images[imageName] = file.fd;
    const memoryUri = `memory://${imageName}`;
    hilog.info(DOMAIN, TAG, `form image prepared index=${index} bytes=${bytes.byteLength} uri=${memoryUri}`);
    return memoryUri;
  } catch (error) {
    const message = (error as BusinessError)?.message ?? JSON.stringify(error);
    hilog.error(DOMAIN, TAG, `form image prepare failed index=${index}: ${message}`);
    if (file != null) {
      try {
        fs.closeSync(file.fd);
      } catch (_) {
      }
    }
    return '';
  }
}

function snapshotItemCount(snapshot: string): number {
  try {
    const parsed = JSON.parse(normalizeHistorySnapshot(snapshot)) as Array<Object>;
    return Array.isArray(parsed) ? parsed.length : 0;
  } catch (_) {
    return 0;
  }
}

function historyTypeName(type: number): string {
  switch (type) {
    case 0:
      return 'picacg';
    case 1:
      return 'ehentai';
    case 2:
      return 'jmComic';
    case 3:
      return 'hitomi';
    case 4:
      return 'htmanga';
    case 5:
      return 'nhentai';
    default:
      return 'custom';
  }
}

function formatHistoryProgress(ep: number, page: number, maxPage: number): string {
  const safeEp = ep <= 0 ? 1 : ep;
  const safePage = page <= 0 ? 1 : page;
  if (maxPage > 0) {
    return `第${safeEp}话 · ${safePage}/${maxPage}页`;
  }
  return `第${safeEp}话 · 第${safePage}页`;
}

function formatHistoryTime(timestamp: number): string {
  if (timestamp <= 0) {
    return '';
  }
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
  const date = new Date(timestamp);
  const day = new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
  const days = Math.floor((today - day) / 86400000);
  if (days <= 0) {
    return '今天';
  }
  if (days === 1) {
    return '昨天';
  }
  if (days < 7) {
    return `${days}天前`;
  }
  return `${date.getMonth() + 1}/${date.getDate()}`;
}

function serializeRecords(records: Array<WidgetFormRecord>): Array<string> {
  return records.map((record: WidgetFormRecord) => `${record.formId}:${record.dimension}:${record.height}`);
}

function deserializeRecords(rawValue: preferences.ValueType): Array<WidgetFormRecord> {
  if (!Array.isArray(rawValue)) {
    return [];
  }
  const rawRecords = rawValue as Array<string>;
  const records: Array<WidgetFormRecord> = [];
  for (const rawRecord of rawRecords) {
    const parts = rawRecord.split(':');
    if (parts.length !== 2 && parts.length !== 3) {
      continue;
    }
    const dimension = Number(parts[1]);
    if (parts[0].length === 0 || Number.isNaN(dimension)) {
      continue;
    }
    records.push({
      formId: parts[0],
      dimension,
      height: parts.length === 3 && !Number.isNaN(Number(parts[2])) ? Number(parts[2]) : 0,
    });
  }
  return records;
}

export function createHistoryWidgetBinding(
  context: common.Context,
  historyItems: string,
  dimension: number,
  themeColors: WidgetThemeColors = DEFAULT_WIDGET_THEME,
  systemColorMode?: number,
  formHeight: number = 0,
): formBindingData.FormBindingData {
  const maxItems = maxItemsForDimension(dimension, formHeight);
  const items = parseHistorySnapshotItems(historyItems, maxItems);
  const revision = Date.now().toString();
  const images: Record<string, number> = {};
  const binding: Record<string, Object> = {};
  binding.historyItems = limitHistorySnapshot(historyItems, maxItems);
  binding.historyCardMode = cardModeForDimension(dimension).toString();
  binding.historyMaxItems = maxItems.toString();
  binding.historyCount = items.length.toString();
  // Theme colors are supplied by Flutter so the card follows the app's
  // selected theme instead of only following the device color mode.
  const activeTheme = selectWidgetTheme(context, themeColors, systemColorMode);
  binding.cardBackground = activeTheme.background;
  binding.cardPrimaryText = activeTheme.primary;
  binding.cardSecondaryText = activeTheme.secondary;
  binding.cardTertiaryText = activeTheme.tertiary;
  binding.cardDivider = activeTheme.divider;
  binding.updatedAt = Date.now().toString();
  binding.title0 = items[0]?.title ?? '';
  binding.subtitle0 = items[0]?.subtitle ?? '';
  binding.cover0 = historyCoverBindingValue(context, items[0], 0, revision, images);
  binding.source0 = items[0]?.source ?? '';
  binding.progress0 = items[0]?.progress ?? '';
  binding.time0 = items[0]?.time ?? '';
  binding.target0 = items[0]?.target ?? '';
  binding.type0 = (items[0]?.type ?? 0).toString();
  binding.ep0 = (items[0]?.ep ?? 1).toString();
  binding.page0 = (items[0]?.page ?? 1).toString();
  binding.title1 = items[1]?.title ?? '';
  binding.subtitle1 = items[1]?.subtitle ?? '';
  binding.cover1 = historyCoverBindingValue(context, items[1], 1, revision, images);
  binding.source1 = items[1]?.source ?? '';
  binding.progress1 = items[1]?.progress ?? '';
  binding.time1 = items[1]?.time ?? '';
  binding.target1 = items[1]?.target ?? '';
  binding.type1 = (items[1]?.type ?? 0).toString();
  binding.ep1 = (items[1]?.ep ?? 1).toString();
  binding.page1 = (items[1]?.page ?? 1).toString();
  binding.title2 = items[2]?.title ?? '';
  binding.subtitle2 = items[2]?.subtitle ?? '';
  binding.cover2 = historyCoverBindingValue(context, items[2], 2, revision, images);
  binding.source2 = items[2]?.source ?? '';
  binding.progress2 = items[2]?.progress ?? '';
  binding.time2 = items[2]?.time ?? '';
  binding.target2 = items[2]?.target ?? '';
  binding.type2 = (items[2]?.type ?? 0).toString();
  binding.ep2 = (items[2]?.ep ?? 1).toString();
  binding.page2 = (items[2]?.page ?? 1).toString();
  binding.title3 = items[3]?.title ?? '';
  binding.subtitle3 = items[3]?.subtitle ?? '';
  binding.cover3 = historyCoverBindingValue(context, items[3], 3, revision, images);
  binding.source3 = items[3]?.source ?? '';
  binding.progress3 = items[3]?.progress ?? '';
  binding.time3 = items[3]?.time ?? '';
  binding.target3 = items[3]?.target ?? '';
  binding.type3 = (items[3]?.type ?? 0).toString();
  binding.ep3 = (items[3]?.ep ?? 1).toString();
  binding.page3 = (items[3]?.page ?? 1).toString();
  binding.title4 = items[4]?.title ?? '';
  binding.subtitle4 = items[4]?.subtitle ?? '';
  binding.cover4 = historyCoverBindingValue(context, items[4], 4, revision, images);
  binding.source4 = items[4]?.source ?? '';
  binding.progress4 = items[4]?.progress ?? '';
  binding.time4 = items[4]?.time ?? '';
  binding.target4 = items[4]?.target ?? '';
  binding.type4 = (items[4]?.type ?? 0).toString();
  binding.ep4 = (items[4]?.ep ?? 1).toString();
  binding.page4 = (items[4]?.page ?? 1).toString();
  binding.title5 = items[5]?.title ?? '';
  binding.subtitle5 = items[5]?.subtitle ?? '';
  binding.cover5 = historyCoverBindingValue(context, items[5], 5, revision, images);
  binding.source5 = items[5]?.source ?? '';
  binding.progress5 = items[5]?.progress ?? '';
  binding.time5 = items[5]?.time ?? '';
  binding.target5 = items[5]?.target ?? '';
  binding.type5 = (items[5]?.type ?? 0).toString();
  binding.ep5 = (items[5]?.ep ?? 1).toString();
  binding.page5 = (items[5]?.page ?? 1).toString();
  binding.title6 = items[6]?.title ?? '';
  binding.subtitle6 = items[6]?.subtitle ?? '';
  binding.cover6 = historyCoverBindingValue(context, items[6], 6, revision, images);
  binding.source6 = items[6]?.source ?? '';
  binding.progress6 = items[6]?.progress ?? '';
  binding.time6 = items[6]?.time ?? '';
  binding.target6 = items[6]?.target ?? '';
  binding.type6 = (items[6]?.type ?? 0).toString();
  binding.ep6 = (items[6]?.ep ?? 1).toString();
  binding.page6 = (items[6]?.page ?? 1).toString();
  binding.title7 = items[7]?.title ?? '';
  binding.subtitle7 = items[7]?.subtitle ?? '';
  binding.cover7 = historyCoverBindingValue(context, items[7], 7, revision, images);
  binding.source7 = items[7]?.source ?? '';
  binding.progress7 = items[7]?.progress ?? '';
  binding.time7 = items[7]?.time ?? '';
  binding.target7 = items[7]?.target ?? '';
  binding.type7 = (items[7]?.type ?? 0).toString();
  binding.ep7 = (items[7]?.ep ?? 1).toString();
  binding.page7 = (items[7]?.page ?? 1).toString();
  hilog.error(DOMAIN, TAG,
    `binding dimension=${dimension} max=${maxItems} count=${items.length} title0=${items[0]?.title.length ?? 0} cover0=${items[0]?.cover.length ?? 0} title2=${items[2]?.title.length ?? 0} cover2=${items[2]?.cover.length ?? 0} title4=${items[4]?.title.length ?? 0} cover4=${items[4]?.cover.length ?? 0} title5=${items[5]?.title.length ?? 0} cover5=${items[5]?.cover.length ?? 0}`);
  binding.formImages = images;
  return formBindingData.createFormBindingData(binding);
}

export async function readHistorySnapshot(context: common.Context): Promise<string> {
  const fileSnapshot = readHistorySnapshotFromFile(context);
  if (fileSnapshot.length > 0) {
    return fileSnapshot;
  }
  const databaseSnapshot = await readHistorySnapshotFromDatabase(context);
  if (databaseSnapshot.length > 0) {
    return databaseSnapshot;
  }
  try {
    const prefs = await getPrefs(context);
    const rawSnapshot = await prefs.get(HISTORY_KEY, EMPTY_HISTORY);
    return typeof rawSnapshot === 'string'
      ? normalizeHistorySnapshot(rawSnapshot)
      : EMPTY_HISTORY;
  } catch (error) {
    const message = (error as BusinessError)?.message ?? JSON.stringify(error);
    hilog.error(DOMAIN, TAG, `readHistorySnapshot failed: ${message}`);
    return EMPTY_HISTORY;
  }
}

export function readHistorySnapshotSync(context: common.Context): string {
  const fileSnapshot = readHistorySnapshotFromFile(context);
  return fileSnapshot.length > 0 ? fileSnapshot : EMPTY_HISTORY;
}

function readHistorySnapshotFromFile(context: common.Context): string {
  const paths: Array<string> = [
    `${context.filesDir}/${HISTORY_DB_RELATIVE_DIR}/${SNAPSHOT_FILE_NAME}`,
    `${context.filesDir}/${SNAPSHOT_FILE_NAME}`,
    `/data/storage/el2/base/files/${HISTORY_DB_RELATIVE_DIR}/${SNAPSHOT_FILE_NAME}`,
    `/data/storage/el2/base/files/${SNAPSHOT_FILE_NAME}`,
    `/data/storage/el1/base/haps/${HISTORY_DB_RELATIVE_DIR}/${SNAPSHOT_FILE_NAME}`,
    `/data/storage/el1/base/haps/${SNAPSHOT_FILE_NAME}`,
  ];
  for (const path of paths) {
    try {
      if (!fs.accessSync(path)) {
        continue;
      }
      const stat = fs.statSync(path);
      if (stat.size <= 0) {
        continue;
      }
      const file = fs.openSync(path, fs.OpenMode.READ_ONLY);
      try {
        const buffer = new ArrayBuffer(stat.size);
        const readSize = fs.readSync(file.fd, buffer);
        const snapshot = String.fromCharCode(...new Uint8Array(buffer.slice(0, readSize)));
        const normalizedSnapshot = normalizeHistorySnapshot(snapshot);
        if (snapshotItemCount(normalizedSnapshot) > 0) {
          hilog.error(DOMAIN, TAG, `history file snapshot loaded count=${snapshotItemCount(normalizedSnapshot)} path=${path}`);
          return normalizedSnapshot;
        }
      } finally {
        fs.closeSync(file);
      }
    } catch (error) {
      const message = (error as BusinessError)?.message ?? JSON.stringify(error);
      hilog.error(DOMAIN, TAG, `read history file snapshot failed ${path}: ${message}`);
    }
  }
  return '';
}

export async function readHistorySnapshotFromDatabase(
  context: common.Context,
): Promise<string> {
  const candidates: Array<HistoryDbCandidate> = [
    {
      path: `${context.filesDir}/${HISTORY_DB_RELATIVE_DIR}/${HISTORY_DB_NAME}`,
      config: {
        name: HISTORY_DB_NAME,
        securityLevel: relationalStore.SecurityLevel.S1,
        customDir: HISTORY_DB_RELATIVE_DIR,
      },
    },
    {
      path: `${context.filesDir}/${HISTORY_DB_NAME}`,
      config: {
        name: HISTORY_DB_NAME,
        securityLevel: relationalStore.SecurityLevel.S1,
      },
    },
    {
      path: `/data/storage/el2/base/files/${HISTORY_DB_RELATIVE_DIR}/${HISTORY_DB_NAME}`,
      config: {
        name: HISTORY_DB_NAME,
        securityLevel: relationalStore.SecurityLevel.S1,
        customDir: HISTORY_DB_RELATIVE_DIR,
      },
    },
    {
      path: `/data/storage/el2/base/files/${HISTORY_DB_NAME}`,
      config: {
        name: HISTORY_DB_NAME,
        securityLevel: relationalStore.SecurityLevel.S1,
      },
    },
    {
      path: `/data/storage/el1/base/haps/${HISTORY_DB_RELATIVE_DIR}/${HISTORY_DB_NAME}`,
      config: {
        name: HISTORY_DB_NAME,
        securityLevel: relationalStore.SecurityLevel.S1,
        customDir: HISTORY_DB_RELATIVE_DIR,
      },
    },
  ];

  for (const candidate of candidates) {
    if (!await fs.access(candidate.path)) {
      continue;
    }
    const snapshot = await readHistorySnapshotFromDatabaseCandidate(
      context,
      candidate,
    );
    if (snapshot.length > 0) {
      return snapshot;
    }
  }
  return '';
}

async function readHistorySnapshotFromDatabaseCandidate(
  context: common.Context,
  candidate: HistoryDbCandidate,
): Promise<string> {
  let store: relationalStore.RdbStore | null = null;
  let resultSet: relationalStore.ResultSet | null = null;
  try {
    store = await relationalStore.getRdbStore(context, candidate.config);
    resultSet = await store.querySql(
      `select
        target,
        coalesce(title, '') as title,
        coalesce(subtitle, '') as subtitle,
        coalesce(cover, '') as cover,
        coalesce(time, 0) as time,
        coalesce(type, 0) as type,
        coalesce(ep, 1) as ep,
        coalesce(page, 1) as page,
        coalesce(max_page, 0) as max_page
       from history
       order by time desc
       limit 6`,
    );
    const targetColumn = resultSet.getColumnIndex('target');
    const titleColumn = resultSet.getColumnIndex('title');
    const subtitleColumn = resultSet.getColumnIndex('subtitle');
    const coverColumn = resultSet.getColumnIndex('cover');
    const timeColumn = resultSet.getColumnIndex('time');
    const typeColumn = resultSet.getColumnIndex('type');
    const epColumn = resultSet.getColumnIndex('ep');
    const pageColumn = resultSet.getColumnIndex('page');
    const maxPageColumn = resultSet.getColumnIndex('max_page');
    const items: Array<NativeHistorySnapshotItem> = [];
    while (resultSet.goToNextRow()) {
      const type = resultSet.getLong(typeColumn);
      const ep = resultSet.getLong(epColumn);
      const page = resultSet.getLong(pageColumn);
      items.push({
        target: resultSet.getString(targetColumn),
        title: resultSet.getString(titleColumn),
        subtitle: resultSet.getString(subtitleColumn),
        cover: resultSet.getString(coverColumn),
        source: historyTypeName(type),
        progress: formatHistoryProgress(ep, page, resultSet.getLong(maxPageColumn)),
        time: formatHistoryTime(resultSet.getLong(timeColumn)),
        type,
        ep,
        page,
      });
    }
    if (items.length === 0) {
      hilog.info(DOMAIN, TAG, `history db snapshot empty: ${candidate.path}`);
      return '';
    }
    const snapshot = JSON.stringify(items);
    const prefs = await getPrefs(context);
    await prefs.put(HISTORY_KEY, snapshot);
    await prefs.flush();
    hilog.info(DOMAIN, TAG, `history db snapshot loaded ${items.length}: ${candidate.path}`);
    return snapshot;
  } catch (error) {
    const message = (error as BusinessError)?.message ?? JSON.stringify(error);
    hilog.warn(DOMAIN, TAG, `read history db snapshot failed ${candidate.path}: ${message}`);
    return '';
  } finally {
    if (resultSet != null && !resultSet.isClosed) {
      resultSet.close();
    }
    if (store != null) {
      try {
        await store.close();
      } catch (_) {
      }
    }
  }
}

export async function saveHistorySnapshot(
  context: common.Context,
  snapshot: string,
): Promise<void> {
  const normalizedSnapshot = normalizeHistorySnapshot(snapshot);
  const prefs = await getPrefs(context);
  await prefs.put(HISTORY_KEY, normalizedSnapshot);
  await prefs.flush();
  hilog.error(DOMAIN, TAG, `saveHistorySnapshot count=${snapshotItemCount(normalizedSnapshot)}`);
  await updateAllHistoryForms(context, normalizedSnapshot);
}

export async function saveWidgetTheme(
  context: common.Context,
  colors: WidgetThemeColors,
): Promise<void> {
  const prefs = await getPrefs(context);
  await prefs.put(THEME_COLORS_KEY, JSON.stringify(colors));
  await prefs.flush();
  await updateAllHistoryForms(context);
}

export async function savePendingWidgetAction(
  context: common.Context,
  action: string,
): Promise<void> {
  const prefs = await getPrefs(context);
  await prefs.put(PENDING_ACTION_KEY, action);
  await prefs.flush();
}

export async function takePendingWidgetAction(
  context: common.Context,
): Promise<string> {
  const prefs = await getPrefs(context);
  const rawAction = await prefs.get(PENDING_ACTION_KEY, '');
  await prefs.delete(PENDING_ACTION_KEY);
  await prefs.flush();
  return typeof rawAction === 'string' ? rawAction : '';
}

export async function readFormRecords(
  context: common.Context,
): Promise<Array<WidgetFormRecord>> {
  try {
    const prefs = await getPrefs(context);
    const rawRecords = await prefs.get(FORM_RECORDS_KEY, [] as Array<string>);
    return deserializeRecords(rawRecords);
  } catch (error) {
    const message = (error as BusinessError)?.message ?? JSON.stringify(error);
    hilog.error(DOMAIN, TAG, `readFormRecords failed: ${message}`);
    return [];
  }
}

export async function saveFormRecord(
  context: common.Context,
  formId: string,
  dimension: number,
  height: number = 0,
): Promise<void> {
  if (formId.length === 0) {
    return;
  }
  const prefs = await getPrefs(context);
  const rawRecords = await prefs.get(FORM_RECORDS_KEY, [] as Array<string>);
  const records = deserializeRecords(rawRecords)
    .filter((record: WidgetFormRecord) => record.formId !== formId);
  records.push({ formId, dimension, height });
  await prefs.put(FORM_RECORDS_KEY, serializeRecords(records));
  await prefs.flush();
}

export async function removeFormRecord(
  context: common.Context,
  formId: string,
): Promise<void> {
  const prefs = await getPrefs(context);
  const rawRecords = await prefs.get(FORM_RECORDS_KEY, [] as Array<string>);
  const records = deserializeRecords(rawRecords)
    .filter((record: WidgetFormRecord) => record.formId !== formId);
  await prefs.put(FORM_RECORDS_KEY, serializeRecords(records));
  await prefs.flush();
}

export async function updateHistoryForm(
  context: common.Context,
  formId: string,
  historyItems: string,
  dimension: number,
  systemColorMode?: number,
  formHeight: number = 0,
): Promise<void> {
  const count = snapshotItemCount(historyItems);
  const themeColors = await readStoredThemeColors(context);
  await formProvider.updateForm(
    formId,
    createHistoryWidgetBinding(context, historyItems, dimension, themeColors, systemColorMode, formHeight),
  );
  hilog.error(DOMAIN, TAG,
    `updateForm success formId=${formId} dimension=${dimension} height=${formHeight} count=${count}`);
}

export async function updateAllHistoryForms(
  context: common.Context,
  historyItems?: string,
  systemColorMode?: number,
): Promise<void> {
  const snapshot = historyItems ?? await readHistorySnapshot(context);
  const storedRecords = await readFormRecords(context);
  const records = await mergeRunningFormRecords(context, storedRecords);
  const aliveRecords: Array<WidgetFormRecord> = [];
  let changed = false;
  for (const record of records) {
    try {
      await updateHistoryForm(context, record.formId, snapshot, record.dimension, systemColorMode, record.height);
      aliveRecords.push(record);
    } catch (error) {
      const message = (error as BusinessError)?.message ?? JSON.stringify(error);
      hilog.error(DOMAIN, TAG, `updateForm ${record.formId} failed: ${message}`);
      if (message.includes('does not exist')) {
        changed = true;
      } else {
        aliveRecords.push(record);
      }
    }
  }
  if (changed) {
    const prefs = await getPrefs(context);
    await prefs.put(FORM_RECORDS_KEY, serializeRecords(aliveRecords));
    await prefs.flush();
    hilog.info(DOMAIN, TAG, `pruned invalid form records: ${records.length} -> ${aliveRecords.length}`);
  }
}

async function mergeRunningFormRecords(
  context: common.Context,
  storedRecords: Array<WidgetFormRecord>,
): Promise<Array<WidgetFormRecord>> {
  const merged = new Map<string, WidgetFormRecord>();
  for (const record of storedRecords) {
    merged.set(record.formId, record);
  }

  try {
    const runningForms = await formProvider.getPublishedRunningFormInfos();
    for (const runningForm of runningForms) {
      hilog.error(DOMAIN, TAG,
        `running form id=${runningForm.formId} name=${runningForm.formName} ability=${runningForm.abilityName} dimension=${runningForm.dimension}`);
      if (runningForm.formName !== HISTORY_FORM_NAME &&
        runningForm.abilityName !== HISTORY_FORM_ABILITY) {
        continue;
      }
      merged.set(runningForm.formId, {
        formId: runningForm.formId,
        dimension: runningForm.dimension,
        height: merged.get(runningForm.formId)?.height ?? 0,
      });
    }
    if (runningForms.length > 0) {
      hilog.error(DOMAIN, TAG, `published running forms=${runningForms.length} merged records=${merged.size}`);
    }
  } catch (error) {
    const message = (error as BusinessError)?.message ?? JSON.stringify(error);
    hilog.error(DOMAIN, TAG, `getPublishedRunningFormInfos failed: ${message}`);
  }

  const records = Array.from(merged.values());
  if (records.length !== storedRecords.length) {
    const prefs = await getPrefs(context);
    await prefs.put(FORM_RECORDS_KEY, serializeRecords(records));
    await prefs.flush();
  }
  return records;
}

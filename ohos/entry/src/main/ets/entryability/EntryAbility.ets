import {
  FlutterAbility,
  FlutterEngine,
  MethodCall,
  MethodCallHandler,
  MethodResult,
} from '@ohos/flutter_ohos';
import DownloadBridgePlugin from '../plugins/download/DownloadBridgePlugin';
import OhosBackgroundDownloadPlugin from '../plugins/background_download/OhosBackgroundDownloadPlugin';
import BatteryPlugin from '../plugins/battery/BatteryPlugin';
import ContinuationPlugin, {
  ENABLE_CONTINUATION,
  applyContinuationWantParam,
  cacheContinuationWant,
  dispatchContinuationWant,
  hasContinuationPayload,
} from '../plugins/continuation/ContinuationPlugin';
import UrlLauncherPlugin from '../plugins/url_launcher/UrlLauncherPlugin';
import VolumeKeyPlugin from '../plugins/volume/VolumeKeyPlugin';
import OhosDeviceInfoPlugin from '../plugins/device_info/OhosDeviceInfoPlugin';
import OhosSharePlugin from '../plugins/share/OhosSharePlugin';
import OhosDecorPlugin from '../plugins/decor/OhosDecorPlugin';
import OhosFilePickerPlugin from '../plugins/file_picker/OhosFilePickerPlugin';
import OhosWidgetPlugin, {
  cacheWidgetWant,
  dispatchWidgetWant,
  hasWidgetAction,
} from '../plugins/widget/OhosWidgetPlugin';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import hilog from '@ohos.hilog';
import type Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import type { common, Permissions } from '@kit.AbilityKit';
import { abilityAccessCtrl } from '@kit.AbilityKit';
import { BusinessError } from '@ohos.base';
import window from '@ohos.window';

const TAG: string = 'EntryAbility';
const DOMAIN: number = 0xD005100;
const STORAGE_PERMISSIONS: Array<Permissions> = [
  'ohos.permission.READ_MEDIA' as Permissions,
  'ohos.permission.WRITE_MEDIA' as Permissions,
  'ohos.permission.READ_WRITE_DOWNLOAD_DIRECTORY' as Permissions,
  'ohos.permission.DISTRIBUTED_DATASYNC' as Permissions,
];
const WIDGET_ACTION_KEY: string = 'pica_widget_action';
const WIDGET_PARAMS_KEY: string = 'params';
const WIDGET_ACTION_OPEN_HISTORY: string = 'open_history';
const WIDGET_ACTION_OPEN_READER: string = 'open_reader';

class SafeNavigationHandler implements MethodCallHandler {
  onMethodCall(call: MethodCall, result: MethodResult): void {
    result.success(null);
  }
}

export default class EntryAbility extends FlutterAbility {
  private titleAndDockHoverUnsupported: boolean = false;
  private titleAndDockHoverInFlight: boolean = false;

  async onCreate(want: Want, launchParams: AbilityConstant.LaunchParam) {
    const cleanWant = this.sanitizeWidgetWant(want);
    await super.onCreate(cleanWant, launchParams);
    await this.handleWidgetWant(want, false);
    if (ENABLE_CONTINUATION) {
      if (this.handleContinuationWant(want, launchParams, false)) {
        this.context.restoreWindowStage(new LocalStorage());
      }
      await this.setInitialContinueState();
    }
    await this.requestStoragePermissions();
  }

  onNewWant(want: Want, launchParams: AbilityConstant.LaunchParam): void {
    this.handleWidgetWant(want, true).catch((error: BusinessError) => {
      hilog.error(DOMAIN, TAG, `handleWidgetWant failed: ${error.message}`);
    });
    const cleanWant = this.sanitizeWidgetWant(want);
    super.onNewWant(cleanWant, launchParams);
    if (ENABLE_CONTINUATION) {
      this.handleContinuationWant(want, launchParams, true);
    }
  }

  onContinue(
    wantParam: Record<string, Object>,
  ): AbilityConstant.OnContinueResult {
    if (!ENABLE_CONTINUATION) {
      return AbilityConstant.OnContinueResult.REJECT;
    }
    if (!applyContinuationWantParam(wantParam)) {
      return AbilityConstant.OnContinueResult.REJECT;
    }
    return AbilityConstant.OnContinueResult.AGREE;
  }

  onWindowStageRestore(windowStage: window.WindowStage): void {
    this.onWindowStageCreate(windowStage);
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    try {
      windowStage.off('windowStageEvent', this.windowStageEventCallback);
    } catch (_) {
    }
    super.onWindowStageCreate(windowStage);
    const mainWindow = windowStage.getMainWindowSync();
    this.scheduleImmersiveWindowDecor(mainWindow);
    mainWindow.on('windowStatusChange', () => {
      this.scheduleImmersiveWindowDecor(mainWindow);
    });
  }

  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    flutterEngine.getNavigationChannel()?.setMethodCallHandler(new SafeNavigationHandler());
    GeneratedPluginRegistrant.registerWith(flutterEngine);
    flutterEngine.getPlugins()?.add(new DownloadBridgePlugin());
    flutterEngine.getPlugins()?.add(new OhosBackgroundDownloadPlugin());
    flutterEngine.getPlugins()?.add(new BatteryPlugin());
    if (ENABLE_CONTINUATION) {
      flutterEngine.getPlugins()?.add(new ContinuationPlugin());
    }
    flutterEngine.getPlugins()?.add(new UrlLauncherPlugin());
    flutterEngine.getPlugins()?.add(new VolumeKeyPlugin());
    flutterEngine.getPlugins()?.add(new OhosDeviceInfoPlugin());
    flutterEngine.getPlugins()?.add(new OhosSharePlugin());
    flutterEngine.getPlugins()?.add(new OhosDecorPlugin());
    flutterEngine.getPlugins()?.add(new OhosFilePickerPlugin());
    flutterEngine.getPlugins()?.add(new OhosWidgetPlugin());
  }

  private async setInitialContinueState(): Promise<void> {
    const abilityContext = this.context as common.UIAbilityContext;
    if (!abilityContext) {
      return;
    }
    try {
      await abilityContext.setMissionContinueState(
        AbilityConstant.ContinueState.INACTIVE,
      );
    } catch (error) {
      const reason =
        (error as BusinessError)?.message ?? JSON.stringify(error);
      hilog.error(DOMAIN, TAG, `setMissionContinueState failed: ${reason}`);
    }
  }

  private handleContinuationWant(
    want: Want,
    launchParams: AbilityConstant.LaunchParam,
    dispatchImmediately: boolean,
  ): boolean {
    const hasPayload = hasContinuationPayload(want);
    if (
      launchParams.launchReason !== AbilityConstant.LaunchReason.CONTINUATION &&
      !hasPayload
    ) {
      return false;
    }
    if (dispatchImmediately) {
      dispatchContinuationWant(want);
    } else {
      cacheContinuationWant(want);
    }
    return true;
  }

  private async handleWidgetWant(
    want: Want,
    dispatchImmediately: boolean,
  ): Promise<boolean> {
    if (!hasWidgetAction(want)) {
      return false;
    }
    if (dispatchImmediately) {
      await dispatchWidgetWant(this.context as common.Context, want);
    } else {
      await cacheWidgetWant(this.context as common.Context, want);
    }
    return true;
  }

  private sanitizeWidgetWant(want: Want): Want {
    const parameters = want.parameters as Record<string, Object> | undefined;
    const cleanParameters: Record<string, Object> = {};
    if (parameters != null) {
      Object.entries(parameters).forEach((entry: [string, Object]) => {
        const key = entry[0];
        const value = entry[1];
        if (key === WIDGET_ACTION_KEY && this.isWidgetAction(value)) {
          return;
        }
        if (key === WIDGET_PARAMS_KEY && this.isWidgetParams(value)) {
          return;
        }
        cleanParameters[key] = value;
      });
    }
    const cleanWant: Want = {};
    if (want.bundleName != null) {
      cleanWant.bundleName = want.bundleName;
    }
    if (want.abilityName != null) {
      cleanWant.abilityName = want.abilityName;
    }
    if (want.deviceId != null) {
      cleanWant.deviceId = want.deviceId;
    }
    if (want.uri != null) {
      cleanWant.uri = want.uri;
    }
    if (want.type != null) {
      cleanWant.type = want.type;
    }
    if (want.flags != null) {
      cleanWant.flags = want.flags;
    }
    if (want.action != null) {
      cleanWant.action = want.action;
    }
    if (want.entities != null) {
      cleanWant.entities = want.entities;
    }
    if (want.moduleName != null) {
      cleanWant.moduleName = want.moduleName;
    }
    cleanWant.parameters = cleanParameters;
    return cleanWant;
  }

  private isWidgetParams(value: Object): boolean {
    if (typeof value === 'string') {
      try {
        const params = JSON.parse(value) as Record<string, Object>;
        return this.isWidgetAction(params[WIDGET_ACTION_KEY]);
      } catch (_) {
        return false;
      }
    }
    if (value instanceof String) {
      try {
        const params = JSON.parse(value.toString()) as Record<string, Object>;
        return this.isWidgetAction(params[WIDGET_ACTION_KEY]);
      } catch (_) {
        return false;
      }
    }
    if (value == null || typeof value !== 'object') {
      return false;
    }
    const params = value as Record<string, Object>;
    return this.isWidgetAction(params[WIDGET_ACTION_KEY]);
  }

  private isWidgetAction(value: Object | undefined): boolean {
    if (typeof value === 'string') {
      return value === WIDGET_ACTION_OPEN_HISTORY ||
        value === WIDGET_ACTION_OPEN_READER;
    }
    if (value instanceof String) {
      const action = value.toString();
      return action === WIDGET_ACTION_OPEN_HISTORY ||
        action === WIDGET_ACTION_OPEN_READER;
    }
    return false;
  }

  private async requestStoragePermissions(): Promise<void> {
    const abilityContext = this.context as common.UIAbilityContext;
    if (!abilityContext) {
      return;
    }
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    try {
      await atManager.requestPermissionsFromUser(abilityContext, STORAGE_PERMISSIONS);
    } catch (error) {
      const reason =
        (error as BusinessError)?.message ?? JSON.stringify(error);
      hilog.error(DOMAIN, TAG, `requestPermissionsFromUser failed: ${reason}`);
    }
  }

  private scheduleImmersiveWindowDecor(mainWindow: window.Window): void {
    setTimeout(() => {
      this.applyImmersiveWindowDecor(mainWindow);
    }, 1200);
    setTimeout(() => {
      this.applyImmersiveWindowDecor(mainWindow);
    }, 2500);
    setTimeout(() => {
      this.applyImmersiveWindowDecor(mainWindow);
    }, 4000);
  }

  private async applyImmersiveWindowDecor(mainWindow: window.Window): Promise<void> {
    try {
      mainWindow.setWindowDecorVisible(false);
    } catch (error) {
      const reason =
        (error as BusinessError)?.message ?? JSON.stringify(error);
      hilog.error(DOMAIN, TAG, `setWindowDecorVisible failed: ${reason}`);
    }

    try {
      mainWindow.setImmersiveModeEnabledState(true);
    } catch (error) {
      const reason =
        (error as BusinessError)?.message ?? JSON.stringify(error);
      hilog.error(DOMAIN, TAG, `setImmersiveModeEnabledState failed: ${reason}`);
    }

    if (this.titleAndDockHoverUnsupported || this.titleAndDockHoverInFlight) {
      return;
    }

    try {
      this.titleAndDockHoverInFlight = true;
      await mainWindow.setTitleAndDockHoverShown(true, true);
    } catch (error) {
      const businessError = error as BusinessError;
      if (businessError?.code === 801) {
        this.titleAndDockHoverUnsupported = true;
        return;
      }
      const reason = businessError?.message ?? JSON.stringify(error);
      hilog.warn(DOMAIN, TAG, `setTitleAndDockHoverShown failed: ${reason}`);
    } finally {
      this.titleAndDockHoverInFlight = false;
    }
  }
}

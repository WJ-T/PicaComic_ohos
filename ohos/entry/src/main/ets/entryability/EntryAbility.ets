import {
  FlutterAbility,
  FlutterEngine,
  MethodCall,
  MethodCallHandler,
  MethodResult,
} from '@ohos/flutter_ohos';
import DownloadBridgePlugin from '../plugins/download/DownloadBridgePlugin';
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

class SafeNavigationHandler implements MethodCallHandler {
  onMethodCall(call: MethodCall, result: MethodResult): void {
    result.success(null);
  }
}

export default class EntryAbility extends FlutterAbility {
  async onCreate(want: Want, launchParams: AbilityConstant.LaunchParam) {
    await super.onCreate(want, launchParams);
    if (ENABLE_CONTINUATION) {
      if (this.handleContinuationWant(want, launchParams, false)) {
        this.context.restoreWindowStage(new LocalStorage());
      }
      await this.setInitialContinueState();
    }
    await this.requestStoragePermissions();
  }

  onNewWant(want: Want, launchParams: AbilityConstant.LaunchParam): void {
    super.onNewWant(want, launchParams);
    if (ENABLE_CONTINUATION) {
      this.handleContinuationWant(want, launchParams, true);
    }
  }

  async onContinue(
    wantParam: Record<string, Object>,
  ): Promise<AbilityConstant.OnContinueResult> {
    if (!ENABLE_CONTINUATION) {
      return AbilityConstant.OnContinueResult.REJECT;
    }
    if (!(await applyContinuationWantParam(wantParam))) {
      return AbilityConstant.OnContinueResult.REJECT;
    }
    return AbilityConstant.OnContinueResult.AGREE;
  }

  onWindowStageRestore(windowStage: window.WindowStage): void {
    this.onWindowStageCreate(windowStage);
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
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
    flutterEngine.getPlugins()?.add(new BatteryPlugin());
    if (ENABLE_CONTINUATION) {
      flutterEngine.getPlugins()?.add(new ContinuationPlugin());
    }
    flutterEngine.getPlugins()?.add(new UrlLauncherPlugin());
    flutterEngine.getPlugins()?.add(new VolumeKeyPlugin());
    flutterEngine.getPlugins()?.add(new OhosDeviceInfoPlugin());
    flutterEngine.getPlugins()?.add(new OhosSharePlugin());
    flutterEngine.getPlugins()?.add(new OhosDecorPlugin());
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
    }, 0);
    setTimeout(() => {
      this.applyImmersiveWindowDecor(mainWindow);
    }, 300);
    setTimeout(() => {
      this.applyImmersiveWindowDecor(mainWindow);
    }, 1000);
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

    try {
      await mainWindow.setTitleAndDockHoverShown(true, true);
    } catch (error) {
      const reason =
        (error as BusinessError)?.message ?? JSON.stringify(error);
      hilog.error(DOMAIN, TAG, `setTitleAndDockHoverShown failed: ${reason}`);
    }
  }
}

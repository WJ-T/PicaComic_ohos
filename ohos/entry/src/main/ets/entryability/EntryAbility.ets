import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import DownloadBridgePlugin from '../plugins/download/DownloadBridgePlugin';
import BatteryPlugin from '../plugins/battery/BatteryPlugin';
import ContinuationPlugin, {
  ENABLE_CONTINUATION,
  applyContinuationWantParam,
  cacheContinuationWant,
  dispatchContinuationWant,
} from '../plugins/continuation/ContinuationPlugin';
import UrlLauncherPlugin from '../plugins/url_launcher/UrlLauncherPlugin';
import VolumeKeyPlugin from '../plugins/volume/VolumeKeyPlugin';
import OhosDeviceInfoPlugin from '../plugins/device_info/OhosDeviceInfoPlugin';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import hilog from '@ohos.hilog';
import type Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import type { common, Permissions } from '@kit.AbilityKit';
import { abilityAccessCtrl } from '@kit.AbilityKit';
import { BusinessError } from '@ohos.base';

const TAG: string = 'EntryAbility';
const DOMAIN: number = 0xD005100;
const STORAGE_PERMISSIONS: Array<Permissions> = [
  'ohos.permission.READ_MEDIA' as Permissions,
  'ohos.permission.WRITE_MEDIA' as Permissions,
  'ohos.permission.READ_WRITE_DOWNLOAD_DIRECTORY' as Permissions,
];

export default class EntryAbility extends FlutterAbility {
  async onCreate(want: Want, launchParams: AbilityConstant.LaunchParam) {
    await super.onCreate(want, launchParams);
    if (ENABLE_CONTINUATION) {
      cacheContinuationWant(want);
      await this.setInitialContinueState();
    }
    await this.requestStoragePermissions();
  }

  onNewWant(want: Want, launchParams: AbilityConstant.LaunchParam): void {
    super.onNewWant(want, launchParams);
    if (ENABLE_CONTINUATION) {
      dispatchContinuationWant(want);
    }
  }

  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    if (!ENABLE_CONTINUATION) {
      return AbilityConstant.OnContinueResult.REJECT;
    }
    if (!applyContinuationWantParam(wantParam)) {
      return AbilityConstant.OnContinueResult.REJECT;
    }
    return AbilityConstant.OnContinueResult.AGREE;
  }

  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    GeneratedPluginRegistrant.registerWith(flutterEngine);
    flutterEngine.getPlugins()?.add(new DownloadBridgePlugin());
    flutterEngine.getPlugins()?.add(new BatteryPlugin());
    if (ENABLE_CONTINUATION) {
      flutterEngine.getPlugins()?.add(new ContinuationPlugin());
    }
    flutterEngine.getPlugins()?.add(new UrlLauncherPlugin());
    flutterEngine.getPlugins()?.add(new VolumeKeyPlugin());
    flutterEngine.getPlugins()?.add(new OhosDeviceInfoPlugin());
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
}

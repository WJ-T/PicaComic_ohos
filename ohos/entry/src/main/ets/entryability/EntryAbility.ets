import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import DownloadBridgePlugin from '../plugins/download/DownloadBridgePlugin';
import BatteryPlugin from '../plugins/battery/BatteryPlugin';
import UrlLauncherPlugin from '../plugins/url_launcher/UrlLauncherPlugin';
import VolumeKeyPlugin from '../plugins/volume/VolumeKeyPlugin';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import hilog from '@ohos.hilog';
import type Want from '@ohos.app.ability.Want';
import type AbilityConstant from '@ohos.app.ability.AbilityConstant';
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
    await this.requestStoragePermissions();
  }

  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    GeneratedPluginRegistrant.registerWith(flutterEngine);
    flutterEngine.getPlugins()?.add(new DownloadBridgePlugin());
    flutterEngine.getPlugins()?.add(new BatteryPlugin());
    flutterEngine.getPlugins()?.add(new UrlLauncherPlugin());
    flutterEngine.getPlugins()?.add(new VolumeKeyPlugin());
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

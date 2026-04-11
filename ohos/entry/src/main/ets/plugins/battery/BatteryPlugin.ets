import {
  BinaryMessenger,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import batteryInfo from '@ohos.batteryInfo';
import { BusinessError } from '@ohos.base';
import hilog from '@ohos.hilog';

const CHANNEL: string = 'pica_comic/ohos_battery';
const TAG: string = 'BatteryPlugin';
const DOMAIN: number = 0xD005104;
const CHARGING_ENABLE: number = 1;
const CHARGING_FULL: number = 3;

export default class BatteryPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;

  getUniqueClassName(): string {
    return 'BatteryPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    const messenger: BinaryMessenger = binding.getBinaryMessenger();
    this.channel = new MethodChannel(messenger, CHANNEL);
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'getStatus':
        this.handleGetStatus(result);
        break;
      default:
        result.notImplemented();
    }
  }

  private handleGetStatus(result: MethodResult): void {
    try {
      const chargingStatus = batteryInfo.chargingStatus;
      result.success({
        level: batteryInfo.batterySOC,
        charging:
          chargingStatus === CHARGING_ENABLE ||
          chargingStatus === CHARGING_FULL,
      });
    } catch (error) {
      const message =
        (error as BusinessError)?.message ?? JSON.stringify(error);
      hilog.error(DOMAIN, TAG, `getStatus failed: ${message}`);
      result.error('battery_error', message, null);
    }
  }
}

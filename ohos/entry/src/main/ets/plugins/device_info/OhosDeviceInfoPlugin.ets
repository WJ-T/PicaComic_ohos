import {
  BinaryMessenger,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import deviceInfo from '@ohos.deviceInfo';
import { BusinessError } from '@ohos.base';
import hilog from '@ohos.hilog';

const CHANNEL: string = 'pica_comic/ohos_device_info';
const TAG: string = 'OhosDeviceInfoPlugin';
const DOMAIN: number = 0xD005105;

export default class OhosDeviceInfoPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;

  getUniqueClassName(): string {
    return 'OhosDeviceInfoPlugin';
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
      case 'getDeviceType':
        this.handleGetDeviceType(result);
        break;
      default:
        result.notImplemented();
    }
  }

  private handleGetDeviceType(result: MethodResult): void {
    try {
      result.success(deviceInfo.deviceType);
    } catch (error) {
      const message =
        (error as BusinessError)?.message ?? JSON.stringify(error);
      hilog.error(DOMAIN, TAG, `getDeviceType failed: ${message}`);
      result.error('device_info_error', message, null);
    }
  }
}

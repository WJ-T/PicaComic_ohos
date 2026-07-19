import ConfigurationConstant from '@ohos.app.ability.ConfigurationConstant';
import window from '@ohos.window';
import {
  BinaryMessenger,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { BusinessError } from '@ohos.base';
import hilog from '@ohos.hilog';

const CHANNEL: string = 'pica_comic/ohos_decor';
const TAG: string = 'OhosDecorPlugin';
const DOMAIN: number = 0xD005107;

export default class OhosDecorPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private lastWindow: window.Window | null = null;

  getUniqueClassName(): string {
    return 'OhosDecorPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    const messenger: BinaryMessenger = binding.getBinaryMessenger();
    this.channel = new MethodChannel(messenger, CHANNEL);
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
    this.lastWindow = null;
  }

  async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    switch (call.method) {
      case 'setDecorButtonDark':
        await this.setDecorButtonDark(call.argument('dark') === true, result);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  private async setDecorButtonDark(
    dark: boolean,
    result: MethodResult,
  ): Promise<void> {
    try {
      this.lastWindow ??= await window.getLastWindow(getContext());
      this.lastWindow.setDecorButtonStyle({
        colorMode: dark
          ? ConfigurationConstant.ColorMode.COLOR_MODE_DARK
          : ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET,
      });
      result.success(true);
    } catch (error) {
      const message =
        (error as BusinessError)?.message ?? JSON.stringify(error);
      hilog.error(DOMAIN, TAG, `setDecorButtonDark failed: ${message}`);
      result.success(false);
    }
  }
}

import {
  AbilityPluginBinding,
  BinaryMessenger,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { common, UIAbility } from '@kit.AbilityKit';
import { fileUri } from '@kit.CoreFileKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@ohos.base';
import hilog from '@ohos.hilog';

const CHANNEL: string = 'pica_comic/ohos_share';
const TAG: string = 'OhosSharePlugin';
const DOMAIN: number = 0xD005105;

export default class OhosSharePlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private ability: UIAbility | null = null;

  getUniqueClassName(): string {
    return 'OhosSharePlugin';
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

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.ability = binding.getAbility();
  }

  onDetachedFromAbility(binding: AbilityPluginBinding): void {
    if (this.ability === binding.getAbility()) {
      this.ability = null;
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'shareText':
        this.handleShareText(call, result);
        break;
      case 'shareFiles':
        this.handleShareFiles(call, result);
        break;
      default:
        result.notImplemented();
    }
  }

  private async handleShareText(call: MethodCall, result: MethodResult): Promise<void> {
    const text = call.argument('text') as string | null;
    if (!text || text.length === 0) {
      result.error('invalid_args', 'Text cannot be empty', null);
      return;
    }
    const subject = call.argument('subject') as string | null;
    const record: systemShare.SharedRecord = {
      utd: utd.UniformDataType.PLAIN_TEXT,
      content: text,
      title: subject ?? undefined,
    };
    await this.showShareData(new systemShare.SharedData(record), result);
  }

  private async handleShareFiles(call: MethodCall, result: MethodResult): Promise<void> {
    const paths = call.argument('paths') as Array<string> | null;
    if (!paths || paths.length === 0) {
      result.error('invalid_args', 'File paths cannot be empty', null);
      return;
    }

    let data: systemShare.SharedData | null = null;
    paths.forEach((path: string) => {
      const record = this.createFileRecord(path);
      if (data === null) {
        data = new systemShare.SharedData(record);
      } else {
        data.addRecord(record);
      }
    });

    if (data === null) {
      result.error('invalid_args', 'File paths cannot be empty', null);
      return;
    }
    await this.showShareData(data, result, paths.length > 1);
  }

  private createFileRecord(path: string): systemShare.SharedRecord {
    const uri = path.startsWith('file://') ? path : fileUri.getUriFromPath(path);
    return {
      utd: this.resolveUtd(path),
      uri: uri,
      title: this.fileName(path),
    };
  }

  private async showShareData(
    data: systemShare.SharedData,
    result: MethodResult,
    batch: boolean = false,
  ): Promise<void> {
    if (!this.ability) {
      result.error('no_ability', 'UIAbility not attached', null);
      return;
    }
    try {
      const context = this.ability.context as common.UIAbilityContext;
      const controller = new systemShare.ShareController(data);
      await controller.show(context, {
        selectionMode: batch
          ? systemShare.SelectionMode.BATCH
          : systemShare.SelectionMode.SINGLE,
      });
      result.success(true);
    } catch (error) {
      const message = (error as BusinessError)?.message ?? JSON.stringify(error);
      hilog.error(DOMAIN, TAG, `share failed: ${message}`);
      result.error('share_error', message, null);
    }
  }

  private resolveUtd(path: string): string {
    const lower = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return utd.UniformDataType.PNG;
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return utd.UniformDataType.JPEG;
    }
    if (lower.endsWith('.pdf')) {
      return utd.UniformDataType.PDF;
    }
    if (lower.endsWith('.zip')) {
      return utd.UniformDataType.ZIP_ARCHIVE;
    }
    if (lower.endsWith('.txt') || lower.endsWith('.json') || lower.endsWith('.log')) {
      return utd.UniformDataType.PLAIN_TEXT;
    }
    return utd.UniformDataType.FILE;
  }

  private fileName(path: string): string {
    const normalized = path.endsWith('/') ? path.substring(0, path.length - 1) : path;
    const index = normalized.lastIndexOf('/');
    if (index >= 0 && index < normalized.length - 1) {
      return normalized.substring(index + 1);
    }
    return normalized;
  }
}

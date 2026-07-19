import {
  AbilityPluginBinding,
  Any,
  BinaryMessenger,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import type Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import wantConstant from '@ohos.app.ability.wantConstant';
import type { common } from '@kit.AbilityKit';
import { BusinessError } from '@ohos.base';
import hilog from '@ohos.hilog';

const CHANNEL: string = 'pica_comic/ohos_continuation';
const TAG: string = 'ContinuationPlugin';
const DOMAIN: number = 0xD005105;
const PAYLOAD_KEY: string = 'pica_comic.continuation_payload';
export const ENABLE_CONTINUATION: boolean = true;

type ContinuationPayload = Record<string, Object>;

class ContinuationStore {
  static pendingPayload: ContinuationPayload | null = null;
  static activePayload: ContinuationPayload | null = null;
  static plugin: ContinuationPlugin | null = null;

  static cacheFromWant(want: Want | undefined | null): void {
    const parameters = want?.parameters as Record<string, Object> | undefined;
    const payloadText = ContinuationStore.readPayloadText(parameters);
    if (payloadText.length === 0) {
      return;
    }
    try {
      const parsed = JSON.parse(payloadText) as ContinuationPayload;
      ContinuationStore.pendingPayload = parsed;
      if (ContinuationStore.plugin != null) {
        ContinuationStore.plugin.dispatchPayload(parsed);
      }
    } catch (error) {
      const message =
        (error as BusinessError)?.message ?? JSON.stringify(error);
      hilog.error(DOMAIN, TAG, `Failed to parse continuation payload: ${message}`);
    }
  }

  static dispatchFromWant(want: Want | undefined | null): void {
    const parameters = want?.parameters as Record<string, Object> | undefined;
    const payloadText = ContinuationStore.readPayloadText(parameters);
    if (payloadText.length === 0) {
      return;
    }
    try {
      const parsed = JSON.parse(payloadText) as ContinuationPayload;
      if (ContinuationStore.plugin != null) {
        ContinuationStore.plugin.dispatchPayload(parsed);
      } else {
        ContinuationStore.pendingPayload = parsed;
      }
    } catch (error) {
      const message =
        (error as BusinessError)?.message ?? JSON.stringify(error);
      hilog.error(DOMAIN, TAG, `Failed to dispatch continuation payload: ${message}`);
    }
  }

  static async applyWantParam(
    wantParam: Record<string, Object>,
  ): Promise<boolean> {
    let payloadText = await ContinuationStore.requestCurrentPayloadText();
    if (payloadText.length === 0 && ContinuationStore.activePayload != null) {
      payloadText = JSON.stringify(ContinuationStore.activePayload);
    }
    if (payloadText.length === 0) {
      return false;
    }
    wantParam[PAYLOAD_KEY] = payloadText as Object;
    wantParam[wantConstant.Params.SUPPORT_CONTINUE_PAGE_STACK_KEY] =
      false as Object;
    wantParam[wantConstant.Params.SUPPORT_CONTINUE_SOURCE_EXIT_KEY] =
      true as Object;
    return true;
  }

  static async requestCurrentPayloadText(): Promise<string> {
    if (ContinuationStore.plugin == null) {
      return '';
    }
    const payloadText = await ContinuationStore.plugin.requestReaderState();
    return payloadText ?? '';
  }

  static readPayloadText(
    parameters: Record<string, Object> | undefined,
  ): string {
    const rawPayload = parameters?.[PAYLOAD_KEY];
    if (typeof rawPayload === 'string') {
      return rawPayload;
    }
    if (rawPayload instanceof String) {
      return rawPayload.toString();
    }
    return '';
  }

  static consumePendingPayload(): ContinuationPayload | null {
    const payload = ContinuationStore.pendingPayload;
    ContinuationStore.pendingPayload = null;
    return payload;
  }
}

export function cacheContinuationWant(want: Want | undefined | null): void {
  if (!ENABLE_CONTINUATION) {
    return;
  }
  ContinuationStore.cacheFromWant(want);
}

export function applyContinuationWantParam(
  wantParam: Record<string, Object>,
): Promise<boolean> {
  if (!ENABLE_CONTINUATION) {
    return Promise.resolve(false);
  }
  return ContinuationStore.applyWantParam(wantParam);
}

export function dispatchContinuationWant(want: Want | undefined | null): void {
  if (!ENABLE_CONTINUATION) {
    return;
  }
  ContinuationStore.dispatchFromWant(want);
}

export default class ContinuationPlugin
  implements FlutterPlugin, MethodCallHandler
{
  private channel: MethodChannel | null = null;
  private abilityContext: common.UIAbilityContext | null = null;

  getUniqueClassName(): string {
    return 'ContinuationPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    if (!ENABLE_CONTINUATION) {
      return;
    }
    const messenger: BinaryMessenger = binding.getBinaryMessenger();
    this.channel = new MethodChannel(messenger, CHANNEL);
    this.channel.setMethodCallHandler(this);
    ContinuationStore.plugin = this;
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
    if (ContinuationStore.plugin === this) {
      ContinuationStore.plugin = null;
    }
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.abilityContext = binding.getAbility().context as common.UIAbilityContext;
  }

  onDetachedFromAbility(binding: AbilityPluginBinding): void {
    if (this.abilityContext === binding.getAbility().context) {
      this.abilityContext = null;
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'setReaderState':
        this.handleSetReaderState(call, result);
        break;
      case 'clearReaderState':
        this.handleClearReaderState(result);
        break;
      case 'getInitialContinuation':
        result.success(ContinuationStore.consumePendingPayload());
        break;
      default:
        result.notImplemented();
    }
  }

  dispatchPayload(payload: ContinuationPayload): void {
    if (this.channel == null) {
      return;
    }
    this.channel.invokeMethod('onContinuation', payload as Object);
  }

  requestReaderState(): Promise<string | null> {
    if (this.channel == null) {
      return Promise.resolve(null);
    }
    return new Promise<string | null>((resolve) => {
      const timer = setTimeout(() => resolve(null), 1500);
      const callback: MethodResult = {
        success: (raw: Any) => {
          clearTimeout(timer);
          if (typeof raw === 'string' && raw.length > 0) {
            resolve(raw);
          } else {
            resolve(null);
          }
        },
        error: (_code: string, _message: string | undefined, _details: Any) => {
          clearTimeout(timer);
          resolve(null);
        },
        notImplemented: () => {
          clearTimeout(timer);
          resolve(null);
        },
      };
      this.channel!.invokeMethod('getReaderState', null, callback);
    });
  }

  private async handleSetReaderState(
    call: MethodCall,
    result: MethodResult,
  ): Promise<void> {
    const payload = call.argument('payload') as ContinuationPayload | null;
    if (payload == null) {
      result.error('invalid_args', 'Continuation payload is required', null);
      return;
    }
    ContinuationStore.activePayload = payload;
    try {
      await this.updateContinueState(AbilityConstant.ContinueState.ACTIVE);
      result.success(true);
    } catch (error) {
      const message =
        (error as BusinessError)?.message ?? JSON.stringify(error);
      hilog.error(DOMAIN, TAG, `setReaderState failed: ${message}`);
      result.error('continuation_error', message, null);
    }
  }

  private async handleClearReaderState(result: MethodResult): Promise<void> {
    ContinuationStore.activePayload = null;
    try {
      await this.updateContinueState(AbilityConstant.ContinueState.INACTIVE);
      result.success(true);
    } catch (error) {
      const message =
        (error as BusinessError)?.message ?? JSON.stringify(error);
      hilog.error(DOMAIN, TAG, `clearReaderState failed: ${message}`);
      result.error('continuation_error', message, null);
    }
  }

  private async updateContinueState(
    state: AbilityConstant.ContinueState,
  ): Promise<void> {
    if (this.abilityContext == null) {
      throw new Error('UIAbilityContext not attached');
    }
    await this.abilityContext.setMissionContinueState(state);
  }
}

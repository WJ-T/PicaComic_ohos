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
import type Want from '@ohos.app.ability.Want';
import type { common } from '@kit.AbilityKit';
import { BusinessError } from '@ohos.base';
import hilog from '@ohos.hilog';
import {
  saveHistorySnapshot,
  savePendingWidgetAction,
  takePendingWidgetAction,
} from './WidgetBridge';

const CHANNEL: string = 'pica_comic/ohos_widget';
const TAG: string = 'OhosWidgetPlugin';
const DOMAIN: number = 0xD005109;
const ACTION_KEY: string = 'pica_widget_action';
const ACTION_OPEN_HISTORY: string = 'open_history';
const ACTION_OPEN_READER: string = 'open_reader';

function readStringField(record: Record<string, Object>, key: string): string {
  const value = record[key];
  if (typeof value === 'string') {
    return value;
  }
  if (value instanceof String) {
    return value.toString();
  }
  if (typeof value === 'number') {
    return value.toString();
  }
  if (value instanceof Number) {
    return Number(value).toString();
  }
  return '';
}

function isWidgetAction(action: string): boolean {
  return action === ACTION_OPEN_HISTORY || action === ACTION_OPEN_READER;
}

class WidgetActionStore {
  static pendingAction: string | null = null;
  static plugin: OhosWidgetPlugin | null = null;

  static readActionPayloadFromRecord(
    parameters: Record<string, Object> | undefined,
  ): string {
    if (parameters == null) {
      return '';
    }
    const action = readStringField(parameters, ACTION_KEY);
    if (action === ACTION_OPEN_HISTORY) {
      return ACTION_OPEN_HISTORY;
    }
    if (action === ACTION_OPEN_READER) {
      return JSON.stringify({
        action: ACTION_OPEN_READER,
        target: readStringField(parameters, 'target'),
        type: readStringField(parameters, 'type'),
        ep: readStringField(parameters, 'ep'),
        page: readStringField(parameters, 'page'),
      });
    }
    const rawParams = parameters?.['params'];
    if (typeof rawParams === 'string') {
      try {
        return WidgetActionStore.readActionPayloadFromRecord(
          JSON.parse(rawParams) as Record<string, Object>,
        );
      } catch (_) {
        return '';
      }
    }
    if (rawParams instanceof String) {
      try {
        return WidgetActionStore.readActionPayloadFromRecord(
          JSON.parse(rawParams.toString()) as Record<string, Object>,
        );
      } catch (_) {
        return '';
      }
    }
    if (rawParams != null && typeof rawParams === 'object') {
      return WidgetActionStore.readActionPayloadFromRecord(rawParams as Record<string, Object>);
    }
    return '';
  }

  static readActionPayload(want: Want | undefined | null): string {
    const parameters = want?.parameters as Record<string, Object> | undefined;
    return WidgetActionStore.readActionPayloadFromRecord(parameters);
  }

  static readActionName(payload: string): string {
    if (payload === ACTION_OPEN_HISTORY) {
      return ACTION_OPEN_HISTORY;
    }
    try {
      const parsed = JSON.parse(payload) as Record<string, Object>;
      return readStringField(parsed, 'action');
    } catch (_) {
      return '';
    }
  }

  static async cacheFromWant(
    context: common.Context,
    want: Want | undefined | null,
  ): Promise<boolean> {
    const action = WidgetActionStore.readActionPayload(want);
    if (!isWidgetAction(WidgetActionStore.readActionName(action))) {
      return false;
    }
    WidgetActionStore.pendingAction = action;
    await savePendingWidgetAction(context, action);
    hilog.info(DOMAIN, TAG, `cache widget action: ${action}`);
    if (WidgetActionStore.plugin != null) {
      WidgetActionStore.plugin.dispatchAction(action);
    }
    return true;
  }

  static async dispatchFromWant(
    context: common.Context,
    want: Want | undefined | null,
  ): Promise<boolean> {
    const action = WidgetActionStore.readActionPayload(want);
    if (!isWidgetAction(WidgetActionStore.readActionName(action))) {
      return false;
    }
    await savePendingWidgetAction(context, action);
    hilog.info(DOMAIN, TAG, `dispatch widget action: ${action}`);
    if (WidgetActionStore.plugin != null) {
      WidgetActionStore.plugin.dispatchAction(action);
    } else {
      WidgetActionStore.pendingAction = action;
    }
    return true;
  }

  static consumePendingAction(): string | null {
    const action = WidgetActionStore.pendingAction;
    WidgetActionStore.pendingAction = null;
    return action;
  }
}

export function cacheWidgetWant(
  context: common.Context,
  want: Want | undefined | null,
): Promise<boolean> {
  return WidgetActionStore.cacheFromWant(context, want);
}

export function dispatchWidgetWant(
  context: common.Context,
  want: Want | undefined | null,
): Promise<boolean> {
  return WidgetActionStore.dispatchFromWant(context, want);
}

export function hasWidgetAction(want: Want | undefined | null): boolean {
  const action = WidgetActionStore.readActionName(
    WidgetActionStore.readActionPayload(want),
  );
  return isWidgetAction(action);
}

export default class OhosWidgetPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private abilityContext: common.UIAbilityContext | null = null;

  getUniqueClassName(): string {
    return 'OhosWidgetPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    const messenger: BinaryMessenger = binding.getBinaryMessenger();
    this.channel = new MethodChannel(messenger, CHANNEL);
    this.channel.setMethodCallHandler(this);
    WidgetActionStore.plugin = this;
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
    if (WidgetActionStore.plugin === this) {
      WidgetActionStore.plugin = null;
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

  async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    switch (call.method) {
      case 'getInitialWidgetAction':
        await this.handleGetInitialWidgetAction(result);
        break;
      case 'updateHistorySnapshot':
        await this.handleUpdateHistorySnapshot(call, result);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  private async handleGetInitialWidgetAction(result: MethodResult): Promise<void> {
    let action = WidgetActionStore.consumePendingAction();
    if ((action == null || action.length === 0) && this.abilityContext != null) {
      action = await takePendingWidgetAction(this.abilityContext);
    }
    if (action != null && action.length > 0) {
      hilog.info(DOMAIN, TAG, `consume initial widget action: ${action}`);
    }
    result.success(action);
  }

  dispatchAction(action: string): void {
    if (this.channel == null) {
      return;
    }
    this.channel.invokeMethod('onWidgetAction', action as Object);
  }

  private async handleUpdateHistorySnapshot(
    call: MethodCall,
    result: MethodResult,
  ): Promise<void> {
    const snapshot = call.argument('snapshot') as string | null;
    if (snapshot == null) {
      result.error('invalid_args', 'History snapshot is required', null);
      return;
    }
    try {
      const context = this.abilityContext ?? (getContext() as common.UIAbilityContext);
      hilog.error(DOMAIN, TAG, `updateHistorySnapshot count=${this.snapshotCount(snapshot)}`);
      await saveHistorySnapshot(context, snapshot);
      result.success(true);
    } catch (error) {
      const message = (error as BusinessError)?.message ?? JSON.stringify(error);
      hilog.error(DOMAIN, TAG, `updateHistorySnapshot failed: ${message}`);
      result.error('widget_error', message, null);
    }
  }

  private snapshotCount(snapshot: string): number {
    try {
      const parsed = JSON.parse(snapshot) as Array<Object>;
      return Array.isArray(parsed) ? parsed.length : 0;
    } catch (_) {
      return -1;
    }
  }
}

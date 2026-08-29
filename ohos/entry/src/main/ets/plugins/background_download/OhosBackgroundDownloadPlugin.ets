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
import { common, wantAgent, WantAgent } from '@kit.AbilityKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { BusinessError } from '@ohos.base';
import hilog from '@ohos.hilog';
import type Want from '@ohos.app.ability.Want';

const CHANNEL: string = 'pica_comic/ohos_background_download';
const TAG: string = 'OhosBackgroundDownload';
const DOMAIN: number = 0xD00510A;

export default class OhosBackgroundDownloadPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private context: common.UIAbilityContext | null = null;
  private operation: Promise<void> = Promise.resolve();
  private wanted: boolean = false;
  private running: boolean = false;

  getUniqueClassName(): string {
    return 'OhosBackgroundDownloadPlugin';
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
    this.context = binding.getAbility().context as common.UIAbilityContext;
  }

  onDetachedFromAbility(binding: AbilityPluginBinding): void {
    this.context = null;
  }

  async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    switch (call.method) {
      case 'start':
        result.success(await this.setWanted(true));
        break;
      case 'stop':
        result.success(await this.setWanted(false));
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  private async setWanted(wanted: boolean): Promise<boolean> {
    this.wanted = wanted;
    this.operation = this.operation.then(async (): Promise<void> => {
      await this.reconcile();
    });
    await this.operation;
    return this.running === this.wanted;
  }

  private async reconcile(): Promise<void> {
    if (this.wanted === this.running) {
      return;
    }
    const context = this.context ?? getContext() as common.UIAbilityContext;
    if (this.wanted) {
      try {
        const agentInfo: wantAgent.WantAgentInfo = {
          wants: [
            {
              bundleName: context.abilityInfo.bundleName,
              abilityName: context.abilityInfo.name,
            } as Want,
          ],
          actionType: wantAgent.OperationType.START_ABILITY,
          requestCode: 0,
          actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
        };
        const agent: WantAgent = await wantAgent.getWantAgent(agentInfo);
        await backgroundTaskManager.startBackgroundRunning(
          context,
          ['dataTransfer'],
          agent,
        );
        this.running = true;
        hilog.info(DOMAIN, TAG, 'dataTransfer background task started');
      } catch (error) {
        this.running = false;
        this.logError('startBackgroundRunning', error);
      }
      return;
    }
    try {
      await backgroundTaskManager.stopBackgroundRunning(context);
      this.running = false;
      hilog.info(DOMAIN, TAG, 'dataTransfer background task stopped');
    } catch (error) {
      this.logError('stopBackgroundRunning', error);
    }
  }

  private logError(operation: string, error: Object): void {
    const businessError = error as BusinessError;
    const message = businessError?.message ?? JSON.stringify(error);
    hilog.error(
      DOMAIN,
      TAG,
      `${operation} failed, code=${businessError?.code ?? -1}, message=${message}`,
    );
  }
}

import {
  Any,
  BinaryMessenger,
  EventChannel,
  EventSink,
  FlutterPlugin,
  FlutterPluginBinding,
  StreamHandler,
} from '@ohos/flutter_ohos';
import inputConsumer from '@ohos.multimodalInput.inputConsumer';
import { KeyCode } from '@ohos.multimodalInput.keyCode';
import type { KeyEvent } from '@ohos.multimodalInput.keyEvent';
import type { Callback } from '@ohos.base';
import hilog from '@ohos.hilog';
import { BusinessError } from '@ohos.base';

const CHANNEL: string = 'com.github.pacalini.pica_comic/volume';
const TAG: string = 'VolumeKeyPlugin';
const DOMAIN: number = 0xD005103;
const VOLUME_UP_EVENT: number = 1;
const VOLUME_DOWN_EVENT: number = 2;
const KEY_ACTION_DOWN: number = 1;

class EmptyStreamHandler implements StreamHandler {
  onListen(args: Any, events: EventSink): void {
    events.endOfStream();
  }

  onCancel(args: Any): void {}
}

export default class VolumeKeyPlugin implements FlutterPlugin, StreamHandler {
  private eventChannel: EventChannel | null = null;
  private eventSink: EventSink | null = null;
  private volumeUpCallback: Callback<KeyEvent> | null = null;
  private volumeDownCallback: Callback<KeyEvent> | null = null;
  private listening: boolean = false;

  getUniqueClassName(): string {
    return 'VolumeKeyPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    const messenger: BinaryMessenger = binding.getBinaryMessenger();
    this.eventChannel = new EventChannel(messenger, CHANNEL);
    this.eventChannel.setStreamHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.stopListening();
    this.eventSink = null;
    this.eventChannel?.setStreamHandler(new EmptyStreamHandler());
    this.eventChannel = null;
  }

  onListen(args: Any, events: EventSink): void {
    this.eventSink = events;
    this.startListening();
  }

  onCancel(args: Any): void {
    this.stopListening();
    this.eventSink = null;
  }

  private startListening(): void {
    if (this.listening) {
      return;
    }

    const volumeUpCallback: Callback<KeyEvent> = (_event: KeyEvent): void => {
      this.eventSink?.success(VOLUME_UP_EVENT);
    };
    const volumeDownCallback: Callback<KeyEvent> = (_event: KeyEvent): void => {
      this.eventSink?.success(VOLUME_DOWN_EVENT);
    };
    this.volumeUpCallback = volumeUpCallback;
    this.volumeDownCallback = volumeDownCallback;

    try {
      inputConsumer.on('keyPressed', {
        key: KeyCode.KEYCODE_VOLUME_UP,
        action: KEY_ACTION_DOWN,
        isRepeat: false,
      }, volumeUpCallback);
      inputConsumer.on('keyPressed', {
        key: KeyCode.KEYCODE_VOLUME_DOWN,
        action: KEY_ACTION_DOWN,
        isRepeat: false,
      }, volumeDownCallback);
      this.listening = true;
      hilog.info(DOMAIN, TAG, 'Volume key listener attached');
    } catch (error) {
      this.stopListening();
      const message =
        (error as BusinessError)?.message ?? JSON.stringify(error);
      hilog.error(DOMAIN, TAG, `Failed to attach listener: ${message}`);
      throw new Error(message);
    }
  }

  private stopListening(): void {
    this.unregisterCallback(this.volumeUpCallback);
    this.unregisterCallback(this.volumeDownCallback);
    this.volumeUpCallback = null;
    this.volumeDownCallback = null;
    this.listening = false;
  }

  private unregisterCallback(callback: Callback<KeyEvent> | null): void {
    if (callback == null) {
      return;
    }
    try {
      inputConsumer.off('keyPressed', callback);
    } catch (error) {
      const message =
        (error as BusinessError)?.message ?? JSON.stringify(error);
      hilog.error(DOMAIN, TAG, `Failed to detach listener: ${message}`);
    }
  }
}

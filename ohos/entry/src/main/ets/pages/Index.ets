import common from '@ohos.app.ability.common';
import window from '@ohos.window';
import { FlutterPage } from '@ohos/flutter_ohos';

let storage = LocalStorage.getShared()
const EVENT_BACK_PRESS = 'EVENT_BACK_PRESS'
const TAG = 'Index'

@Entry(storage)
@Component
struct Index {
  private context = getContext(this) as common.UIAbilityContext
  @LocalStorageLink('viewId') viewId: string = ""
  @State winWidth: number = 0
  @State winHeight: number = 0
  private win: window.Window | null = null
  private sizeCallback: ((size: window.Size) => void) | null = null
  private rectCallback: ((opts: window.RectChangeOptions) => void) | null = null

  aboutToAppear(): void {
    window.getLastWindow(this.context).then((w: window.Window) => {
      this.win = w
      const rect = w.getWindowProperties().windowRect
      this.updateWindowSize(rect.width, rect.height)
      this.sizeCallback = (size: window.Size) => {
        this.updateWindowSize(size.width, size.height)
      }
      w.on('windowSizeChange', this.sizeCallback)
      try {
        this.rectCallback = (opts: window.RectChangeOptions) => {
          this.updateWindowSize(opts.rect.width, opts.rect.height)
        }
        w.on('windowRectChange', this.rectCallback)
      } catch (err) {
        console.error(TAG, `windowRectChange listener failed: ${err}`)
      }
    }).catch((err: Error) => {
      console.error(TAG, `getLastWindow failed: ${err}`)
    })
  }

  aboutToDisappear(): void {
    try {
      if (this.win != null && this.sizeCallback != null) {
        this.win.off('windowSizeChange', this.sizeCallback)
      }
      if (this.win != null && this.rectCallback != null) {
        this.win.off('windowRectChange', this.rectCallback)
      }
    } catch (err) {
      console.error(TAG, `off window listeners failed: ${err}`)
    }
    this.win = null
    this.sizeCallback = null
    this.rectCallback = null
  }

  private updateWindowSize(width: number, height: number): void {
    if (width <= 0 || height <= 0) {
      return
    }
    this.winWidth = width
    this.winHeight = height
  }

  build() {
    Column() {
      FlutterPage({ viewId: this.viewId })
        .width('100%')
        .height('100%')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    }
    .width(this.winWidth > 0 ? `${this.winWidth}px` : '100%')
    .height(this.winHeight > 0 ? `${this.winHeight}px` : '100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  onBackPress(): boolean {
    this.context.eventHub.emit(EVENT_BACK_PRESS)
    return true
  }
}

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
import { picker, fileUri, fileIo as fs } from '@kit.CoreFileKit';
import { BusinessError } from '@ohos.base';

const CHANNEL: string = 'pica_comic/ohos_file_picker';

export default class OhosFilePickerPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private ability: UIAbility | null = null;

  getUniqueClassName(): string {
    return 'OhosFilePickerPlugin';
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
      case 'pickPicadata':
        this.handlePickPicadata(result);
        break;
      case 'pickLocalComicDirectory':
        this.handlePickLocalComicDirectory(result);
        break;
      default:
        result.notImplemented();
    }
  }

  private async handlePickPicadata(result: MethodResult): Promise<void> {
    if (!this.ability) {
      result.error('no_ability', 'UIAbility not attached', null);
      return;
    }
    try {
      const abilityContext = this.ability.context as common.UIAbilityContext;
      const documentPicker = new picker.DocumentViewPicker(abilityContext);
      const options = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      options.fileSuffixFilters = ['picadata'];
      const uris: Array<string> = await documentPicker.select(options);
      if (!uris || uris.length === 0) {
        result.success(null);
        return;
      }
      const sandboxPath = await this.copyToSandbox(abilityContext, uris[0]);
      result.success(sandboxPath);
    } catch (error) {
      const message = (error as BusinessError)?.message ?? JSON.stringify(error);
      result.error('pick_error', message, null);
    }
  }

  private async handlePickLocalComicDirectory(result: MethodResult): Promise<void> {
    if (!this.ability) {
      result.error('no_ability', 'UIAbility not attached', null);
      return;
    }
    try {
      const abilityContext = this.ability.context as common.UIAbilityContext;
      const documentPicker = new picker.DocumentViewPicker(abilityContext);
      const options = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      options.selectMode = picker.DocumentSelectMode.FOLDER;
      const uris: Array<string> = await documentPicker.select(options);
      if (!uris || uris.length === 0) {
        result.success(null);
        return;
      }
      const targetPath = this.copyDirectoryToSandbox(abilityContext, uris[0]);
      result.success(targetPath);
    } catch (error) {
      const businessError = error as BusinessError;
      if (businessError?.code === 13900012) {
        result.success(null);
        return;
      }
      const message = businessError?.message ?? JSON.stringify(error);
      result.error('pick_directory_error', message, null);
    }
  }

  private copyDirectoryToSandbox(context: common.UIAbilityContext, uri: string): string {
    const targetRoot = `${context.filesDir}/local_add_comic`;
    fs.mkdirSync(targetRoot, true);
    const folderName = this.safeFileName(
      this.decodeFileName(this.extractFileName(uri)),
      `comic_${Date.now()}`,
    );
    const targetPath = this.uniqueDirectoryPath(targetRoot, folderName);
    fs.mkdirSync(targetPath, true);
    let sourcePath = this.resolveFilePath(uri) ?? uri;
    try {
      fs.listFileSync(sourcePath);
    } catch (error) {
      if (sourcePath === uri) {
        const message = (error as BusinessError)?.message ?? JSON.stringify(error);
        throw new Error(`Unable to access selected directory: ${message}`);
      }
      sourcePath = uri;
      fs.listFileSync(sourcePath);
    }
    this.copyDirectory(sourcePath, targetPath);
    return targetPath;
  }

  private copyDirectory(sourcePath: string, targetPath: string): void {
    const names = fs.listFileSync(sourcePath);
    names.forEach((name: string) => {
      const source = `${sourcePath}/${name}`;
      const target = `${targetPath}/${this.safeFileName(name, 'item')}`;
      if (fs.statSync(source).isDirectory()) {
        fs.mkdirSync(target, true);
        this.copyDirectory(source, target);
      } else {
        try {
          fs.copyFileSync(source, target);
        } catch (_) {
          this.copyByStream(source, target);
        }
      }
    });
  }

  private uniqueDirectoryPath(root: string, name: string): string {
    let candidate = `${root}/${name}`;
    let suffix = 2;
    while (this.pathExists(candidate)) {
      candidate = `${root}/${name} (${suffix})`;
      suffix += 1;
    }
    return candidate;
  }

  private pathExists(path: string): boolean {
    try {
      return fs.accessSync(path);
    } catch (_) {
      return false;
    }
  }

  private safeFileName(name: string, fallback: string): string {
    const safe = name.replace(/[\\/:*?\"<>|]/g, '_').trim();
    return safe.length > 0 ? safe : fallback;
  }

  private async copyToSandbox(context: common.UIAbilityContext, uri: string): Promise<string> {
    const targetDir = `${context.filesDir}/imports`;
    await this.ensureDir(targetDir);
    const fileName = this.decodeFileName(this.extractFileName(uri));
    const uniqueName = `${Date.now()}_${fileName}`;
    const targetPath = `${targetDir}/${uniqueName}`;
    const sourcePath = this.resolveFilePath(uri);
    if (sourcePath) {
      try {
        fs.copyFileSync(sourcePath, targetPath);
        return targetPath;
      } catch (error) {
        console.error(`[OhosFilePicker] copyFileSync failed: ${JSON.stringify(error)}`);
      }
    }
    this.copyByStream(uri, targetPath);
    return targetPath;
  }

  private async ensureDir(path: string): Promise<void> {
    try {
      await fs.access(path);
    } catch (_) {
      fs.mkdirSync(path, true);
    }
  }

  private extractFileName(uri: string): string {
    const trimmed = uri.endsWith('/') ? uri.substring(0, uri.length - 1) : uri;
    const idx = trimmed.lastIndexOf('/');
    if (idx >= 0 && idx < trimmed.length - 1) {
      return trimmed.substring(idx + 1);
    }
    return `picked_${Date.now()}`;
  }

  private decodeFileName(name: string): string {
    try {
      return decodeURIComponent(name);
    } catch (_) {
      return name;
    }
  }

  private resolveFilePath(uri: string): string | null {
    if (!uri || uri.length === 0) {
      return null;
    }
    if (uri.startsWith('file://docs')) {
      return this.decodeUri(uri.replace('file://docs', ''));
    }
    if (uri.startsWith('file://')) {
      return new fileUri.FileUri(uri).path;
    }
    return uri;
  }

  private copyByStream(sourceUri: string, target: string): void {
    const resolvedSource = this.resolveFilePath(sourceUri) ?? sourceUri;
    const sourceEntry = fs.openSync(resolvedSource, fs.OpenMode.READ_ONLY);
    const targetEntry = fs.openSync(target, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
    try {
      const buffer = new ArrayBuffer(4096);
      while (true) {
        const readSize = fs.readSync(sourceEntry.fd, buffer);
        if (readSize <= 0) {
          break;
        }
        fs.writeSync(targetEntry.fd, buffer, { length: readSize });
      }
    } finally {
      fs.closeSync(sourceEntry);
      fs.closeSync(targetEntry);
    }
  }

  private decodeUri(value: string): string {
    try {
      return decodeURIComponent(value);
    } catch (_) {
      return value;
    }
  }
}

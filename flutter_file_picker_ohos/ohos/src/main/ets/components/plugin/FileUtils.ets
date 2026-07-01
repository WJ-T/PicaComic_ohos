/*
 * Copyright (C) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { List } from '@kit.ArkTS';
import { Log } from '@ohos/flutter_ohos';
import { common, UIAbility, Want } from '@kit.AbilityKit';
import { fileIo as fs, fileUri } from '@kit.CoreFileKit';
import { FileInfo, FileInfoBuilder } from './FileInfo'
import util from '@ohos.util';

export class FileUtils {
  private static TAG: string = "FilePickerUtils";
  private readonly PRIMARY_VOLUME_NAME: string = "primary";

  static getFileExtension(filename: string): string {
    const dotIndex = filename.lastIndexOf('.');
    if (dotIndex === -1) {
      return ''; // 没有后缀名
    }
    return filename.substring(dotIndex + 1);
  }

  static ensureFileExtension(filename: string, extension: string): string {
    // 获取文件后缀名，并转换为小写进行比较
    const currentExtension = FileUtils.getFileExtension(filename);
    // 检查文件名是否以指定的后缀结尾
    if (currentExtension !== extension.toLowerCase()) {
      // 如果不是，则拼接上后缀
      return filename + "." + extension;
    }
    // 如果已经是正确的后缀，则返回原文件名
    return filename;
  }

  static getFileName(uri: string, context?: common.UIAbilityContext): string {
    let result: string | null = null;
    try {
      if (uri.startsWith("file://docs")) {
        const trimmed = uri.endsWith("/") ? uri.substring(0, uri.length - 1) : uri;
        result = trimmed.substring(trimmed.lastIndexOf("/") + 1);
        return decodeURIComponent(result);
      }
      if (uri.startsWith("file://") || uri.startsWith("/data")) {
        result = uri.substring(uri.lastIndexOf("/") + 1);
      }
    } catch (e) {
      Log.e(FileUtils.TAG, "Failed to handle file name: " + e.toString());
    }
    return (result ?? ("picked_" + Date.now().toString())) as string;
  }

  static async openFileStream(context: common.UIAbilityContext, uri: string,
    withData: boolean): Promise<FileInfo | null> {
    const fileInfo: FileInfoBuilder = new FileInfoBuilder();
    const sourcePath: string = FileUtils.resolvePath(uri);
    const fileName: string = FileUtils.getFileName(uri, context) as string;
    const cacheDir: string = context.cacheDir + "/file_picker";
    const decodedName = FileUtils.urlDecodeManual(fileName);
    let finalPath: string = cacheDir + "/" + Date.now().toString() + "_" + FileUtils.safeCacheName(decodedName);
    try {
      if (!await fs.access(cacheDir)) {
        fs.mkdirSync(cacheDir, true);
      }
      let copied: boolean = false;
      const copyCandidates: string[] = sourcePath === uri ? [sourcePath] : [sourcePath, uri];
      for (let i = 0; i < copyCandidates.length; i++) {
        try {
          fs.copyFileSync(copyCandidates[i], finalPath);
          copied = true;
          break;
        } catch (e) {
          Log.e(FileUtils.TAG, "copyFileSync failed: " + e.toString());
        }
      }
      if (!copied) {
        for (let i = 0; i < copyCandidates.length; i++) {
          if (FileUtils.copyByStream(copyCandidates[i], finalPath)) {
            copied = true;
            break;
          }
        }
      }
      if (!copied) {
        return null;
      }
      if (withData) {
        const file = fs.openSync(finalPath, fs.OpenMode.READ_ONLY);
        FileUtils.loadData(file, fileInfo);
        fs.closeSync(file);
      }
      const stat = fs.statSync(finalPath);
      fileInfo
        .withPath(finalPath)
        .withName(decodedName)
        .withUri(uri)
        .withSize(stat.size);
    } catch (err) {
      Log.e(FileUtils.TAG, "open uri file failed err:" + err)
    }
    return fileInfo.build()
  }

  static safeCacheName(name: string): string {
    let result = '';
    for (let i = 0; i < name.length; i++) {
      const ch = name[i];
      const code = name.charCodeAt(i);
      const valid =
        (code >= 48 && code <= 57) ||
        (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122) ||
        ch === '.' || ch === '_' || ch === '-';
      result += valid ? ch : '_';
    }
    return result.length > 0 ? result : ("picked_" + Date.now().toString());
  }

  static copyByStream(source: string, target: string): boolean {
    let sourceEntry: fs.File | null = null;
    let targetEntry: fs.File | null = null;
    try {
      sourceEntry = fs.openSync(source, fs.OpenMode.READ_ONLY);
      targetEntry = fs.openSync(target, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      const buffer = new ArrayBuffer(4096);
      while (true) {
        const readSize = fs.readSync(sourceEntry.fd, buffer);
        if (readSize <= 0) {
          break;
        }
        fs.writeSync(targetEntry.fd, buffer, { length: readSize });
      }
      return true;
    } catch (e) {
      Log.e(FileUtils.TAG, "copyByStream failed: " + e.toString());
      return false;
    } finally {
      if (sourceEntry != null) {
        fs.closeSync(sourceEntry);
      }
      if (targetEntry != null) {
        fs.closeSync(targetEntry);
      }
    }
  }

  // 将各种 file://docs/file:// 等 URI 解析成真实路径
  static resolvePath(uri: string): string {
    if (!uri) {
      return uri;
    }
    try {
      if (uri.startsWith("file://docs")) {
        // HarmonyOS 文档沙箱前缀 -> 物理路径
        const decoded = decodeURIComponent(uri.replace("file://docs", ""));
        return decoded.startsWith("/") ? decoded : ("/" + decoded);
      }
      if (uri.startsWith("file://")) {
        return new fileUri.FileUri(uri).path;
      }
      return decodeURIComponent(uri);
    } catch (_) {
      return uri;
    }
  }

  //单选 将中文URL编码（也称为百分号编码或百分比编码每个字符为UTF-8编码）转为正常中文
  static singleSelectionConversion(originalUri: string): string {
    let finalPath: string = "";
    let originalPath = originalUri
    let oldName = FileUtils.getFileName(originalUri);
    let newName: string = FileUtils.urlDecodeManual(oldName);
    finalPath = FileUtils.replaceFileName(originalPath, oldName, newName)
    return finalPath
  }

  static replaceFileName(originalPath: string, originalEncodedFileName: string, newFileName: string): string {
    // 替换原始路径中的文件名为新的文件名
    const newPath = originalPath.replace(originalEncodedFileName, newFileName);
    return newPath;
  }

  static urlDecodeManual(encodedString: string): string {
    let result = '';
    let i = 0;
    while (i < encodedString.length) {
      const char = encodedString[i];
      if (char === '%') {
        // 提取 %XX 形式的子字符串
        const hexCode = encodedString.substring(i + 1, i + 3);
        const byte = parseInt(hexCode, 16);
        // 将字节转换为字符
        result += String.fromCharCode(byte);
        // 跳过已经处理的三个字符
        i += 3;
      } else {
        // 直接添加普通字符
        result += char;
        i++;
      }
    }
    // 将结果从 UTF-8 编码转换为字符串
    return FileUtils.decodeUTF8(result);
  }

  static decodeUTF8(utf8String: string): string {
    const utf8Bytes = new Uint8Array(utf8String.length);
    for (let i = 0; i < utf8String.length; i++) {
      utf8Bytes[i] = utf8String.charCodeAt(i);
    }
    return new util.TextDecoder().decodeToString(utf8Bytes);
  }

  static clearCache(ability: UIAbility): boolean {
    const path: string =
      ability.context.cacheDir + "/file_picker";
    try {
      fs.rmdirSync(path)
    } catch (err) {
      Log.e(FileUtils.TAG, "There was an error while clearing cached files: " + err.toString());
      return false
    }
    return true;
  }

  static loadData(file: fs.File, fileInfo: FileInfoBuilder) {
    try {
      let stat = fs.statSync(file.fd);
      let buf = new ArrayBuffer(stat.size == 0 ? 1 : stat.size);
      let fileSize: number = fs.readSync(file.fd, buf);
      let bytes = new Uint8Array(buf.slice(0, fileSize));
      fileInfo
        .withData(bytes)
        .withSize(fileSize);
    } catch (e) {
      Log.e(FileUtils.TAG, "Failed to load bytes into memory with error " + e.toString() +
        ". Probably the file is too big to fit device memory. Bytes won't be added to the file this time.");
    }
  }
}

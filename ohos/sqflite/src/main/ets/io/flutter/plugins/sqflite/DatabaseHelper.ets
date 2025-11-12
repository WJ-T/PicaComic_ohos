/*
* Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
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

import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { Tools } from './Tools';
import { BusinessError } from '@ohos.base';
import { Constant } from './OhosConstant';
import deviceInfo from '@ohos.deviceInfo';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import fs from '@ohos.file.fs';
import { HashMap } from '@kit.ArkTS';

export class DatabaseHelper {
  /// 已加载的数据库, 存储数据库名称与数据库实例
  public static dbMap: Map<string, relationalStore.RdbStore> = new Map<string, relationalStore.RdbStore>();
  /// 加载的数据库, 存储数据库id与数据库名称
  public static dbIdMap: HashMap<number, string> = new HashMap<number, string>();
  /// 加载的数据库, 存储数据库id与是否只读
  public static dbIdOnlyMap: HashMap<number, boolean> = new HashMap<number, boolean>();
  /// 当前数据库的id
  private static currentDbId: number = 0;

  /// 打开一个数据库
  public static async openDatabase(context: common.Context, call: MethodCall, result: MethodResult): Promise<void> {
    let id: number = -1;
    let dbPath: string = call.argument(Constant.PARAM_PATH);
    let dbPathDirList: string[] = dbPath.split('/');
    let dbName: string = DatabaseHelper.getDatabaseNameByDbPathDirList(dbPathDirList);

    const isExisted: boolean = await DatabaseHelper.checkDatabaseExisted(dbPath);
    let local: relationalStore.RdbStore | null = DatabaseHelper.getDatabaseFromMemory(dbName);
    if (isExisted && local != null) {
      // 从通过数据库名称从内存中获取数据库ID
      id = DatabaseHelper.getMemoryDatabaseIdByDatabaseName(dbName);
    } else {
      let readOnly: boolean =
        call.argument(Constant.PARAM_READ_ONLY) == undefined ? false : call.argument(Constant.PARAM_READ_ONLY);
      let config: relationalStore.StoreConfig = DatabaseHelper.createDatabaseConfig(dbPathDirList, dbName, readOnly);
      try {
        let rdbStore = await relationalStore.getRdbStore(context, config);
        DatabaseHelper.dbMap.set(dbName, rdbStore);
        DatabaseHelper.currentDbId = DatabaseHelper.currentDbId + 1;
        id = DatabaseHelper.currentDbId;
        DatabaseHelper.dbIdMap.set(id, dbName);
        DatabaseHelper.dbIdOnlyMap.set(id, readOnly);
      } catch (err) {
        let code = (err as BusinessError).code;
        let message = (err as BusinessError).message;
        result.error(Constant.SQLITE_ERROR, 'Error code: ' + code + 'error message: ' + message + '。',
          'open database failed');
        return;
      }
    }
    let map: Record<string, Object> = {
      'id': id,
      'recovered': false,
      'recoveredInTransaction': false,
    }
    result.success(map);
  }

  /// 检查数据库是否存在
  public static async checkDatabaseExisted(dbPath: string): Promise<boolean> {
    let isExists: boolean = await fs.access(dbPath);
    return isExists;
  }

  /// 从已加载的列表里获取一个数据库
  private static getDatabaseFromMemory(dbName: string): relationalStore.RdbStore | null {
    if (DatabaseHelper.dbMap.has(dbName)) {
      return DatabaseHelper.dbMap.get(dbName) as relationalStore.RdbStore | null;
    }
    return null;
  }

  /// 从已加载的列表里获取一个数据库
  public static getDatabaseOrError(call: MethodCall, result: MethodResult): relationalStore.RdbStore | null {
    let dbId: number = call.argument(Constant.PARAM_ID);
    let dbName: string | undefined = DatabaseHelper.dbIdMap.get(dbId);
    if (typeof dbName == undefined) {
      result.error('sqlite_error', "database_closed" + "" + dbId, null);
      return null;
    }
    let rdbStore = DatabaseHelper.getDatabaseFromMemory(dbName);
    if (rdbStore != null) {
      return rdbStore;
    } else {
      result.error('sqlite_error', "database_closed" + "" + dbId, null);
      return null;
    }
  }

  /// 关闭一个数据库
  public static async closeDatabase(call: MethodCall, result: MethodResult): Promise<void> {
    let dbId: number = call.argument(Constant.PARAM_ID);
    let dbName: string | undefined = DatabaseHelper.dbIdMap.get(dbId);
    if (dbName == undefined) {
      return;
    }
    let local: relationalStore.RdbStore | null = DatabaseHelper.getDatabaseFromMemory(dbName);
    if (local != null) {
      try {
        await local.close();
        DatabaseHelper.removeDatabaseFromMemoryByDatabaseName(dbName);
        result.success(null);
        return;
      } catch (err) {
        let code = (err as BusinessError).code;
        let message = (err as BusinessError).message;
        result.error('sqlite_error', "close database failed. " + 'error code:' + code + '.  message:' + message, null);
        return;
      }
    }
    result.error('sqlite_error', "close database failed, database is not exist, can not close" + " " + dbId, null);
  }

  /// 删除一个数据库
  public static async deleteDatabase(context: common.Context, dbPath: string): Promise<boolean> {
    let result: boolean = false;
    let dbPathDirList: string[] = dbPath.split('/');
    let dbName: string = DatabaseHelper.getDatabaseNameByDbPathDirList(dbPathDirList);

    try {
      let config: relationalStore.StoreConfig = DatabaseHelper.createDatabaseConfig(dbPathDirList, dbName);
      await relationalStore.deleteRdbStore(context, config);
      result = true;
      if (DatabaseHelper.dbMap.has(dbName)) {
        DatabaseHelper.removeDatabaseFromMemoryByDatabaseName(dbName);
      }
      return result;
    } catch (e) {
      return result;
    }
  }

  /// 获取设备版本信息
  public static async getPlatformVersion(call: MethodCall, result: MethodResult): Promise<void> {
    result.success('ohos' + deviceInfo.osFullName);
  }

  /// Options操作，设置LogLevel，仅限开发，已被废弃
  public static async options(call: MethodCall, result: MethodResult): Promise<void> {
    let logLevel: number | undefined = call.argument(Constant.PARAM_LOG_LEVEL);
    result.success(null);
  }

  /// 设置debug模式，查看SQL查询，已弃用
  public static async debugMode(call: MethodCall, result: MethodResult): Promise<void> {
    let on: boolean = call.args;
    result.success(null);
  }

  private static createDatabaseConfig(dbNameList: string[], dbName: string,
    isReadOnly?: boolean): relationalStore.StoreConfig {
    //自定义数据库路径
    let customDir: string = '';
    for (let index = Constant.DB_PATH_PARSING_BEGIN_INDEX; index < dbNameList.length - 1; index++) {
      if (customDir.length > 0) {
        customDir = customDir + '/' + dbNameList[index];
      } else {
        customDir = dbNameList[index];
      }
    }

    let customDirPath = customDir.length > 0 ? customDir : undefined;
    let sdkApiVersion = deviceInfo.sdkApiVersion;
    let config: relationalStore.StoreConfig | undefined = undefined;
    if (sdkApiVersion >= Constant.API_17) {
      config = {
        name: dbName, // 数据库文件名
        securityLevel: relationalStore.SecurityLevel.S1, // 数据库安全级别
        customDir: customDirPath,
        tokenizer: relationalStore.Tokenizer.ICU_TOKENIZER,
        isReadOnly: isReadOnly
      }
    } else {
      config = {
        name: dbName, // 数据库文件名
        securityLevel: relationalStore.SecurityLevel.S1, // 数据库安全级别
        customDir: customDirPath,
        isReadOnly: isReadOnly
      }
    }
    return config!;
  }

  private static getDatabaseNameByDbPathDirList(dbPathDirList: string[]): string {
    let dbName: string = dbPathDirList[dbPathDirList.length - 1];
    let endWithDb: boolean = Tools.stringEndWith(dbName, '.db');
    if (!endWithDb) {
      dbName = dbName + '.db';
    }
    return dbName;
  }

  private static getMemoryDatabaseIdByDatabaseName(dbName: string): number {
    let id = -1;
    DatabaseHelper.dbIdMap.forEach((value, key) => {
      if (dbName == value) {
        id = key ?? -1;
      }
    })
    return id;
  }

  public static getMemoryDatabaseNameByDatabaseId(dbid: number): string {
    return DatabaseHelper.dbIdMap.get(dbid);
  }

  private static removeDatabaseFromMemoryByDatabaseName(dbName: string) {
    DatabaseHelper.dbMap.delete(dbName);
    let id: number = DatabaseHelper.getMemoryDatabaseIdByDatabaseName(dbName);
    DatabaseHelper.dbIdMap.remove(id);
    DatabaseHelper.dbIdOnlyMap.remove(id);
  }

}